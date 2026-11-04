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

    # Primary Emergency Guardian / Contact Info
    emergency_contact_name: Optional[str] = Field(None, max_length=100)
    emergency_contact_phone: Optional[str] = Field(None, max_length=20)
    emergency_contact_relation: Optional[str] = Field(None, max_length=50)

    # Safe Zone & Police Protection
    home_address: Optional[str] = Field(None, max_length=255)
    city_police_jurisdiction: Optional[str] = Field(None, max_length=100)
    preferred_police_helpline: Optional[str] = Field("112", max_length=20)

    # Medical & Rescue Telemetry
    blood_group: Optional[str] = Field(None, max_length=10)
    medical_notes: Optional[str] = Field(None, max_length=255)
    age: Optional[int] = Field(None, ge=1, le=120)

    # Safety preferences & Consent
    police_dispatch_consent: Optional[bool] = Field(True)

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

    # Primary Emergency Guardian
    emergency_contact_name: Optional[str] = Field(None, max_length=100)
    emergency_contact_phone: Optional[str] = Field(None, max_length=20)
    emergency_contact_relation: Optional[str] = Field(None, max_length=50)

    # Location & Police
    home_address: Optional[str] = Field(None, max_length=255)
    city_police_jurisdiction: Optional[str] = Field(None, max_length=100)
    preferred_police_helpline: Optional[str] = Field(None, max_length=20)

    # Medical & Identity
    blood_group: Optional[str] = Field(None, max_length=10)
    medical_notes: Optional[str] = Field(None, max_length=255)
    age: Optional[int] = Field(None, ge=1, le=120)
    police_dispatch_consent: Optional[bool] = None


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

    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    emergency_contact_relation: Optional[str] = None

    home_address: Optional[str] = None
    city_police_jurisdiction: Optional[str] = None
    preferred_police_helpline: str = "112"

    blood_group: Optional[str] = None
    medical_notes: Optional[str] = None
    age: Optional[int] = None
    police_dispatch_consent: bool = True

    created_at: datetime
    updated_at: datetime
