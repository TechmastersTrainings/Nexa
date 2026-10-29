from typing import List
from uuid import UUID
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.alert import AlertDispatchRequest, AlertDispatchResponse, AlertLogResponse
from app.services.alert_service import alert_service

router = APIRouter(prefix="/alerts", tags=["Emergency Alerts Delivery"])


@router.post("/dispatch", response_model=AlertDispatchResponse, status_code=status.HTTP_201_CREATED)
def dispatch_emergency_alerts(
    dispatch_in: AlertDispatchRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Triggers emergency alert broadcast (SMS or Voice) to the user's trusted contacts
    for a registered distress incident.
    """
    return alert_service.dispatch_alerts_for_incident(
        db=db,
        user=current_user,
        dispatch_in=dispatch_in,
    )


@router.get("/incident/{incident_id}", response_model=List[AlertLogResponse])
def get_alerts_for_incident(
    incident_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Retrieves all dispatch and delivery status logs for a specific incident.
    """
    return alert_service.get_incident_alerts(
        db=db,
        user_id=current_user.id,
        incident_id=incident_id,
    )


@router.get("/history", response_model=List[AlertLogResponse])
def get_user_alert_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Retrieves all emergency alert dispatch logs across all incidents for the authenticated user.
    """
    return alert_service.get_user_alerts(
        db=db,
        user_id=current_user.id,
    )
