from sqlalchemy import Column, Integer, Float, String, DateTime, ForeignKey
from sqlalchemy.sql import func

from app.database.base import Base


class Prediction(Base):

    __tablename__ = "predictions"

    id = Column(Integer, primary_key=True)

    user_id = Column(Integer, ForeignKey("users.id"))

    cancer_type = Column(String(100))

    confidence = Column(Float)

    risk_level = Column(String(30))

    created_at = Column(DateTime(timezone=True), server_default=func.now())