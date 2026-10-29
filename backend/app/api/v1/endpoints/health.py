from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException, status
from app.core.database import check_db_connection

router = APIRouter()


@router.get("", summary="System Health and Database Readiness")
def health_check():
    db_ok = check_db_connection()
    if not db_ok:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "status": "degraded",
                "database": "disconnected",
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
        )
    return {
        "status": "healthy",
        "service": "Nexa Safety Platform API",
        "database": "connected",
        "timestamp": datetime.now(timezone.utc).isoformat()
    }
