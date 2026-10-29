from typing import Dict, Optional
from pydantic import BaseModel, Field


class AcousticFeatures(BaseModel):
    rms_energy: float = Field(..., description="Root Mean Square energy of the audio waveform (amplitude measure)")
    zero_crossing_rate: float = Field(..., description="Normalized rate of sign-changes along the signal")
    high_frequency_ratio: float = Field(..., description="Ratio of high-frequency first-difference energy")
    amplitude_variance: float = Field(..., description="Variance of signal peaks across time chunks")
    estimated_pitch_hz: Optional[float] = Field(None, description="Fundamental pitch estimate in Hertz")


class StressAnalysisRequest(BaseModel):
    raw_audio_base64: Optional[str] = Field(
        None,
        description="Base64-encoded 16-bit PCM WAV audio clip snippet (1-5 seconds recommended)",
    )
    sample_rate: int = Field(16000, description="Audio sampling rate in Hz (default 16000)")
    feature_override: Optional[Dict[str, float]] = Field(
        None,
        description="Optional manual feature vector input for diagnostic/testing benchmarks",
    )


class StressAnalysisResponse(BaseModel):
    distress_score: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description="Calibrated vocal distress index from 0.0 (calm) to 1.0 (extreme distress/screaming)",
    )
    risk_level: str = Field(
        ...,
        description="'NORMAL', 'ELEVATED_STRESS', or 'CRITICAL_DISTRESS'",
    )
    confidence: float = Field(..., ge=0.0, le=1.0)
    features: AcousticFeatures
    methodology: str = Field(
        "Acoustic spectral energy & zero-crossing statistical extraction",
        description="Explanation of classification technique",
    )
    privacy_guarantee: str = Field(
        "Ephemeral on-demand processing. Raw audio waveforms are never permanently stored in cloud databases.",
    )
