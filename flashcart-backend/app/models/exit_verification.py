from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, DateTime, Text
from app.core.database import Base


class ExitVerificationLog(Base):
    __tablename__ = "exit_verifications"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    order_id = Column(String(64), index=True, nullable=False)
    staff_id = Column(String(64), index=True, nullable=False)
    verified_at = Column(
        DateTime, 
        default=lambda: datetime.now(timezone.utc), 
        nullable=False
    )
    result = Column(String(32), nullable=False)  # SUCCESS, ALREADY_VERIFIED, UNPAID, NOT_FOUND
    notes = Column(Text, nullable=True)
