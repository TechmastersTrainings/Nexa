from datetime import datetime
from typing import List, Optional
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field


class AlertLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    incident_id: UUID
    recipient_contact_id: Optional[UUID] = None
    recipient_phone: str
    message_body: str
    provider: str
    provider_message_id: Optional[str] = None
    delivery_status: str
    status_details: Optional[str] = None
    attempt_number: int
    error_message: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class AlertDispatchRequest(BaseModel):
    incident_id: UUID
    alert_type: str = Field("sms", description="'sms', 'voice', or 'all'")
    recipient_ids: Optional[List[UUID]] = Field(None, description="Optional specific contact IDs to target")


class AlertDispatchResponse(BaseModel):
    incident_id: UUID
    dispatched_count: int
    failed_count: int
    alerts: List[AlertLogResponse]
