from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field


class SafetyReportCreate(BaseModel):
    title: str = Field(..., min_length=3, max_length=150)
    description: Optional[str] = Field(None, max_length=1000)
    category: str = Field(
        "poor_lighting",
        description="Hazard or sanctuary category: 'poor_lighting', 'harassment_hotspot', 'isolated_route', 'safe_haven', 'police_booth', 'hospital'",
    )
    severity_level: int = Field(3, ge=1, le=5, description="1 (Safe Haven / Sanctuary) to 5 (Critical Danger / Hazard)")
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    radius_meters: float = Field(150.0, ge=10.0, le=5000.0)


class SafetyReportResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    reporter_id: Optional[UUID] = None
    title: str
    description: Optional[str] = None
    category: str
    severity_level: int
    latitude: float
    longitude: float
    radius_meters: float
    is_verified: bool
    upvotes: int
    distance_km: Optional[float] = None
    created_at: datetime
    updated_at: datetime
