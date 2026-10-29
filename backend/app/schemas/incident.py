from datetime import datetime
from typing import List, Optional
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field


class IncidentCreate(BaseModel):
    client_incident_id: str = Field(..., min_length=1, max_length=100)
    trigger_type: str = Field("safe_word", max_length=50)
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    accuracy_meters: Optional[float] = None
    location_timestamp: Optional[datetime] = None
    location_unavailable: bool = False
    battery_level: Optional[int] = Field(None, ge=0, le=100)
    local_created_at: datetime


class IncidentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    client_incident_id: str
    trigger_type: str
    status: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    accuracy_meters: Optional[float] = None
    location_timestamp: Optional[datetime] = None
    location_unavailable: bool
    battery_level: Optional[int] = None
    local_created_at: datetime
    synchronized_at: datetime
    created_at: datetime
    updated_at: datetime


class IncidentSyncBatchRequest(BaseModel):
    incidents: List[IncidentCreate]


class IncidentSyncBatchResponse(BaseModel):
    processed_count: int
    synced_incidents: List[IncidentResponse]
    duplicate_count: int
