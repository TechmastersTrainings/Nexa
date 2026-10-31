import base64
import io
import math
import struct
import uuid
import wave
from datetime import datetime, timezone
import pytest
from fastapi.testclient import TestClient


def create_sample_wav(freq: float = 350.0, duration: float = 0.4) -> bytes:
    sample_rate = 16000
    n = int(sample_rate * duration)
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        frames = []
        for i in range(n):
            t = float(i) / sample_rate
            val = 0.5 * math.sin(2.0 * math.pi * freq * t)
            frames.append(struct.pack("<h", int(val * 32767)))
        wf.writeframes(b"".join(frames))
    return buf.getvalue()


def test_full_lifecyle_e2e_women_safety_distress_flow(client: TestClient):
    """
    Comprehensive End-to-End Lifecycle Scenario:
    1. User Registration & JWT Authentication (Phase 1)
    2. Adding & Verifying Trusted Emergency Contacts (Phase 2)
    3. Simulating Distress Keyword Trigger & On-Device GPS Telemetry (Phases 3-4)
    4. Offline Incident Queue Batch Synchronization (Phase 4)
    5. Automatic Emergency Telecom Broadcast (SMS/Voice) & Delivery Tracking (Phase 5)
    6. Companion Dashboard Telemetry Verification (Phase 6)
    7. Vocal Distress ML Analysis (Phase 7)
    8. Community Safety Hazard Pinning & Radius Querying (Phase 8)
    9. Zero-Compromise Tenant Isolation Verification
    """
    user_suffix = uuid.uuid4().hex[:6]
    email = f"guardian_user_{user_suffix}@nexa-safety.org"
    phone = f"+9198111{user_suffix[:5]}"
    password = "NexaPassword2026!Secure"

    # --- STEP 1: Registration & Login ---
    reg_res = client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": password,
            "full_name": "Priya Sharma",
            "phone_number": phone,
        },
    )
    assert reg_res.status_code == 201
    user_id = reg_res.json()["id"]

    login_res = client.post("/api/v1/auth/login", json={"email": email, "password": password})
    assert login_res.status_code == 200
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Verify Profile
    me_res = client.get("/api/v1/users/me", headers=headers)
    assert me_res.status_code == 200
    assert me_res.json()["id"] == user_id

    # --- STEP 2: Configure Emergency Contacts ---
    contact_1 = client.post(
        "/api/v1/contacts/",
        headers=headers,
        json={
            "name": "Mom",
            "phone_number": "+919876543210",
            "relationship": "Mother",
            "priority_order": 1,
        },
    ).json()
    assert contact_1["is_verified"] is False

    # Simulate responder OTP verification handshake
    verify_res = client.post(
        f"/api/v1/contacts/{contact_1['id']}/verify",
        headers=headers,
        params={"code": "123456"},
    )
    assert verify_res.status_code == 200
    assert verify_res.json()["is_verified"] is True

    # --- STEP 3 & 4: Offline Incident Queue Synchronization ---
    client_incident_id = f"sos-client-uuid-{uuid.uuid4()}"
    offline_batch = {
        "incidents": [
            {
                "client_incident_id": client_incident_id,
                "trigger_type": "voice_safe_word_bachao",
                "latitude": 12.971598,
                "longitude": 77.594566,
                "accuracy_meters": 3.8,
                "location_unavailable": False,
                "battery_level": 74,
                "local_created_at": datetime.now(timezone.utc).isoformat(),
            }
        ]
    }
    sync_res = client.post("/api/v1/incidents/sync", headers=headers, json=offline_batch)
    assert sync_res.status_code == 200
    sync_data = sync_res.json()
    assert sync_data["processed_count"] == 1
    assert sync_data["duplicate_count"] == 0
    server_incident_id = sync_data["synced_incidents"][0]["id"]

    # Verify Idempotent Resync (network bounce simulation)
    retry_sync = client.post("/api/v1/incidents/sync", headers=headers, json=offline_batch)
    assert retry_sync.status_code == 200
    assert retry_sync.json()["duplicate_count"] == 1

    # --- STEP 5: Emergency Broadcast Dispatch ---
    dispatch_res = client.post(
        "/api/v1/alerts/dispatch",
        headers=headers,
        json={"incident_id": server_incident_id, "alert_type": "sms"},
    )
    assert dispatch_res.status_code == 201
    dispatch_data = dispatch_res.json()
    assert dispatch_data["dispatched_count"] >= 1
    assert "EMERGENCY SOS ALERT!" in dispatch_data["alerts"][0]["message_body"]
    assert "12.971598" in dispatch_data["alerts"][0]["message_body"]
    assert dispatch_data["alerts"][0]["provider_message_id"] is not None

    # --- STEP 6: Companion Live Monitoring ---
    incidents_res = client.get("/api/v1/incidents/", headers=headers)
    assert incidents_res.status_code == 200
    assert len(incidents_res.json()) >= 1

    alert_hist_res = client.get("/api/v1/alerts/history", headers=headers)
    assert alert_hist_res.status_code == 200
    assert len(alert_hist_res.json()) >= 1

    # --- STEP 7: Voice-Stress ML Classification ---
    wav_sample = create_sample_wav(freq=380.0, duration=0.3)
    b64_audio = base64.b64encode(wav_sample).decode("utf-8")
    ml_res = client.post(
        "/api/v1/ml/stress-analysis",
        headers=headers,
        json={"raw_audio_base64": b64_audio, "sample_rate": 16000},
    )
    assert ml_res.status_code == 200
    ml_data = ml_res.json()
    assert "distress_score" in ml_data
    assert "risk_level" in ml_data
    assert ml_data["features"]["rms_energy"] > 0

    # --- STEP 8: Community Safety Map & Danger Zones ---
    report_res = client.post(
        "/api/v1/safety-map/reports",
        headers=headers,
        json={
            "title": "MG Road Safe Haven Kiosk",
            "category": "safe_haven",
            "severity_level": 1,
            "latitude": 12.9716,
            "longitude": 77.5946,
            "radius_meters": 100.0,
        },
    )
    assert report_res.status_code == 201
    report_id = report_res.json()["id"]

    # Radius search
    zones_res = client.get(
        "/api/v1/safety-map/zones",
        params={"lat": 12.9716, "lng": 77.5946, "radius_km": 5.0},
    )
    assert zones_res.status_code == 200
    assert any(z["id"] == report_id for z in zones_res.json())

    # Community upvote
    up_res = client.post(f"/api/v1/safety-map/reports/{report_id}/upvote", headers=headers)
    assert up_res.status_code == 200
    assert up_res.json()["upvotes"] == 1

    # --- STEP 9: Tenant Isolation & Attack Resistance ---
    other_user_token = client.post(
        "/api/v1/auth/register",
        json={
            "email": f"attacker_{uuid.uuid4().hex[:6]}@example.com",
            "password": "AttackerPassword123!",
            "full_name": "Attacker",
            "phone_number": f"+9198222{uuid.uuid4().hex[:5]}",
        },
    ).json()
    other_login = client.post(
        "/api/v1/auth/login",
        json={"email": other_user_token["email"], "password": "AttackerPassword123!"},
    ).json()
    attacker_headers = {"Authorization": f"Bearer {other_login['access_token']}"}

    # Attacker tries to dispatch alerts for Priya's incident -> Expect 404
    attack_dispatch = client.post(
        "/api/v1/alerts/dispatch",
        headers=attacker_headers,
        json={"incident_id": server_incident_id, "alert_type": "sms"},
    )
    assert attack_dispatch.status_code == 404

    # Attacker tries to fetch Priya's contacts -> Expect empty list
    attacker_contacts = client.get("/api/v1/contacts/", headers=attacker_headers).json()
    assert len(attacker_contacts) == 0
