from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship as orm_relationship
from app.core.database import Base
from app.models.base import UUIDMixin, TimestampMixin


class TrustedContact(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "trusted_contacts"

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(100), nullable=False)
    phone_number = Column(String(20), nullable=False)
    relationship = Column(String(50), nullable=False, default="Family")
    priority_order = Column(Integer, nullable=False, default=1)
    is_verified = Column(Boolean, nullable=False, default=False)
    verification_code = Column(String(10), nullable=True)
    verification_sent_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships using orm_relationship alias
    user = orm_relationship("User", back_populates="contacts")
    alert_logs = orm_relationship("IncidentAlertLog", back_populates="contact")
