import uuid
from datetime import datetime, timezone
import pytest
from fastapi.testclient import TestClient


def register_and_get_token(client: TestClient, email: str, phone: str) -> str:
    reg_payload = {
        "email": email,
        "password": "Password123!Secure",
        "full_name": "Alert Test User",
        "phone_number": phone,
    }
    client.post("/api/v1/auth/register", json=reg_payload)
    login_res = client.post("/api/v1/auth/login", json={"email": email, "password": "Password123!Secure"})
    return login_res.json()["access_token"]


def test_dispatch_emergency_alerts_to_contacts(client: TestClient):
    email = f"alert_sos_{uuid.uuid4().hex[:6]}@example.com"
    phone = f"+9198765{uuid.uuid4().hex[:5]}"
    token = register_and_get_token(client, email, phone)
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Add 2 trusted contacts
    c1_res = client.post(
        "/api/v1/contacts/",
        headers=headers,
        json={
            "name": "Mom",
            "phone_number": "+919111122222",
            "relationship": "Mother",
            "priority_order": 1,
        },
    )
    assert c1_res.status_code == 201
    c1_id = c1_res.json()["id"]

    c2_res = client.post(
        "/api/v1/contacts/",
        headers=headers,
        json={
            "name": "Brother",
            "phone_number": "+919222233333",
            "relationship": "Sibling",
            "priority_order": 2,
        },
    )
    assert c2_res.status_code == 201

    # 2. Record an SOS incident
    inc_payload = {
        "client_incident_id": f"sos-alert-{uuid.uuid4()}",
        "trigger_type": "safe_word",
        "latitude": 12.971598,
        "longitude": 77.594566,
        "accuracy_meters": 4.5,
        "location_unavailable": False,
        "battery_level": 82,
        "local_created_at": datetime.now(timezone.utc).isoformat(),
    }
    inc_res = client.post("/api/v1/incidents/", headers=headers, json=inc_payload)
    assert inc_res.status_code == 201
    incident_id = inc_res.json()["id"]

    # 3. Dispatch emergency alert broadcast
    dispatch_payload = {
        "incident_id": incident_id,
        "alert_type": "sms",
    }
    dispatch_res = client.post("/api/v1/alerts/dispatch", headers=headers, json=dispatch_payload)
    assert dispatch_res.status_code == 201
    dispatch_data = dispatch_res.json()

    assert dispatch_data["incident_id"] == incident_id
    assert dispatch_data["dispatched_count"] == 2
    assert dispatch_data["failed_count"] == 0
    assert len(dispatch_data["alerts"]) == 2

    # Verify message body formatting
    first_alert = dispatch_data["alerts"][0]
    assert "EMERGENCY SOS ALERT!" in first_alert["message_body"]
    assert "12.971598" in first_alert["message_body"]
    assert "Battery: 82%" in first_alert["message_body"]
    assert first_alert["delivery_status"] in ["delivered", "sent"]
    assert first_alert["provider_message_id"] is not None

    # 4. Query incident alerts
    logs_res = client.get(f"/api/v1/alerts/incident/{incident_id}", headers=headers)
    assert logs_res.status_code == 200
    logs = logs_res.json()
    assert len(logs) == 2


def test_dispatch_alerts_selective_contacts(client: TestClient):
    email = f"alert_sel_{uuid.uuid4().hex[:6]}@example.com"
    phone = f"+9198766{uuid.uuid4().hex[:5]}"
    token = register_and_get_token(client, email, phone)
    headers = {"Authorization": f"Bearer {token}"}

    # Add 2 contacts
    c1 = client.post(
        "/api/v1/contacts/",
        headers=headers,
        json={"name": "Guardian 1", "phone_number": "+919333344444", "relationship": "Guardian", "priority_order": 1},
    ).json()

    c2 = client.post(
        "/api/v1/contacts/",
        headers=headers,
        json={"name": "Friend", "phone_number": "+919444455555", "relationship": "Friend", "priority_order": 2},
    ).json()

    # Record incident
    inc = client.post(
        "/api/v1/incidents/",
        headers=headers,
        json={
            "client_incident_id": f"sos-sel-{uuid.uuid4()}",
            "trigger_type": "acoustic_pulse",
            "location_unavailable": True,
            "battery_level": 45,
            "local_created_at": datetime.now(timezone.utc).isoformat(),
        },
    ).json()

    # Dispatch only to Guardian 1
    dispatch_res = client.post(
        "/api/v1/alerts/dispatch",
        headers=headers,
        json={
            "incident_id": inc["id"],
            "alert_type": "voice",
            "recipient_ids": [c1["id"]],
        },
    )
    assert dispatch_res.status_code == 201
    data = dispatch_res.json()
    assert data["dispatched_count"] == 1
    assert data["alerts"][0]["recipient_contact_id"] == c1["id"]
    assert "Unavailable" in data["alerts"][0]["message_body"]


def test_alerts_tenant_isolation(client: TestClient):
    # User A
    token_a = register_and_get_token(client, f"usera_{uuid.uuid4().hex[:6]}@example.com", f"+9198767{uuid.uuid4().hex[:5]}")
    headers_a = {"Authorization": f"Bearer {token_a}"}

    # User B
    token_b = register_and_get_token(client, f"userb_{uuid.uuid4().hex[:6]}@example.com", f"+9198768{uuid.uuid4().hex[:5]}")
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # User A records an incident
    inc_a = client.post(
        "/api/v1/incidents/",
        headers=headers_a,
        json={
            "client_incident_id": f"inc-a-{uuid.uuid4()}",
            "trigger_type": "safe_word",
            "location_unavailable": False,
            "latitude": 13.0827,
            "longitude": 80.2707,
            "local_created_at": datetime.now(timezone.utc).isoformat(),
        },
    ).json()

    # User B attempts to dispatch alerts for User A's incident -> Expect 404
    dispatch_b = client.post(
        "/api/v1/alerts/dispatch",
        headers=headers_b,
        json={"incident_id": inc_a["id"], "alert_type": "sms"},
    )
    assert dispatch_b.status_code == 404

    # User B attempts to view User A's incident alert logs -> Expect 404
    logs_b = client.get(f"/api/v1/alerts/incident/{inc_a['id']}", headers=headers_b)
    assert logs_b.status_code == 404


def test_user_alert_history_aggregation(client: TestClient):
    email = f"alert_hist_{uuid.uuid4().hex[:6]}@example.com"
    token = register_and_get_token(client, email, f"+9198769{uuid.uuid4().hex[:5]}")
    headers = {"Authorization": f"Bearer {token}"}

    # Add contact
    client.post(
        "/api/v1/contacts/",
        headers=headers,
        json={"name": "Father", "phone_number": "+919555566666", "relationship": "Father", "priority_order": 1},
    )

    # Record 2 incidents and dispatch alerts for each
    for i in range(2):
        inc = client.post(
            "/api/v1/incidents/",
            headers=headers,
            json={
                "client_incident_id": f"hist-inc-{i}-{uuid.uuid4()}",
                "trigger_type": "manual_panic",
                "location_unavailable": True,
                "local_created_at": datetime.now(timezone.utc).isoformat(),
            },
        ).json()
        client.post(
            "/api/v1/alerts/dispatch",
            headers=headers,
            json={"incident_id": inc["id"], "alert_type": "sms"},
        )

    # Query full history
    hist_res = client.get("/api/v1/alerts/history", headers=headers)
    assert hist_res.status_code == 200
    history = hist_res.json()
    assert len(history) == 2
