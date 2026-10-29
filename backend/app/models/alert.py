from sqlalchemy import Column, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import UUIDMixin, TimestampMixin


class IncidentAlertLog(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "incident_alert_logs"

    incident_id = Column(UUID(as_uuid=True), ForeignKey("incidents.id", ondelete="CASCADE"), nullable=False, index=True)
    recipient_contact_id = Column(UUID(as_uuid=True), ForeignKey("trusted_contacts.id", ondelete="SET NULL"), nullable=True)
    recipient_phone = Column(String(20), nullable=False)
    message_body = Column(Text, nullable=False)
    provider = Column(String(50), nullable=False, default="twilio")
    provider_message_id = Column(String(100), nullable=True, index=True)
    delivery_status = Column(String(50), nullable=False, default="queued")
    status_details = Column(Text, nullable=True)
    attempt_number = Column(Integer, nullable=False, default=1)
    error_message = Column(Text, nullable=True)

    # Relationships
    incident = relationship("Incident", back_populates="alert_logs")
    contact = relationship("TrustedContact", back_populates="alert_logs")
