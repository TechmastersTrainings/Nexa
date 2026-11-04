import logging
import ssl
from typing import Generator
from sqlalchemy import create_engine, text
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from app.core.config import settings

logger = logging.getLogger(__name__)

# Determine active database engine (Aiven MySQL, PostgreSQL, or resilient SQLite fallback)
def init_engine():
    try:
        connect_args = {}
        db_url_lower = settings.DATABASE_URL.lower()

        if "mysql" in db_url_lower:
            connect_args["connect_timeout"] = 10
            # For cloud MySQL hosts (such as Aiven, AWS RDS, etc.) or when SSL is specified
            if any(k in db_url_lower for k in ["aivencloud", "rds", "azure", "ssl"]) or ("127.0.0.1" not in db_url_lower and "localhost" not in db_url_lower):
                ssl_ctx = ssl.create_default_context()
                ssl_ctx.check_hostname = False
                ssl_ctx.verify_mode = ssl.CERT_NONE
                connect_args["ssl"] = ssl_ctx
        elif "postgresql" in db_url_lower:
            connect_args["connect_timeout"] = 5

        prod_engine = create_engine(
            settings.DATABASE_URL,
            pool_pre_ping=True,
            pool_recycle=300,
            pool_size=10,
            max_overflow=20,
            echo=False,
            connect_args=connect_args
        )
        with prod_engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        logger.info(f"Connected to production database successfully ({prod_engine.dialect.name}).")
        return prod_engine
    except Exception as ex:
        logger.warning(
            f"Production database connection not active ({ex}). "
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
