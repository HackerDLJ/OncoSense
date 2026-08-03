from sqlalchemy import Column, Integer, Float, String, DateTime, ForeignKey
from sqlalchemy.sql import func

from app.database.base import Base


class Patient(Base):

    __tablename__ = "patients"

    id = Column(Integer, primary_key=True)

    user_id = Column(Integer, ForeignKey("users.id"))

    age = Column(Integer)

    gender = Column(String(20))

    weight = Column(Float)

    height = Column(Float)

    blood_group = Column(String(10))

    created_at = Column(DateTime(timezone=True), server_default=func.now())