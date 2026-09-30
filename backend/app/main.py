from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.auth import router as auth_router
from app.api.clinical import router as clinical_router
from app.api.longitudinal import router as longitudinal_router
from app.database.base import Base
from app.database.postgres import engine
from app.models import MedicalReport, Patient, Prediction, User

# Creates the schema automatically for the zero-config local SQLite demo.
# Production deployments should use migrations and PostgreSQL.
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="OncoSense API",
    version="2.0.0",
    description="Personalized longitudinal health-anomaly research platform. Outputs are research/demo signals and are not diagnoses.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/auth", tags=["Authentication"])
app.include_router(clinical_router, prefix="/api", tags=["Clinical"])
app.include_router(longitudinal_router, prefix="/api")


@app.get("/")
async def root() -> dict[str, str]:
    return {
        "message": "Welcome to OncoSense",
        "status": "Running",
        "mode": "personalized longitudinal research prototype",
    }


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "Healthy"}


frontend_dir = Path(__file__).resolve().parents[2] / "frontend"
if frontend_dir.exists():
    app.mount("/app", StaticFiles(directory=frontend_dir, html=True), name="frontend")
