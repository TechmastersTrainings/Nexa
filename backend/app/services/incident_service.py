from typing import List
from uuid import UUID
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.models.incident import Incident
from app.repositories.incident_repository import incident_repository
from app.schemas.incident import IncidentCreate, IncidentSyncBatchRequest, IncidentSyncBatchResponse


class IncidentService:
    def record_incident(self, db: Session, user_id: UUID, incident_in: IncidentCreate) -> Incident:
        # Check idempotency
        existing = incident_repository.get_by_client_id(db, user_id, incident_in.client_incident_id)
        if existing:
            return existing

        return incident_repository.create(db, user_id, incident_in)

    def sync_batch(self, db: Session, user_id: UUID, batch_in: IncidentSyncBatchRequest) -> IncidentSyncBatchResponse:
        synced: List[Incident] = []
        duplicate_count = 0

        for inc_item in batch_in.incidents:
            existing = incident_repository.get_by_client_id(db, user_id, inc_item.client_incident_id)
            if existing:
                duplicate_count += 1
                synced.append(existing)
            else:
                new_inc = incident_repository.create(db, user_id, inc_item)
                synced.append(new_inc)

        return IncidentSyncBatchResponse(
            processed_count=len(batch_in.incidents),
            synced_incidents=synced,
            duplicate_count=duplicate_count,
        )

    def list_incidents(self, db: Session, user_id: UUID) -> List[Incident]:
        return incident_repository.get_all_by_user(db, user_id)

    def get_incident(self, db: Session, incident_id: UUID, user_id: UUID) -> Incident:
        incident = incident_repository.get_by_id(db, incident_id, user_id)
        if not incident:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Incident record not found.",
            )
        return incident


incident_service = IncidentService()
