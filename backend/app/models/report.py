from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.sql import func

from app.database.base import Base


class MedicalReport(Base):

    __tablename__ = "medical_reports"

    id = Column(Integer, primary_key=True)

    user_id = Column(Integer, ForeignKey("users.id"))

    report_url = Column(String(500))

    summary = Column(String(2000))

    created_at = Column(DateTime(timezone=True), server_default=func.now())