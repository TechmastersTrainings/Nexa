import uuid
from app.models.user import User


def test_register_user_persists_in_postgres(client, db_session):
    payload = {
        "email": "priya.sharma@example.com",
        "password": "SuperSecurePassword2026#",
        "full_name": "Priya Sharma",
        "phone_number": "+919876543210",
        "safe_word_phrase": "help me nexa"
    }
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "priya.sharma@example.com"
    assert data["full_name"] == "Priya Sharma"
    assert data["phone_number"] == "+919876543210"
    assert data["safe_word_phrase"] == "help me nexa"
    assert "id" in data
    assert "password" not in data

    # Verify directly in PostgreSQL that password is not plaintext
    user_record = db_session.query(User).filter(User.email == "priya.sharma@example.com").first()
    assert user_record is not None
    assert user_record.hashed_password != payload["password"]
    assert user_record.hashed_password.startswith("$argon2id$")


def test_duplicate_registration_rejected(client):
    payload = {
        "email": "anita.desai@example.com",
        "password": "Password12345678!",
        "full_name": "Anita Desai",
        "phone_number": "+919876543211",
        "safe_word_phrase": "nexa rescue"
    }
    # First registration
    r1 = client.post("/api/v1/auth/register", json=payload)
    assert r1.status_code == 201

    # Second registration with exact same email
    r2 = client.post("/api/v1/auth/register", json=payload)
    assert r2.status_code == 409
    assert "already exists" in r2.json()["detail"]


def test_duplicate_phone_number_rejected(client):
    user1 = {
        "email": "user1@example.com",
        "password": "Password12345678!",
        "full_name": "User One",
        "phone_number": "+919999988888"
    }
    user2 = {
        "email": "user2@example.com",
        "password": "Password12345678!",
        "full_name": "User Two",
        "phone_number": "+919999988888"
    }
    r1 = client.post("/api/v1/auth/register", json=user1)
    assert r1.status_code == 201

    r2 = client.post("/api/v1/auth/register", json=user2)
    assert r2.status_code == 409
    assert "phone number" in r2.json()["detail"].lower()


def test_login_success_and_failure(client):
    credentials = {
        "email": "kavita.patel@example.com",
        "password": "StrongPassword999!",
        "full_name": "Kavita Patel",
        "phone_number": "+919876543212"
    }
    client.post("/api/v1/auth/register", json=credentials)

    # Valid login
    login_res = client.post("/api/v1/auth/login", json={
        "email": "kavita.patel@example.com",
        "password": "StrongPassword999!"
    })
    assert login_res.status_code == 200
    token_data = login_res.json()
    assert "access_token" in token_data
    assert token_data["token_type"] == "bearer"
    assert token_data["user"]["email"] == "kavita.patel@example.com"

    # Invalid password login
    invalid_res = client.post("/api/v1/auth/login", json={
        "email": "kavita.patel@example.com",
        "password": "WrongPassword!"
    })
    assert invalid_res.status_code == 401
    assert "invalid email or password" in invalid_res.json()["detail"].lower()

    # Nonexistent user login
    nonexistent_res = client.post("/api/v1/auth/login", json={
        "email": "nonexistent@example.com",
        "password": "Password123!"
    })
    assert nonexistent_res.status_code == 401


def test_authenticated_current_user_profile_and_isolation(client):
    # Register User A
    user_a_data = {
        "email": "user.a@example.com",
        "password": "PasswordA123!",
        "full_name": "User Alpha",
        "phone_number": "+919111111111"
    }
    client.post("/api/v1/auth/register", json=user_a_data)
    login_a = client.post("/api/v1/auth/login", json={
        "email": user_a_data["email"],
        "password": user_a_data["password"]
    }).json()
    token_a = login_a["access_token"]

    # Register User B
    user_b_data = {
        "email": "user.b@example.com",
        "password": "PasswordB123!",
        "full_name": "User Beta",
        "phone_number": "+919222222222"
    }
    client.post("/api/v1/auth/register", json=user_b_data)
    login_b = client.post("/api/v1/auth/login", json={
        "email": user_b_data["email"],
        "password": user_b_data["password"]
    }).json()
    token_b = login_b["access_token"]

    # User A accesses /me
    res_a = client.get(
        "/api/v1/users/me",
        headers={"Authorization": f"Bearer {token_a}"}
    )
    assert res_a.status_code == 200
    assert res_a.json()["email"] == "user.a@example.com"
    assert res_a.json()["full_name"] == "User Alpha"

    # User B accesses /me
    res_b = client.get(
        "/api/v1/users/me",
        headers={"Authorization": f"Bearer {token_b}"}
    )
    assert res_b.status_code == 200
    assert res_b.json()["email"] == "user.b@example.com"
    assert res_b.json()["full_name"] == "User Beta"

    # Cross-user isolation: User A cannot see User B's profile
    assert res_a.json()["id"] != res_b.json()["id"]

    # Request without token fails
    unauth_res = client.get("/api/v1/users/me")
    assert unauth_res.status_code == 401

    # Request with invalid token fails
    invalid_token_res = client.get(
        "/api/v1/users/me",
        headers={"Authorization": "Bearer invalid_garbage_token"}
    )
    assert invalid_token_res.status_code == 401
