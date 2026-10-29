from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


class UserBase(BaseModel):
    email: EmailStr
    full_name: str = Field(..., min_length=2, max_length=100)
    phone_number: Optional[str] = Field(None, min_length=7, max_length=20)


class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=100, description="Password must be at least 8 characters long")
    safe_word_phrase: Optional[str] = Field("help me nexa", min_length=3, max_length=100)

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must contain at least 8 characters.")
        return v


class UserLogin(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=1)


class UserUpdate(BaseModel):
    full_name: Optional[str] = Field(None, min_length=2, max_length=100)
    phone_number: Optional[str] = Field(None, min_length=7, max_length=20)
    safe_word_phrase: Optional[str] = Field(None, min_length=3, max_length=100)
    emergency_sharing_enabled: Optional[bool] = None


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    email: EmailStr
    full_name: str
    phone_number: Optional[str] = None
    is_phone_verified: bool
    is_email_verified: bool
    is_active: bool
    role: str
    safe_word_phrase: str
    emergency_sharing_enabled: bool
    created_at: datetime
    updated_at: datetime
