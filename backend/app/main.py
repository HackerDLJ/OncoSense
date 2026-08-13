import os

from fastapi import FastAPI

from app.api.auth import router as auth_router
from app.database.base import Base
from app.database.postgres import engine
from app.models import MedicalReport, Patient, Prediction, User

if os.getenv("DATABASE_URL", "").startswith("sqlite"):
    Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="OncoSense API",
    version="1.0.0",
    description="AI-powered digital health intelligence platform for early cancer risk support.",
)

app.include_router(auth_router, prefix="/auth", tags=["Authentication"])


@app.get("/")
async def root() -> dict[str, str]:
    return {"message": "Welcome to OncoSense", "status": "Running"}


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "Healthy"}