import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, String, TypeDecorator
from sqlalchemy.dialects.postgresql import UUID as PG_UUID


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class GUID(TypeDecorator):
    """
    Platform-independent GUID/UUID type.
    Uses PostgreSQL's native UUID when available, otherwise falls back to String(36).
    """
    impl = String(36)
    cache_ok = True

    def __init__(self, as_uuid=True, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.as_uuid = as_uuid

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            return dialect.type_descriptor(PG_UUID(as_uuid=self.as_uuid))
        else:
            return dialect.type_descriptor(String(36))

    def process_bind_param(self, value, dialect):
        if value is None:
            return value
        return str(value)

    def process_result_value(self, value, dialect):
        if value is None:
            return value
        if not isinstance(value, uuid.UUID):
            return uuid.UUID(str(value))
        return value


# Alias so existing models can import UUID from app.models.base
UUID = GUID


class TimestampMixin:
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)


class UUIDMixin:
    id = Column(GUID(as_uuid=True), primary_key=True, default=uuid.uuid4, nullable=False)
