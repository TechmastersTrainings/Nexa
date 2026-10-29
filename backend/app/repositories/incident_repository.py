from typing import List, Optional
from uuid import UUID
from sqlalchemy.orm import Session
from app.models.incident import Incident
from app.schemas.incident import IncidentCreate


class IncidentRepository:
    def create(self, db: Session, user_id: UUID, incident_in: IncidentCreate) -> Incident:
        incident = Incident(
            user_id=user_id,
            client_incident_id=incident_in.client_incident_id,
            trigger_type=incident_in.trigger_type,
            status="recorded",
            latitude=incident_in.latitude,
            longitude=incident_in.longitude,
            accuracy_meters=incident_in.accuracy_meters,
            location_timestamp=incident_in.location_timestamp,
            location_unavailable=incident_in.location_unavailable,
            battery_level=incident_in.battery_level,
            local_created_at=incident_in.local_created_at,
        )
        db.add(incident)
        db.commit()
        db.refresh(incident)
        return incident

    def get_by_client_id(self, db: Session, user_id: UUID, client_incident_id: str) -> Optional[Incident]:
        return db.query(Incident).filter(
            Incident.user_id == user_id,
            Incident.client_incident_id == client_incident_id,
        ).first()

    def get_by_id(self, db: Session, incident_id: UUID, user_id: UUID) -> Optional[Incident]:
        return db.query(Incident).filter(
            Incident.id == incident_id,
            Incident.user_id == user_id,
        ).first()

    def get_all_by_user(self, db: Session, user_id: UUID) -> List[Incident]:
        return db.query(Incident).filter(
            Incident.user_id == user_id
        ).order_by(Incident.created_at.desc()).all()


incident_repository = IncidentRepository()
