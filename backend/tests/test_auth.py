import uuid
from app.models.user import User


def test_register_user_persists_in_postgres(client, db_session):
    uid = uuid.uuid4().hex[:6]
    test_email = f"priya_{uid}@example.com"
    test_phone = f"+9198{uuid.uuid4().hex[:8]}"
    payload = {
        "email": test_email,
        "password": "SuperSecurePassword2026#",
        "full_name": "Priya Sharma",
        "phone_number": test_phone,
        "safe_word_phrase": "help me nexa"
    }
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == test_email
    assert data["full_name"] == "Priya Sharma"
    assert data["phone_number"] == test_phone
    assert data["safe_word_phrase"] == "help me nexa"
    assert "id" in data
    assert "password" not in data

    # Verify directly in PostgreSQL that password is not plaintext
    user_record = db_session.query(User).filter(User.email == test_email).first()
    assert user_record is not None
    assert user_record.hashed_password != payload["password"]
    assert user_record.hashed_password.startswith("$argon2id$")


def test_duplicate_registration_rejected(client):
    uid = uuid.uuid4().hex[:6]
    payload = {
        "email": f"anita_{uid}@example.com",
        "password": "Password12345678!",
        "full_name": "Anita Desai",
        "phone_number": f"+9198{uuid.uuid4().hex[:8]}",
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
    shared_phone = f"+9199{uuid.uuid4().hex[:8]}"
    user1 = {
        "email": f"user1_{uuid.uuid4().hex[:6]}@example.com",
        "password": "Password12345678!",
        "full_name": "User One",
        "phone_number": shared_phone
    }
    user2 = {
        "email": f"user2_{uuid.uuid4().hex[:6]}@example.com",
        "password": "Password12345678!",
        "full_name": "User Two",
        "phone_number": shared_phone
    }
    r1 = client.post("/api/v1/auth/register", json=user1)
    assert r1.status_code == 201

    r2 = client.post("/api/v1/auth/register", json=user2)
    assert r2.status_code == 409
    assert "phone number" in r2.json()["detail"].lower()


def test_login_success_and_failure(client):
    uid = uuid.uuid4().hex[:6]
    test_email = f"kavita_{uid}@example.com"
    credentials = {
        "email": test_email,
        "password": "StrongPassword999!",
        "full_name": "Kavita Patel",
        "phone_number": f"+9198{uuid.uuid4().hex[:8]}"
    }
    client.post("/api/v1/auth/register", json=credentials)

    # Valid login
    login_res = client.post("/api/v1/auth/login", json={
        "email": test_email,
        "password": "StrongPassword999!"
    })
    assert login_res.status_code == 200
    token_data = login_res.json()
    assert "access_token" in token_data
    assert token_data["token_type"] == "bearer"
    assert token_data["user"]["email"] == test_email

    # Invalid password login
    invalid_res = client.post("/api/v1/auth/login", json={
        "email": test_email,
        "password": "WrongPassword!"
    })
    assert invalid_res.status_code == 401
    assert "invalid email or password" in invalid_res.json()["detail"].lower()

    # Nonexistent user login
    nonexistent_res = client.post("/api/v1/auth/login", json={
        "email": f"nonexistent_{uuid.uuid4().hex[:6]}@example.com",
        "password": "Password123!"
    })
    assert nonexistent_res.status_code == 401


def test_authenticated_current_user_profile_and_isolation(client):
    uid_a = uuid.uuid4().hex[:6]
    uid_b = uuid.uuid4().hex[:6]
    email_a = f"user_a_{uid_a}@example.com"
    email_b = f"user_b_{uid_b}@example.com"

    # Register User A
    user_a_data = {
        "email": email_a,
        "password": "PasswordA123!",
        "full_name": "User Alpha",
        "phone_number": f"+9191{uuid.uuid4().hex[:8]}"
    }
    client.post("/api/v1/auth/register", json=user_a_data)
    login_a = client.post("/api/v1/auth/login", json={
        "email": user_a_data["email"],
        "password": user_a_data["password"]
    }).json()
    token_a = login_a["access_token"]

    # Register User B
    user_b_data = {
        "email": email_b,
        "password": "PasswordB123!",
        "full_name": "User Beta",
        "phone_number": f"+9192{uuid.uuid4().hex[:8]}"
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
    assert res_a.json()["email"] == email_a
    assert res_a.json()["full_name"] == "User Alpha"

    # User B accesses /me
    res_b = client.get(
        "/api/v1/users/me",
        headers={"Authorization": f"Bearer {token_b}"}
    )
    assert res_b.status_code == 200
    assert res_b.json()["email"] == email_b
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


def test_register_user_with_full_women_safety_profile(client, db_session):
    uid = uuid.uuid4().hex[:6]
    test_email = f"shielded_woman_{uid}@example.com"
    test_phone = f"+9198{uuid.uuid4().hex[:8]}"
    guardian_phone = f"+9197{uuid.uuid4().hex[:8]}"

    payload = {
        "email": test_email,
        "password": "ShieldedPassword2026#",
        "full_name": "Meera Krishnan",
        "phone_number": test_phone,
        "safe_word_phrase": "red falcon",
        "emergency_contact_name": "Kavita Krishnan",
        "emergency_contact_phone": guardian_phone,
        "emergency_contact_relation": "Mother",
        "home_address": "Flat 302, Palm Grove, Koramangala",
        "city_police_jurisdiction": "Koramangala PS, Bengaluru",
        "preferred_police_helpline": "112",
        "blood_group": "O+",
        "medical_notes": "Asthmatic, carries inhaler",
        "age": 25,
        "police_dispatch_consent": True
    }

    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == test_email
    assert data["emergency_contact_name"] == "Kavita Krishnan"
    assert data["emergency_contact_phone"] == guardian_phone
    assert data["emergency_contact_relation"] == "Mother"
    assert data["home_address"] == "Flat 302, Palm Grove, Koramangala"
    assert data["city_police_jurisdiction"] == "Koramangala PS, Bengaluru"
    assert data["preferred_police_helpline"] == "112"
    assert data["blood_group"] == "O+"
    assert data["medical_notes"] == "Asthmatic, carries inhaler"
    assert data["age"] == 25
    assert data["police_dispatch_consent"] is True

    # Verify directly in DB
    user_record = db_session.query(User).filter(User.email == test_email).first()
    assert user_record is not None
    assert user_record.blood_group == "O+"
    assert user_record.city_police_jurisdiction == "Koramangala PS, Bengaluru"

    # Verify primary guardian was automatically added to trusted contacts
    from app.models.contact import TrustedContact
    contact_record = db_session.query(TrustedContact).filter(
        TrustedContact.user_id == user_record.id,
        TrustedContact.phone_number == guardian_phone
    ).first()
    assert contact_record is not None
    assert contact_record.name == "Kavita Krishnan"
    assert contact_record.is_verified is True
