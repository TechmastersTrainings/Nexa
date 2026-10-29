from sqlalchemy import Boolean, Column, ForeignKey, String, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import UUIDMixin, TimestampMixin, utc_now


class UserDevice(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "user_devices"

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    device_id = Column(String(100), nullable=False, index=True)
    device_name = Column(String(100), nullable=False)
    platform = Column(String(50), nullable=False, default="android")
    app_version = Column(String(50), nullable=False)
    fcm_token = Column(String(255), nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)
    last_active_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    # Relationship
    user = relationship("User", back_populates="devices")
