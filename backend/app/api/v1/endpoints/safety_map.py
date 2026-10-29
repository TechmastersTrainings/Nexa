from typing import List, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.repositories.safety_zone_repository import safety_zone_repository
from app.schemas.safety_map import SafetyReportCreate, SafetyReportResponse

router = APIRouter(prefix="/safety-map", tags=["Community Safety Map & Danger Zones"])


@router.get("/zones", response_model=List[SafetyReportResponse])
def get_safety_zones_in_radius(
    lat: float = Query(..., ge=-90.0, le=90.0, description="Center latitude coordinate"),
    lng: float = Query(..., ge=-180.0, le=180.0, description="Center longitude coordinate"),
    radius_km: float = Query(10.0, ge=0.1, le=100.0, description="Search radius in kilometers"),
    category: Optional[str] = Query(None, description="Filter by category"),
    db: Session = Depends(get_db),
):
    """
    Retrieves all community safety hazards and safe haven sanctuaries within the specified geographical radius.
    """
    zone_tuples = safety_zone_repository.get_zones_in_radius(
        db=db,
        center_lat=lat,
        center_lng=lng,
        radius_km=radius_km,
        category=category,
    )

    response_list: List[SafetyReportResponse] = []
    for report, dist in zone_tuples:
        res_item = SafetyReportResponse.model_validate(report)
        res_item.distance_km = dist
        response_list.append(res_item)

    return response_list


@router.post("/reports", response_model=SafetyReportResponse, status_code=status.HTTP_201_CREATED)
def submit_safety_report(
    report_in: SafetyReportCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Submits a community hazard report (poor lighting, harassment hotspot) or safe haven location.
    """
    report = safety_zone_repository.create(
        db=db,
        reporter_id=current_user.id,
        report_in=report_in,
    )
    return report


@router.post("/reports/{report_id}/upvote", response_model=SafetyReportResponse)
def upvote_safety_report(
    report_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Validates a community hazard or safe haven report with an upvote.
    """
    report = safety_zone_repository.upvote(db, report_id)
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Safety report record not found.",
        )
    return report


@router.get("/reports/recent", response_model=List[SafetyReportResponse])
def get_recent_safety_reports(
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
):
    """
    Lists recent community safety reports globally.
    """
    return safety_zone_repository.get_all(db, limit=limit)
