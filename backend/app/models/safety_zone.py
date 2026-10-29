from sqlalchemy import Boolean, Column, Float, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import UUIDMixin, TimestampMixin


class SafetyReport(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "safety_reports"

    reporter_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    title = Column(String(150), nullable=False)
    description = Column(Text, nullable=True)
    category = Column(String(50), nullable=False, default="poor_lighting")
    severity_level = Column(Integer, nullable=False, default=3)  # 1 (Safe Haven) to 5 (Severe Hazard)
    latitude = Column(Float, nullable=False, index=True)
    longitude = Column(Float, nullable=False, index=True)
    radius_meters = Column(Float, nullable=False, default=150.0)
    is_verified = Column(Boolean, nullable=False, default=False)
    upvotes = Column(Integer, nullable=False, default=0)

    # Relationships
    reporter = relationship("User")
