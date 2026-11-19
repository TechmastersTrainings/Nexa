from datetime import datetime, timezone
from typing import Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import inspect
from sqlalchemy.orm import Session
from app.core.database import check_db_connection, get_db, engine, Base
from app.core.config import settings
import app.models

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


@router.get("/diagnostic", summary="Database Diagnostic & Auto-Migration")
def db_diagnostic(db: Session = Depends(get_db)) -> Dict[str, Any]:
    info: Dict[str, Any] = {
        "dialect": engine.dialect.name,
        "database_url_scheme": settings.DATABASE_URL.split("://")[0] if "://" in settings.DATABASE_URL else "unknown",
        "models_registered": list(Base.metadata.tables.keys()),
    }

    # Inspect tables existing in actual database
    try:
        inspector = inspect(engine)
        info["tables_in_db"] = inspector.get_table_names()
    except Exception as e:
        info["inspector_error"] = str(e)

    # Force create_all if tables missing
    try:
        Base.metadata.create_all(bind=engine)
        info["create_all_status"] = "success"
    except Exception as e:
        info["create_all_error"] = str(e)

    # Refresh inspector after create_all
    try:
        inspector = inspect(engine)
        info["tables_after_create_all"] = inspector.get_table_names()
    except Exception as e:
        info["inspector_refresh_error"] = str(e)

    # Query users count
    try:
        from app.models.user import User
        count = db.query(User).count()
        info["users_count"] = count
        info["users_query_status"] = "ok"
    except Exception as e:
        info["users_query_error"] = str(e)

    return info
