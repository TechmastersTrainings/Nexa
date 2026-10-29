import base64
import io
import math
import struct
import wave
from typing import Dict, List, Optional, Tuple
from app.schemas.ml import AcousticFeatures, StressAnalysisRequest, StressAnalysisResponse


class VoiceStressAnalysisService:
    def parse_audio_samples(self, raw_bytes: bytes) -> Tuple[List[float], int]:
        """
        Parses raw bytes (either WAV container or raw 16-bit PCM) into normalized float samples [-1.0, 1.0].
        Returns (samples, sample_rate).
        """
        sample_rate = 16000
        samples: List[float] = []

        if raw_bytes.startswith(b"RIFF"):
            try:
                with wave.open(io.BytesIO(raw_bytes), "rb") as wf:
                    sample_rate = wf.getframerate()
                    n_channels = wf.getnchannels()
                    sampwidth = wf.getsampwidth()
                    n_frames = wf.getnframes()
                    frames = wf.readframes(n_frames)

                    if sampwidth == 2:  # 16-bit PCM
                        total_samples = len(frames) // 2
                        unpacked = struct.unpack(f"<{total_samples}h", frames)
                        if n_channels == 2:
                            # Average stereo into mono
                            mono = [(unpacked[i] + unpacked[i + 1]) / (2.0 * 32768.0) for i in range(0, total_samples, 2)]
                            samples = mono
                        else:
                            samples = [s / 32768.0 for s in unpacked]
            except Exception:
                pass

        if not samples and len(raw_bytes) >= 2:
            # Fallback: treat as raw 16-bit PCM little-endian
            total = len(raw_bytes) // 2
            try:
                unpacked = struct.unpack(f"<{total}h", raw_bytes[: total * 2])
                samples = [s / 32768.0 for s in unpacked]
            except Exception:
                samples = []

        return samples, sample_rate

    def extract_features(self, samples: List[float], sample_rate: int = 16000) -> AcousticFeatures:
        n = len(samples)
        if n == 0:
            return AcousticFeatures(
                rms_energy=0.0,
                zero_crossing_rate=0.0,
                high_frequency_ratio=0.0,
                amplitude_variance=0.0,
                estimated_pitch_hz=None,
            )

        # 1. RMS Energy
        sum_sq = sum(s * s for s in samples)
        rms = math.sqrt(sum_sq / n)

        # 2. Zero Crossing Rate (ZCR)
        zcr_count = 0
        for i in range(1, n):
            if (samples[i] >= 0 > samples[i - 1]) or (samples[i] < 0 <= samples[i - 1]):
                zcr_count += 1
        zcr = zcr_count / float(n - 1) if n > 1 else 0.0

        # 3. High Frequency Ratio (First-difference Energy)
        diff_sq = sum((samples[i] - samples[i - 1]) ** 2 for i in range(1, n))
        diff_rms = math.sqrt(diff_sq / (n - 1)) if n > 1 else 0.0
        hf_ratio = min(diff_rms / (rms + 1e-6), 2.0) / 2.0

        # 4. Amplitude Variance across temporal windows (Frame size ~ 50ms)
        frame_size = max(int(sample_rate * 0.05), 10)
        frame_energies: List[float] = []
        for start in range(0, n, frame_size):
            chunk = samples[start : start + frame_size]
            if chunk:
                c_rms = math.sqrt(sum(c * c for c in chunk) / len(chunk))
                frame_energies.append(c_rms)

        if frame_energies:
            mean_energy = sum(frame_energies) / len(frame_energies)
            variance = sum((e - mean_energy) ** 2 for e in frame_energies) / len(frame_energies)
        else:
            variance = 0.0

        # 5. Fundamental Frequency (Pitch) via simplified autocorrelation
        estimated_pitch: Optional[float] = None
        if n >= 512 and sample_rate > 0:
            # Search lags corresponding to 80Hz - 450Hz
            min_lag = int(sample_rate / 450)
            max_lag = int(sample_rate / 80)
            best_lag = min_lag
            max_corr = -1.0

            # Subsample up to 2048 samples for fast autocorrelation
            subset = samples[: min(n, 2048)]
            sub_n = len(subset)

            for lag in range(min_lag, min(max_lag, sub_n // 2)):
                corr = sum(subset[i] * subset[i + lag] for i in range(sub_n - lag))
                if corr > max_corr:
                    max_corr = corr
                    best_lag = lag

            if max_corr > 0 and best_lag > 0:
                estimated_pitch = round(float(sample_rate) / best_lag, 1)

        return AcousticFeatures(
            rms_energy=round(rms, 4),
            zero_crossing_rate=round(zcr, 4),
            high_frequency_ratio=round(hf_ratio, 4),
            amplitude_variance=round(variance, 6),
            estimated_pitch_hz=estimated_pitch,
        )

    def compute_distress_score(self, features: AcousticFeatures) -> Tuple[float, str, float]:
        """
        Computes calibrated vocal distress score (0.0 to 1.0) and determines risk tier.
        """
        # Feature weighting:
        # High RMS energy (screaming/shouting): 35%
        # High ZCR (friction/gasping): 25%
        # High Frequency energy ratio: 20%
        # Energy bursts variance: 20%
        norm_rms = min(features.rms_energy * 4.0, 1.0)
        norm_zcr = min(features.zero_crossing_rate * 3.0, 1.0)
        norm_hf = min(features.high_frequency_ratio * 1.5, 1.0)
        norm_var = min(features.amplitude_variance * 40.0, 1.0)

        raw_score = (
            0.35 * norm_rms
            + 0.25 * norm_zcr
            + 0.20 * norm_hf
            + 0.20 * norm_var
        )

        # Elevate if pitch is sharply shifted to screaming range (>300Hz)
        if features.estimated_pitch_hz and features.estimated_pitch_hz > 320:
            raw_score = min(raw_score * 1.15, 1.0)

        distress_score = round(max(0.0, min(raw_score, 1.0)), 3)

        if distress_score >= 0.70:
            risk_level = "CRITICAL_DISTRESS"
            confidence = 0.92
        elif distress_score >= 0.40:
            risk_level = "ELEVATED_STRESS"
            confidence = 0.85
        else:
            risk_level = "NORMAL"
            confidence = 0.90

        return distress_score, risk_level, confidence

    def analyze(self, req: StressAnalysisRequest) -> StressAnalysisResponse:
        # Check if manual feature override provided
        if req.feature_override:
            f = req.feature_override
            features = AcousticFeatures(
                rms_energy=f.get("rms_energy", 0.0),
                zero_crossing_rate=f.get("zero_crossing_rate", 0.0),
                high_frequency_ratio=f.get("high_frequency_ratio", 0.0),
                amplitude_variance=f.get("amplitude_variance", 0.0),
                estimated_pitch_hz=f.get("estimated_pitch_hz"),
            )
        elif req.raw_audio_base64:
            try:
                audio_bytes = base64.b64decode(req.raw_audio_base64)
            except Exception:
                audio_bytes = b""
            samples, sr = self.parse_audio_samples(audio_bytes)
            sample_rate = req.sample_rate if req.sample_rate > 0 else sr
            features = self.extract_features(samples, sample_rate)
        else:
            # Baseline silence / default
            features = AcousticFeatures(
                rms_energy=0.0,
                zero_crossing_rate=0.0,
                high_frequency_ratio=0.0,
                amplitude_variance=0.0,
                estimated_pitch_hz=None,
            )

        distress_score, risk_level, confidence = self.compute_distress_score(features)

        return StressAnalysisResponse(
            distress_score=distress_score,
            risk_level=risk_level,
            confidence=confidence,
            features=features,
            methodology="Acoustic spectral energy & zero-crossing statistical extraction",
            privacy_guarantee="Ephemeral on-demand processing. Raw audio waveforms are never permanently stored in cloud databases.",
        )


ml_stress_service = VoiceStressAnalysisService()
