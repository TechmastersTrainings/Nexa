import math
from typing import List, Optional, Tuple
from uuid import UUID
from sqlalchemy.orm import Session
from app.models.safety_zone import SafetyReport
from app.schemas.safety_map import SafetyReportCreate


def haversine_distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0  # Earth radius in kilometers
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = (
        math.sin(delta_phi / 2.0) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0) ** 2
    )
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return R * c


class SafetyZoneRepository:
    def create(self, db: Session, reporter_id: Optional[UUID], report_in: SafetyReportCreate) -> SafetyReport:
        report = SafetyReport(
            reporter_id=reporter_id,
            title=report_in.title,
            description=report_in.description,
            category=report_in.category,
            severity_level=report_in.severity_level,
            latitude=report_in.latitude,
            longitude=report_in.longitude,
            radius_meters=report_in.radius_meters,
            is_verified=report_in.severity_level == 1,  # Safe havens start auto-verified or standard
            upvotes=0,
        )
        db.add(report)
        db.commit()
        db.refresh(report)
        return report

    def get_by_id(self, db: Session, report_id: UUID) -> Optional[SafetyReport]:
        return db.query(SafetyReport).filter(SafetyReport.id == report_id).first()

    def get_zones_in_radius(
        self,
        db: Session,
        center_lat: float,
        center_lng: float,
        radius_km: float = 10.0,
        category: Optional[str] = None,
    ) -> List[Tuple[SafetyReport, float]]:
        # Approximate bounding box to filter efficiently before precise Haversine
        # 1 deg latitude ~ 111 km
        lat_delta = radius_km / 111.0
        # 1 deg longitude ~ 111 km * cos(lat)
        lng_delta = radius_km / (111.0 * max(0.1, math.cos(math.radians(center_lat))))

        query = db.query(SafetyReport).filter(
            SafetyReport.latitude >= center_lat - lat_delta,
            SafetyReport.latitude <= center_lat + lat_delta,
            SafetyReport.longitude >= center_lng - lng_delta,
            SafetyReport.longitude <= center_lng + lng_delta,
        )

        if category:
            query = query.filter(SafetyReport.category == category)

        candidates = query.all()

        results: List[Tuple[SafetyReport, float]] = []
        for cand in candidates:
            dist = haversine_distance_km(center_lat, center_lng, cand.latitude, cand.longitude)
            if dist <= radius_km:
                results.append((cand, round(dist, 2)))

        # Sort by distance
        results.sort(key=lambda x: x[1])
        return results

    def upvote(self, db: Session, report_id: UUID) -> Optional[SafetyReport]:
        report = self.get_by_id(db, report_id)
        if not report:
            return None
        report.upvotes += 1
        db.add(report)
        db.commit()
        db.refresh(report)
        return report

    def get_all(self, db: Session, limit: int = 100) -> List[SafetyReport]:
        return db.query(SafetyReport).order_by(SafetyReport.created_at.desc()).limit(limit).all()


safety_zone_repository = SafetyZoneRepository()
