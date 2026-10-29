from sqlalchemy import Boolean, Column, Float, ForeignKey, Integer, String, DateTime, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import UUIDMixin, TimestampMixin, utc_now


class Incident(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "incidents"

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    client_incident_id = Column(String(100), nullable=False, index=True)
    trigger_type = Column(String(50), nullable=False, default="safe_word")
    status = Column(String(50), nullable=False, default="recorded")
    
    # Location information
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    accuracy_meters = Column(Float, nullable=True)
    location_timestamp = Column(DateTime(timezone=True), nullable=True)
    location_unavailable = Column(Boolean, nullable=False, default=False)
    
    # Device state at incident trigger
    battery_level = Column(Integer, nullable=True)
    local_created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    synchronized_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    # Unique constraint per user and client_incident_id ensures idempotency on retried sync
    __table_args__ = (
        UniqueConstraint("user_id", "client_incident_id", name="uq_user_client_incident"),
    )

    # Relationships
    user = relationship("User", back_populates="incidents")
    alert_logs = relationship("IncidentAlertLog", back_populates="incident", cascade="all, delete-orphan")
