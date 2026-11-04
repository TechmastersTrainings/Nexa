from sqlalchemy import Boolean, Column, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import UUIDMixin, TimestampMixin


class User(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "users"

    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100), nullable=False)
    phone_number = Column(String(20), unique=True, index=True, nullable=True)
    is_phone_verified = Column(Boolean, default=False, nullable=False)
    is_email_verified = Column(Boolean, default=False, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    role = Column(String(20), default="user", nullable=False)

    # Primary Emergency Guardian / Contact Info
    emergency_contact_name = Column(String(100), nullable=True)
    emergency_contact_phone = Column(String(20), nullable=True)
    emergency_contact_relation = Column(String(50), nullable=True)

    # Location & Police Jurisdiction
    home_address = Column(String(255), nullable=True)
    city_police_jurisdiction = Column(String(100), nullable=True)
    preferred_police_helpline = Column(String(20), default="112", nullable=False)

    # Medical & Rescue Telemetry
    blood_group = Column(String(10), nullable=True)
    medical_notes = Column(String(255), nullable=True)
    age = Column(Integer, nullable=True)

    # Safety preferences & Covert Duress
    safe_word_phrase = Column(String(100), default="help me nexa", nullable=False)
    emergency_sharing_enabled = Column(Boolean, default=True, nullable=False)
    police_dispatch_consent = Column(Boolean, default=True, nullable=False)

    # Relationships
    contacts = relationship("TrustedContact", back_populates="user", cascade="all, delete-orphan")
    devices = relationship("UserDevice", back_populates="user", cascade="all, delete-orphan")
    incidents = relationship("Incident", back_populates="user", cascade="all, delete-orphan")
