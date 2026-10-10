import logging
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from app.core.config import settings

logger = logging.getLogger(__name__)

# Base class for SQLAlchemy 2.0 models
Base = declarative_base()

def get_engine():
    """
    Creates the SQLAlchemy engine.
    Attempts primary DATABASE_URL (MySQL 8). If unreachable and fallback is allowed,
    falls back to SQLite for effortless local dev & test running.
    """
    try:
        # Check if URL is MySQL
        if settings.DATABASE_URL.startswith("mysql"):
            engine = create_engine(
                settings.DATABASE_URL,
                pool_pre_ping=True,
                pool_recycle=3600,
                echo=False,
            )
            # Try a lightweight ping connection test
            with engine.connect() as conn:
                logger.info(f"Connected successfully to MySQL at {settings.DATABASE_URL.split('@')[-1]}")
            return engine
    except Exception as e:
        logger.warning(
            f"Could not connect to MySQL ({e}). "
            f"Falling back to local SQLite database: {settings.SQLITE_URL}"
        )
        if settings.USE_SQLITE_FALLBACK:
            return create_engine(
                settings.SQLITE_URL,
                connect_args={"check_same_thread": False},
                echo=False,
            )
        raise

    # Default / SQLite engine
    connect_args = {"check_same_thread": False} if "sqlite" in settings.DATABASE_URL else {}
    return create_engine(settings.DATABASE_URL, connect_args=connect_args)


engine = get_engine()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db():
    """FastAPI Dependency for database session injection."""
    db: Session = SessionLocal()
    try:
        yield db
    finally:
        db.close()
