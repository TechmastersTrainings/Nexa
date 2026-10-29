from typing import List
from uuid import UUID
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.contact import TrustedContactCreate, TrustedContactResponse, TrustedContactUpdate
from app.services.contact_service import contact_service

router = APIRouter(prefix="/contacts", tags=["Emergency Contacts"])


@router.post("", response_model=TrustedContactResponse, status_code=status.HTTP_201_CREATED)
def create_contact(
    contact_in: TrustedContactCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Add a new trusted emergency contact with tier priority."""
    return contact_service.add_contact(db, current_user.id, contact_in)


@router.get("", response_model=List[TrustedContactResponse])
def list_contacts(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all trusted emergency contacts for the authenticated user."""
    return contact_service.list_contacts(db, current_user.id)


@router.get("/{contact_id}", response_model=TrustedContactResponse)
def get_contact(
    contact_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Retrieve details of a specific emergency contact."""
    return contact_service.get_contact(db, contact_id, current_user.id)


@router.put("/{contact_id}", response_model=TrustedContactResponse)
def update_contact(
    contact_id: UUID,
    update_in: TrustedContactUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update contact information or priority order."""
    return contact_service.update_contact(db, contact_id, current_user.id, update_in)


@router.delete("/{contact_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_contact(
    contact_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Remove a contact from the emergency responder list."""
    contact_service.delete_contact(db, contact_id, current_user.id)


@router.post("/{contact_id}/verify", response_model=TrustedContactResponse)
def verify_contact(
    contact_id: UUID,
    code: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Verify a contact phone handshake with a 6-digit confirmation code."""
    return contact_service.verify_contact(db, contact_id, current_user.id, code)
