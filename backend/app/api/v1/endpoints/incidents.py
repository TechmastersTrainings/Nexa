from typing import List
from uuid import UUID
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.incident import (
    IncidentCreate,
    IncidentResponse,
    IncidentSyncBatchRequest,
    IncidentSyncBatchResponse,
)
from app.services.incident_service import incident_service

router = APIRouter(prefix="/incidents", tags=["Incidents & Emergency Telemetry"])


@router.post("", response_model=IncidentResponse, status_code=status.HTTP_201_CREATED)
def record_incident(
    incident_in: IncidentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Record an emergency distress incident with GPS location telemetry."""
    return incident_service.record_incident(db, current_user.id, incident_in)


@router.post("/sync", response_model=IncidentSyncBatchResponse)
def sync_offline_queue(
    batch_in: IncidentSyncBatchRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Synchronize an offline local incident queue buffer with idempotency."""
    return incident_service.sync_batch(db, current_user.id, batch_in)


@router.get("", response_model=List[IncidentResponse])
def list_incidents(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Retrieve distress incident history for the authenticated user."""
    return incident_service.list_incidents(db, current_user.id)


@router.get("/{incident_id}", response_model=IncidentResponse)
def get_incident(
    incident_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get details of a specific incident."""
    return incident_service.get_incident(db, incident_id, current_user.id)
