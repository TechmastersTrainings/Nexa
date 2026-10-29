from typing import List, Optional
from uuid import UUID
from sqlalchemy.orm import Session
from app.models.alert import IncidentAlertLog
from app.models.incident import Incident


class AlertRepository:
    def create(
        self,
        db: Session,
        incident_id: UUID,
        recipient_phone: str,
        message_body: str,
        provider: str = "twilio",
        provider_message_id: Optional[str] = None,
        delivery_status: str = "sent",
        status_details: Optional[str] = None,
        recipient_contact_id: Optional[UUID] = None,
        error_message: Optional[str] = None,
        attempt_number: int = 1,
    ) -> IncidentAlertLog:
        alert_log = IncidentAlertLog(
            incident_id=incident_id,
            recipient_contact_id=recipient_contact_id,
            recipient_phone=recipient_phone,
            message_body=message_body,
            provider=provider,
            provider_message_id=provider_message_id,
            delivery_status=delivery_status,
            status_details=status_details,
            attempt_number=attempt_number,
            error_message=error_message,
        )
        db.add(alert_log)
        db.commit()
        db.refresh(alert_log)
        return alert_log

    def get_by_incident_id(self, db: Session, incident_id: UUID) -> List[IncidentAlertLog]:
        return db.query(IncidentAlertLog).filter(
            IncidentAlertLog.incident_id == incident_id
        ).order_by(IncidentAlertLog.created_at.desc()).all()

    def get_by_user_id(self, db: Session, user_id: UUID) -> List[IncidentAlertLog]:
        return (
            db.query(IncidentAlertLog)
            .join(Incident, IncidentAlertLog.incident_id == Incident.id)
            .filter(Incident.user_id == user_id)
            .order_by(IncidentAlertLog.created_at.desc())
            .all()
        )

    def get_by_id(self, db: Session, alert_id: UUID) -> Optional[IncidentAlertLog]:
        return db.query(IncidentAlertLog).filter(IncidentAlertLog.id == alert_id).first()


alert_repository = AlertRepository()
