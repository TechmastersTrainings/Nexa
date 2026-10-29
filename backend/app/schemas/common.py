from typing import Generic, Optional, TypeVar
from pydantic import BaseModel

T = TypeVar("T")


class APIResponse(BaseModel, Generic[T]):
    success: bool = True
    message: str = "Operation completed successfully"
    data: Optional[T] = None


class ErrorDetail(BaseModel):
    code: str
    message: str
    details: Optional[dict] = None


class APIErrorResponse(BaseModel):
    success: bool = False
    error: ErrorDetail
