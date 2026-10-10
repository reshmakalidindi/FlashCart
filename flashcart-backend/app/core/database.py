import logging
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from app.core.config import settings

logger = logging.getLogger(__name__)

# Declarative Base class for SQLAlchemy 2.0 models
Base = declarative_base()


def get_engine(db_url: str = None):
    """
    Creates and configures the single primary MySQL SQLAlchemy engine.
    Automatic SQLite fallback is completely removed.
    Enforces MySQL 8 connection pooling, health pre-pinging, and auto-recycle.
    """
    url = db_url or settings.sqlalchemy_database_url

    if not url.startswith("mysql"):
        raise RuntimeError(
            f"FlashCart is strictly configured to use MySQL as the primary database. "
            f"Invalid connection protocol: {url.split('://')[0]}. Automatic SQLite fallback is disabled."
        )

    engine = create_engine(
        url,
        pool_pre_ping=True,      # Tests connection liveness before checking out from pool
        pool_recycle=3600,       # Recycles connections every hour to avoid MySQL timeout
        pool_size=10,            # Steady-state connection pool size
        max_overflow=20,         # Maximum extra connections for peak shopping traffic
        echo=False,
    )
    return engine


engine = get_engine()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db():
    """FastAPI Dependency for database session injection."""
    db: Session = SessionLocal()
    try:
        yield db
    finally:
        db.close()
