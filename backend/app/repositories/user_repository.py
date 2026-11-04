from typing import Optional
from uuid import UUID
from sqlalchemy.orm import Session
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate


class UserRepository:
    @staticmethod
    def get_by_id(db: Session, user_id: UUID) -> Optional[User]:
        return db.query(User).filter(User.id == user_id).first()

    @staticmethod
    def get_by_email(db: Session, email: str) -> Optional[User]:
        return db.query(User).filter(User.email == email.lower().strip()).first()

    @staticmethod
    def get_by_phone(db: Session, phone_number: str) -> Optional[User]:
        if not phone_number:
            return None
        return db.query(User).filter(User.phone_number == phone_number.strip()).first()

    @staticmethod
    def create(db: Session, user_in: UserCreate, hashed_password: str) -> User:
        user = User(
            email=user_in.email.lower().strip(),
            hashed_password=hashed_password,
            full_name=user_in.full_name.strip(),
            phone_number=user_in.phone_number.strip() if user_in.phone_number else None,
            safe_word_phrase=user_in.safe_word_phrase.strip() if user_in.safe_word_phrase else "help me nexa",
            is_active=True,
            is_phone_verified=False,
            is_email_verified=False,
            role="user",
            # Women Safety & Emergency Protection Profile
            emergency_contact_name=user_in.emergency_contact_name.strip() if user_in.emergency_contact_name else None,
            emergency_contact_phone=user_in.emergency_contact_phone.strip() if user_in.emergency_contact_phone else None,
            emergency_contact_relation=user_in.emergency_contact_relation.strip() if user_in.emergency_contact_relation else None,
            home_address=user_in.home_address.strip() if user_in.home_address else None,
            city_police_jurisdiction=user_in.city_police_jurisdiction.strip() if user_in.city_police_jurisdiction else None,
            preferred_police_helpline=user_in.preferred_police_helpline.strip() if user_in.preferred_police_helpline else "112",
            blood_group=user_in.blood_group.strip() if user_in.blood_group else None,
            medical_notes=user_in.medical_notes.strip() if user_in.medical_notes else None,
            age=user_in.age if user_in.age is not None else None,
            police_dispatch_consent=user_in.police_dispatch_consent if user_in.police_dispatch_consent is not None else True,
        )
        db.add(user)
        db.commit()
        db.refresh(user)

        # Automatically enroll primary emergency guardian into trusted contacts network
        if user_in.emergency_contact_name and user_in.emergency_contact_phone:
            try:
                from app.models.contact import TrustedContact
                guardian = TrustedContact(
                    user_id=user.id,
                    name=user_in.emergency_contact_name.strip(),
                    phone_number=user_in.emergency_contact_phone.strip(),
                    relationship=user_in.emergency_contact_relation.strip() if user_in.emergency_contact_relation else "Primary Guardian",
                    priority_order=1,
                    is_verified=True,
                )
                db.add(guardian)
                db.commit()
            except Exception:
                db.rollback()

        return user

    @staticmethod
    def update(db: Session, user: User, update_data: UserUpdate) -> User:
        if update_data.full_name is not None:
            user.full_name = update_data.full_name.strip()
        if update_data.phone_number is not None:
            user.phone_number = update_data.phone_number.strip()
            # Changing phone number resets phone verification status
            user.is_phone_verified = False
        if update_data.safe_word_phrase is not None:
            user.safe_word_phrase = update_data.safe_word_phrase.strip()
        if update_data.emergency_sharing_enabled is not None:
            user.emergency_sharing_enabled = update_data.emergency_sharing_enabled

        # Women Safety & Emergency Protection Updates
        if update_data.emergency_contact_name is not None:
            user.emergency_contact_name = update_data.emergency_contact_name.strip()
        if update_data.emergency_contact_phone is not None:
            user.emergency_contact_phone = update_data.emergency_contact_phone.strip()
        if update_data.emergency_contact_relation is not None:
            user.emergency_contact_relation = update_data.emergency_contact_relation.strip()
        if update_data.home_address is not None:
            user.home_address = update_data.home_address.strip()
        if update_data.city_police_jurisdiction is not None:
            user.city_police_jurisdiction = update_data.city_police_jurisdiction.strip()
        if update_data.preferred_police_helpline is not None:
            user.preferred_police_helpline = update_data.preferred_police_helpline.strip()
        if update_data.blood_group is not None:
            user.blood_group = update_data.blood_group.strip()
        if update_data.medical_notes is not None:
            user.medical_notes = update_data.medical_notes.strip()
        if update_data.age is not None:
            user.age = update_data.age
        if update_data.police_dispatch_consent is not None:
            user.police_dispatch_consent = update_data.police_dispatch_consent

        db.commit()
        db.refresh(user)
        return user

    @staticmethod
    def delete(db: Session, user: User) -> None:
        db.delete(user)
        db.commit()
