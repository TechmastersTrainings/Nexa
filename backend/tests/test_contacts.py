import pytest
from fastapi.testclient import TestClient


def get_auth_token(client: TestClient, email: str, password: str = "SecurePass123!") -> str:
    # Register if not already registered
    client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": password,
            "full_name": "Test User",
            "phone_number": f"+9198{abs(hash(email)) % 100000000:08d}",
        },
    )
    # Login with JSON payload
    res = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    assert res.status_code == 200, f"Login failed for {email}: {res.text}"
    return res.json()["access_token"]


def test_create_and_list_trusted_contacts(client: TestClient):
    token = get_auth_token(client, "contact_user1@example.com")
    headers = {"Authorization": f"Bearer {token}"}

    payload = {
        "name": "Sarah Connor",
        "phone_number": "+919876540001",
        "relationship": "Sister",
        "priority_order": 1,
    }

    res = client.post("/api/v1/contacts", json=payload, headers=headers)
    assert res.status_code == 201
    contact = res.json()
    assert contact["name"] == "Sarah Connor"
    assert contact["phone_number"] == "+919876540001"
    assert contact["relationship"] == "Sister"
    assert contact["is_verified"] is False
    assert "id" in contact

    # List contacts
    list_res = client.get("/api/v1/contacts", headers=headers)
    assert list_res.status_code == 200
    contacts = list_res.json()
    assert len(contacts) == 1
    assert contacts[0]["id"] == contact["id"]


def test_contact_tenant_isolation(client: TestClient):
    # User A creates a contact
    token_a = get_auth_token(client, "alice_contacts@example.com")
    headers_a = {"Authorization": f"Bearer {token_a}"}

    res_a = client.post(
        "/api/v1/contacts",
        json={"name": "Alice Guardian", "phone_number": "+919876540002", "relationship": "Mother", "priority_order": 1},
        headers=headers_a,
    )
    contact_id = res_a.json()["id"]

    # User B tries to access or modify User A's contact
    token_b = get_auth_token(client, "bob_contacts@example.com")
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # B cannot fetch A's contact
    get_res = client.get(f"/api/v1/contacts/{contact_id}", headers=headers_b)
    assert get_res.status_code == 404

    # B cannot update A's contact
    put_res = client.put(f"/api/v1/contacts/{contact_id}", json={"name": "Hacked Name"}, headers=headers_b)
    assert put_res.status_code == 404

    # B cannot delete A's contact
    del_res = client.delete(f"/api/v1/contacts/{contact_id}", headers=headers_b)
    assert del_res.status_code == 404


def test_update_and_delete_contact(client: TestClient):
    token = get_auth_token(client, "update_contact@example.com")
    headers = {"Authorization": f"Bearer {token}"}

    # Create
    create_res = client.post(
        "/api/v1/contacts",
        json={"name": "Old Name", "phone_number": "+919876540003", "relationship": "Friend", "priority_order": 2},
        headers=headers,
    )
    contact_id = create_res.json()["id"]

    # Update
    update_res = client.put(
        f"/api/v1/contacts/{contact_id}",
        json={"name": "New Name", "priority_order": 1},
        headers=headers,
    )
    assert update_res.status_code == 200
    assert update_res.json()["name"] == "New Name"
    assert update_res.json()["priority_order"] == 1

    # Delete
    del_res = client.delete(f"/api/v1/contacts/{contact_id}", headers=headers)
    assert del_res.status_code == 204

    # Verify deleted
    get_res = client.get(f"/api/v1/contacts/{contact_id}", headers=headers)
    assert get_res.status_code == 404


def test_duplicate_contact_phone_and_limit_enforced(client: TestClient):
    token = get_auth_token(client, "limit_contact@example.com")
    headers = {"Authorization": f"Bearer {token}"}

    # First contact
    res1 = client.post(
        "/api/v1/contacts",
        json={"name": "Contact 1", "phone_number": "+919876540004", "relationship": "Sister", "priority_order": 1},
        headers=headers,
    )
    assert res1.status_code == 201

    # Duplicate phone for same user rejected
    dup_res = client.post(
        "/api/v1/contacts",
        json={"name": "Contact Duplicate", "phone_number": "+919876540004", "relationship": "Friend", "priority_order": 2},
        headers=headers,
    )
    assert dup_res.status_code == 400
    assert "already exists" in dup_res.json()["detail"]
