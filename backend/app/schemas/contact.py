from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field


class TrustedContactBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    phone_number: str = Field(..., min_length=7, max_length=20)
    relationship: str = Field("Family", max_length=50)
    priority_order: int = Field(1, ge=1, le=10)


class TrustedContactCreate(TrustedContactBase):
    pass


class TrustedContactUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=100)
    phone_number: Optional[str] = Field(None, min_length=7, max_length=20)
    relationship: Optional[str] = Field(None, max_length=50)
    priority_order: Optional[int] = Field(None, ge=1, le=10)


class TrustedContactResponse(TrustedContactBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    is_verified: bool
    created_at: datetime
    updated_at: datetime
