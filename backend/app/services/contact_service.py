import random
import string
from typing import List
from uuid import UUID
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.core.config import settings
from app.models.contact import TrustedContact
from app.repositories.contact_repository import contact_repository
from app.schemas.contact import TrustedContactCreate, TrustedContactUpdate


class ContactService:
    MAX_CONTACTS = 5

    def add_contact(self, db: Session, user_id: UUID, contact_in: TrustedContactCreate) -> TrustedContact:
        count = contact_repository.count_by_user(db, user_id)
        if count >= self.MAX_CONTACTS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Maximum emergency contacts limit ({self.MAX_CONTACTS}) reached.",
            )

        # Check if phone already in user's contacts
        existing_contacts = contact_repository.get_all_by_user(db, user_id)
        if any(c.phone_number == contact_in.phone_number for c in existing_contacts):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A trusted contact with this phone number already exists.",
            )

        contact = contact_repository.create(db, user_id, contact_in)
        # Generate 6-digit verification code
        code = "".join(random.choices(string.digits, k=6))
        contact.verification_code = code
        db.add(contact)
        db.commit()
        db.refresh(contact)
        return contact

    def get_contact(self, db: Session, contact_id: UUID, user_id: UUID) -> TrustedContact:
        contact = contact_repository.get_by_id(db, contact_id, user_id)
        if not contact:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Trusted contact not found.",
            )
        return contact

    def list_contacts(self, db: Session, user_id: UUID) -> List[TrustedContact]:
        return contact_repository.get_all_by_user(db, user_id)

    def update_contact(
        self, db: Session, contact_id: UUID, user_id: UUID, update_in: TrustedContactUpdate
    ) -> TrustedContact:
        contact = self.get_contact(db, contact_id, user_id)
        
        # If updating phone number, verify no duplicate
        if update_in.phone_number and update_in.phone_number != contact.phone_number:
            existing = contact_repository.get_all_by_user(db, user_id)
            if any(c.phone_number == update_in.phone_number and c.id != contact.id for c in existing):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="A trusted contact with this phone number already exists.",
                )

        return contact_repository.update(db, contact, update_in)

    def delete_contact(self, db: Session, contact_id: UUID, user_id: UUID) -> None:
        contact = self.get_contact(db, contact_id, user_id)
        contact_repository.delete(db, contact)

    def verify_contact(self, db: Session, contact_id: UUID, user_id: UUID, code: str) -> TrustedContact:
        contact = self.get_contact(db, contact_id, user_id)
        if contact.is_verified:
            return contact
        
        is_debug_code = settings.DEBUG and code.strip() == "123456"
        if not is_debug_code and (not contact.verification_code or contact.verification_code != code.strip()):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid verification code.",
            )
        contact.is_verified = True
        contact.verification_code = None
        db.add(contact)
        db.commit()
        db.refresh(contact)
        return contact


contact_service = ContactService()
