from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.user import UserCreate, UserLogin, UserResponse
from app.schemas.token import TokenResponse
from app.services.user_service import UserService

router = APIRouter()


@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register New User"
)
def register(
    user_in: UserCreate,
    db: Session = Depends(get_db)
):
    """
    Register a new user account with Argon2id password hashing.
    Validates email format, unique email, unique phone number, and password length.
    """
    return UserService.register_user(db=db, user_in=user_in)


@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="User Login"
)
def login(
    credentials: UserLogin,
    db: Session = Depends(get_db)
):
    """
    Authenticate user with email and password.
    Returns JWT bearer token and public user profile upon valid credentials.
    """
    return UserService.authenticate_user(db=db, credentials=credentials)
