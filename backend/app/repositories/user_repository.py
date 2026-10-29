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
            role="user"
        )
        db.add(user)
        db.commit()
        db.refresh(user)
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

        db.commit()
        db.refresh(user)
        return user

    @staticmethod
    def delete(db: Session, user: User) -> None:
        db.delete(user)
        db.commit()
