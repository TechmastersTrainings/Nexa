from datetime import timedelta
import pytest
from fastapi import HTTPException
from app.core.security import (
    get_password_hash,
    verify_password,
    create_access_token,
    decode_access_token
)


def test_argon2id_hashing_and_verification():
    raw_password = "SecureSuperPassword2026!"
    hashed = get_password_hash(raw_password)

    # Argon2id hashes start with $argon2id$
    assert hashed.startswith("$argon2id$")
    assert hashed != raw_password

    # Correct password verifies
    assert verify_password(raw_password, hashed) is True

    # Incorrect password fails verification
    assert verify_password("WrongPassword123", hashed) is False


def test_jwt_token_generation_and_decoding():
    user_id = "11111111-2222-3333-4444-555555555555"
    token = create_access_token(subject=user_id, claims={"role": "user"})
    assert isinstance(token, str)

    payload = decode_access_token(token)
    assert payload["sub"] == user_id
    assert payload["role"] == "user"
    assert "exp" in payload
    assert "iat" in payload


def test_expired_jwt_token_raises_401():
    user_id = "11111111-2222-3333-4444-555555555555"
    # Create expired token (-10 minutes)
    expired_token = create_access_token(
        subject=user_id,
        expires_delta=timedelta(minutes=-10)
    )

    with pytest.raises(HTTPException) as exc_info:
        decode_access_token(expired_token)
    assert exc_info.value.status_code == 401
    assert "expired" in exc_info.value.detail.lower()


def test_tampered_jwt_token_raises_401():
    token = create_access_token(subject="valid_user")
    tampered_token = token[:-5] + "XXXXX"

    with pytest.raises(HTTPException) as exc_info:
        decode_access_token(tampered_token)
    assert exc_info.value.status_code == 401
