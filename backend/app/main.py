from fastapi import FastAPI

from app.database.base import Base
from app.database.postgres import engine

# Import models so SQLAlchemy registers them
from app.models import User, Patient, Prediction, MedicalReport

# Import routers
from app.api.auth import router as auth_router

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="OncoSense API",
    version="1.0.0",
)

# Register routers
app.include_router(
    auth_router,
    prefix="/auth",
    tags=["Authentication"],
)

@app.get("/")
async def root():
    return {
        "message": "Welcome to OncoSense",
        "status": "Running"
    }

@app.get("/health")
async def health():
    return {
        "status": "Healthy"
    }