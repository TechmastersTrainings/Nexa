from typing import Optional
from pydantic import BaseModel
from app.schemas.user import UserResponse


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserResponse


class TokenPayload(BaseModel):
    sub: str
    iat: int
    exp: int
    type: str = "access"


class RefreshTokenRequest(BaseModel):
    refresh_token: str
