import base64
import io
import math
import struct
import uuid
import wave
import pytest
from fastapi.testclient import TestClient


def create_test_wav(freq: float = 200.0, duration_sec: float = 1.0, amplitude: float = 0.2, noise: bool = False) -> bytes:
    sample_rate = 16000
    num_samples = int(sample_rate * duration_sec)
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        frames = []
        for i in range(num_samples):
            t = float(i) / sample_rate
            val = amplitude * math.sin(2.0 * math.pi * freq * t)
            if noise:
                # Add irregular high-frequency jitter/noise
                val += 0.3 * (math.sin(2.0 * math.pi * freq * 5 * t) + math.sin(2.0 * math.pi * freq * 9 * t))
            val = max(-1.0, min(1.0, val))
            sample_val = int(val * 32767)
            frames.append(struct.pack("<h", sample_val))
        wf.writeframes(b"".join(frames))
    return buf.getvalue()


def get_auth_token(client: TestClient) -> str:
    email = f"ml_user_{uuid.uuid4().hex[:6]}@example.com"
    phone = f"+9199999{uuid.uuid4().hex[:5]}"
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Password123!Secure", "full_name": "ML Tester", "phone_number": phone},
    )
    res = client.post("/api/v1/auth/login", json={"email": email, "password": "Password123!Secure"})
    return res.json()["access_token"]


def test_ml_stress_with_calm_audio(client: TestClient):
    token = get_auth_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    # Calm 150 Hz tone, low amplitude
    wav_bytes = create_test_wav(freq=150.0, duration_sec=0.5, amplitude=0.1, noise=False)
    b64_audio = base64.b64encode(wav_bytes).decode("utf-8")

    res = client.post(
        "/api/v1/ml/stress-analysis",
        headers=headers,
        json={"raw_audio_base64": b64_audio, "sample_rate": 16000},
    )
    assert res.status_code == 200
    data = res.json()
    assert data["distress_score"] < 0.40
    assert data["risk_level"] == "NORMAL"
    assert data["features"]["rms_energy"] > 0
    assert "Ephemeral" in data["privacy_guarantee"]


def test_ml_stress_with_screaming_distress_audio(client: TestClient):
    token = get_auth_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    # High frequency 400Hz with harsh noisy agitation and high amplitude
    wav_bytes = create_test_wav(freq=380.0, duration_sec=0.5, amplitude=0.8, noise=True)
    b64_audio = base64.b64encode(wav_bytes).decode("utf-8")

    res = client.post(
        "/api/v1/ml/stress-analysis",
        headers=headers,
        json={"raw_audio_base64": b64_audio, "sample_rate": 16000},
    )
    assert res.status_code == 200
    data = res.json()
    assert data["distress_score"] >= 0.40
    assert data["risk_level"] in ["ELEVATED_STRESS", "CRITICAL_DISTRESS"]


def test_ml_stress_with_feature_override(client: TestClient):
    token = get_auth_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    # Test extreme distress features
    res = client.post(
        "/api/v1/ml/stress-analysis",
        headers=headers,
        json={
            "feature_override": {
                "rms_energy": 0.35,
                "zero_crossing_rate": 0.45,
                "high_frequency_ratio": 0.85,
                "amplitude_variance": 0.05,
                "estimated_pitch_hz": 380.0,
            }
        },
    )
    assert res.status_code == 200
    data = res.json()
    assert data["distress_score"] >= 0.70
    assert data["risk_level"] == "CRITICAL_DISTRESS"


def test_ml_stress_file_upload(client: TestClient):
    token = get_auth_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    wav_bytes = create_test_wav(freq=250.0, duration_sec=0.3, amplitude=0.3)
    files = {"file": ("distress_sample.wav", wav_bytes, "audio/wav")}

    res = client.post("/api/v1/ml/stress-analysis/file", headers=headers, files=files)
    assert res.status_code == 200
    data = res.json()
    assert "distress_score" in data
    assert "features" in data


def test_ml_stress_unauthenticated_rejected(client: TestClient):
    res = client.post("/api/v1/ml/stress-analysis", json={})
    assert res.status_code == 401
