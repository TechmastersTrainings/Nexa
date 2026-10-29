from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserResponse, UserUpdate
from app.services.user_service import UserService

router = APIRouter()


@router.get("/me", response_model=UserResponse, summary="Get Current Authenticated User Profile")
def get_current_user_profile(
    current_user: User = Depends(get_current_user)
):
    """Retrieve private profile details for the authenticated user."""
    return UserResponse.model_validate(current_user)


@router.patch("/me", response_model=UserResponse, summary="Update Authenticated User Profile")
def update_current_user_profile(
    update_in: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update profile information for the authenticated user."""
    return UserService.update_profile(db=db, user_id=current_user.id, update_in=update_in)


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT, summary="Delete Authenticated User Account")
def delete_current_user_account(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Permanently delete user account and associated private data."""
    UserRepository.delete(db=db, user=current_user)
    return None
