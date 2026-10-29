from typing import List, Optional
from uuid import UUID
from sqlalchemy.orm import Session
from app.models.contact import TrustedContact
from app.schemas.contact import TrustedContactCreate, TrustedContactUpdate


class ContactRepository:
    def create(self, db: Session, user_id: UUID, contact_in: TrustedContactCreate) -> TrustedContact:
        contact = TrustedContact(
            user_id=user_id,
            name=contact_in.name,
            phone_number=contact_in.phone_number,
            relationship=contact_in.relationship,
            priority_order=contact_in.priority_order,
            is_verified=False,
        )
        db.add(contact)
        db.commit()
        db.refresh(contact)
        return contact

    def get_by_id(self, db: Session, contact_id: UUID, user_id: UUID) -> Optional[TrustedContact]:
        return db.query(TrustedContact).filter(
            TrustedContact.id == contact_id,
            TrustedContact.user_id == user_id,
        ).first()

    def get_all_by_user(self, db: Session, user_id: UUID) -> List[TrustedContact]:
        return db.query(TrustedContact).filter(
            TrustedContact.user_id == user_id
        ).order_by(TrustedContact.priority_order.asc(), TrustedContact.created_at.asc()).all()

    def count_by_user(self, db: Session, user_id: UUID) -> int:
        return db.query(TrustedContact).filter(TrustedContact.user_id == user_id).count()

    def update(self, db: Session, contact: TrustedContact, update_in: TrustedContactUpdate) -> TrustedContact:
        update_data = update_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(contact, field, value)
        db.add(contact)
        db.commit()
        db.refresh(contact)
        return contact

    def delete(self, db: Session, contact: TrustedContact) -> None:
        db.delete(contact)
        db.commit()


contact_repository = ContactRepository()
