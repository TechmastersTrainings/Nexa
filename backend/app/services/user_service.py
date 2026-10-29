from datetime import timedelta
from typing import Optional
from uuid import UUID
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.security import get_password_hash, verify_password, create_access_token
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserCreate, UserLogin, UserResponse, UserUpdate
from app.schemas.token import TokenResponse


class UserService:
    @staticmethod
    def register_user(db: Session, user_in: UserCreate) -> UserResponse:
        # Check duplicate email
        existing_email = UserRepository.get_by_email(db, user_in.email)
        if existing_email:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="An account with this email address already exists."
            )

        # Check duplicate phone if provided
        if user_in.phone_number:
            existing_phone = UserRepository.get_by_phone(db, user_in.phone_number)
            if existing_phone:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="An account with this phone number already exists."
                )

        hashed_password = get_password_hash(user_in.password)
        new_user = UserRepository.create(db, user_in, hashed_password)
        return UserResponse.model_validate(new_user)

    @staticmethod
    def authenticate_user(db: Session, credentials: UserLogin) -> TokenResponse:
        user = UserRepository.get_by_email(db, credentials.email)
        
        # Constant time-like check to prevent account enumeration
        if not user or not verify_password(credentials.password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password.",
                headers={"WWW-Authenticate": "Bearer"}
            )

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User account is deactivated. Please contact support."
            )

        # Generate JWT access token with subject=user.id
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        token = create_access_token(
            subject=str(user.id),
            expires_delta=access_token_expires,
            claims={"role": user.role}
        )

        return TokenResponse(
            access_token=token,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            user=UserResponse.model_validate(user)
        )

    @staticmethod
    def get_profile(db: Session, user_id: UUID) -> UserResponse:
        user = UserRepository.get_by_id(db, user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User profile not found."
            )
        return UserResponse.model_validate(user)

    @staticmethod
    def update_profile(db: Session, user_id: UUID, update_in: UserUpdate) -> UserResponse:
        user = UserRepository.get_by_id(db, user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User profile not found."
            )

        if update_in.phone_number and update_in.phone_number != user.phone_number:
            existing_phone = UserRepository.get_by_phone(db, update_in.phone_number)
            if existing_phone and existing_phone.id != user.id:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="This phone number is already registered by another account."
                )

        updated_user = UserRepository.update(db, user, update_in)
        return UserResponse.model_validate(updated_user)
