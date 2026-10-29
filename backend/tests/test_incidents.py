import datetime
import pytest
from fastapi.testclient import TestClient


def get_auth_token(client: TestClient, email: str, password: str = "Pass12345678#") -> str:
    client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": password,
            "full_name": "Incident Test User",
            "phone_number": f"+9197{abs(hash(email)) % 100000000:08d}",
        },
    )
    res = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    return res.json()["access_token"]


def test_record_incident_with_location_telemetry(client: TestClient):
    token = get_auth_token(client, "loc_user@example.com")
    headers = {"Authorization": f"Bearer {token}"}

    payload = {
        "client_incident_id": "client-uuid-001",
        "trigger_type": "voice_safe_word",
        "latitude": 28.6139,
        "longitude": 77.2090,
        "accuracy_meters": 4.5,
        "location_unavailable": False,
        "battery_level": 78,
        "local_created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }

    res = client.post("/api/v1/incidents", json=payload, headers=headers)
    assert res.status_code == 201
    data = res.json()
    assert data["client_incident_id"] == "client-uuid-001"
    assert data["latitude"] == 28.6139
    assert data["longitude"] == 77.2090
    assert data["location_unavailable"] is False
    assert data["status"] == "recorded"
    assert "id" in data


def test_record_incident_location_unavailable(client: TestClient):
    token = get_auth_token(client, "loc_unavail_user@example.com")
    headers = {"Authorization": f"Bearer {token}"}

    payload = {
        "client_incident_id": "client-uuid-unavail-002",
        "trigger_type": "manual_panic",
        "latitude": None,
        "longitude": None,
        "accuracy_meters": None,
        "location_unavailable": True,
        "battery_level": 15,
        "local_created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }

    res = client.post("/api/v1/incidents", json=payload, headers=headers)
    assert res.status_code == 201
    data = res.json()
    assert data["location_unavailable"] is True
    assert data["latitude"] is None


def test_incident_idempotency_on_retry(client: TestClient):
    token = get_auth_token(client, "idempotent_user@example.com")
    headers = {"Authorization": f"Bearer {token}"}

    payload = {
        "client_incident_id": "retry-incident-123",
        "trigger_type": "voice_safe_word",
        "latitude": 19.0760,
        "longitude": 72.8777,
        "accuracy_meters": 10.0,
        "location_unavailable": False,
        "local_created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }

    res1 = client.post("/api/v1/incidents", json=payload, headers=headers)
    assert res1.status_code == 201
    id1 = res1.json()["id"]

    # Re-send exact same client_incident_id
    res2 = client.post("/api/v1/incidents", json=payload, headers=headers)
    assert res2.status_code == 201
    id2 = res2.json()["id"]

    assert id1 == id2


def test_batch_sync_offline_incident_queue(client: TestClient):
    token = get_auth_token(client, "sync_user@example.com")
    headers = {"Authorization": f"Bearer {token}"}

    batch_payload = {
        "incidents": [
            {
                "client_incident_id": "offline-queue-1",
                "trigger_type": "safe_word",
                "latitude": 12.9716,
                "longitude": 77.5946,
                "accuracy_meters": 8.0,
                "location_unavailable": False,
                "local_created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            },
            {
                "client_incident_id": "offline-queue-2",
                "trigger_type": "manual_sos",
                "latitude": 12.9719,
                "longitude": 77.5950,
                "accuracy_meters": 5.0,
                "location_unavailable": False,
                "local_created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            },
        ]
    }

    sync_res = client.post("/api/v1/incidents/sync", json=batch_payload, headers=headers)
    assert sync_res.status_code == 200
    sync_data = sync_res.json()
    assert sync_data["processed_count"] == 2
    assert len(sync_data["synced_incidents"]) == 2
    assert sync_data["duplicate_count"] == 0

    # Repeat sync with same items - verify duplicates handled gracefully
    sync_repeat = client.post("/api/v1/incidents/sync", json=batch_payload, headers=headers)
    assert sync_repeat.status_code == 200
    repeat_data = sync_repeat.json()
    assert repeat_data["duplicate_count"] == 2


def test_incident_tenant_isolation(client: TestClient):
    token_a = get_auth_token(client, "tenant_a@example.com")
    headers_a = {"Authorization": f"Bearer {token_a}"}

    res_a = client.post(
        "/api/v1/incidents",
        json={
            "client_incident_id": "tenant-a-inc-1",
            "trigger_type": "safe_word",
            "local_created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        },
        headers=headers_a,
    )
    inc_a_id = res_a.json()["id"]

    # User B cannot access User A's incident
    token_b = get_auth_token(client, "tenant_b@example.com")
    headers_b = {"Authorization": f"Bearer {token_b}"}

    get_res = client.get(f"/api/v1/incidents/{inc_a_id}", headers=headers_b)
    assert get_res.status_code == 404
