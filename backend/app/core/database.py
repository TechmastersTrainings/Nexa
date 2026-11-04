import logging
from typing import Generator
from sqlalchemy import create_engine, text
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from app.core.config import settings

logger = logging.getLogger(__name__)

# Determine active database engine (PostgreSQL or resilient SQLite fallback)
def init_engine():
    try:
        pg_engine = create_engine(
            settings.DATABASE_URL,
            pool_pre_ping=True,
            pool_size=10,
            max_overflow=20,
            echo=False,
            connect_args={"connect_timeout": 2} if "postgresql" in settings.DATABASE_URL else {}
        )
        with pg_engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        logger.info("Connected to PostgreSQL production database successfully.")
        return pg_engine
    except Exception as ex:
        logger.warning(
            f"PostgreSQL connection to {settings.POSTGRES_SERVER}:{settings.POSTGRES_PORT} not active ({ex}). "
            "Falling back to local SQLite database (nexa_safety.db) for zero-downtime availability."
        )
        sqlite_engine = create_engine(
            "sqlite:///./nexa_safety.db",
            connect_args={"check_same_thread": False},
            echo=False
        )
        return sqlite_engine


engine = init_engine()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db() -> Generator[Session, None, None]:
    """Dependency that provides a transactional database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def check_db_connection() -> bool:
    """Execute simple test query to verify live database connection."""
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
            return True
    except Exception:
        return False
