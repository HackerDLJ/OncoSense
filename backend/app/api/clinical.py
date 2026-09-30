from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.api.auth import get_current_user
from app.database.postgres import get_db
from app.models.patient import Patient
from app.models.prediction import Prediction
from app.models.report import MedicalReport
from app.models.user import User

router = APIRouter()


class PatientCreate(BaseModel):
    age: int = Field(ge=0, le=120)
    gender: str = Field(min_length=1, max_length=20)
    weight: float = Field(gt=0, le=500)
    height: float = Field(gt=0, le=300)
    blood_group: str = Field(min_length=1, max_length=10)


class RiskRequest(BaseModel):
    age: int = Field(ge=0, le=120)
    bmi: float = Field(gt=5, lt=80)
    smoking: bool = False
    family_history: bool = False
    persistent_symptoms: bool = False


class ReportRequest(BaseModel):
    text: str = Field(min_length=1, max_length=10000)


def _risk_score(data: RiskRequest) -> dict[str, Any]:
    """Transparent demo heuristic, not a clinical prediction model."""
    score = 0
    reasons: list[str] = []

    if data.age >= 60:
        score += 2
        reasons.append("Age is 60 or above")
    elif data.age >= 45:
        score += 1
        reasons.append("Age is 45 or above")

    if data.bmi >= 30:
        score += 1
        reasons.append("BMI is in the obesity range")
    if data.smoking:
        score += 2
        reasons.append("Smoking history reported")
    if data.family_history:
        score += 2
        reasons.append("Family history reported")
    if data.persistent_symptoms:
        score += 2
        reasons.append("Persistent symptoms reported")

    if score <= 2:
        level = "lower signal"
    elif score <= 5:
        level = "moderate signal"
    else:
        level = "higher signal"

    confidence = min(0.95, 0.55 + score * 0.05)
    return {
        "risk_score": score,
        "risk_level": level,
        "confidence": round(confidence, 2),
        "reasons": reasons,
        "method": "transparent_demo_heuristic",
        "clinical_use": False,
        "disclaimer": "This is a software demonstration signal, not a cancer diagnosis or medical advice. Clinical decisions require qualified medical professionals and validated models.",
    }


@router.post("/patients")
def create_patient(
    payload: PatientCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict[str, Any]:
    patient = Patient(user_id=current_user.id, **payload.model_dump())
    db.add(patient)
    db.commit()
    db.refresh(patient)
    return {"id": patient.id, **payload.model_dump()}


@router.get("/patients")
def list_patients(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[dict[str, Any]]:
    rows = db.query(Patient).filter(Patient.user_id == current_user.id).order_by(Patient.created_at.desc()).all()
    return [
        {"id": p.id, "age": p.age, "gender": p.gender, "weight": p.weight, "height": p.height, "blood_group": p.blood_group}
        for p in rows
    ]


@router.post("/risk-assessment")
def risk_assessment(
    payload: RiskRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict[str, Any]:
    result = _risk_score(payload)
    prediction = Prediction(
        user_id=current_user.id,
        cancer_type="unspecified",
        confidence=result["confidence"],
        risk_level=result["risk_level"],
    )
    db.add(prediction)
    db.commit()
    result["prediction_id"] = prediction.id
    return result


@router.post("/report-summary")
def report_summary(
    payload: ReportRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict[str, Any]:
    text = " ".join(payload.text.split())
    lowered = text.lower()
    keywords = {
        "imaging": ["ct", "mri", "pet", "x-ray", "ultrasound", "scan"],
        "pathology": ["biopsy", "histology", "pathology", "tumor", "malignant", "benign"],
        "symptoms": ["pain", "bleeding", "weight loss", "fatigue", "lump", "cough"],
    }
    detected = {group: [word for word in words if word in lowered] for group, words in keywords.items()}
    detected = {k: v for k, v in detected.items() if v}
    summary = (
        "Report received. The prototype detected the following topic keywords: "
        + (", ".join(f"{k} ({', '.join(v)})" for k, v in detected.items()) if detected else "no supported keywords")
        + ". This parser does not interpret medical findings."
    )
    report = MedicalReport(user_id=current_user.id, report_url="local-text", summary=summary)
    db.add(report)
    db.commit()
    return {
        "report_id": report.id,
        "summary": summary,
        "detected_topics": detected,
        "disclaimer": "Automated text parsing is informational only and must not be used to diagnose cancer.",
    }


@router.get("/dashboard")
def dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict[str, Any]:
    patients = db.query(Patient).filter(Patient.user_id == current_user.id).count()
    predictions = db.query(Prediction).filter(Prediction.user_id == current_user.id).count()
    reports = db.query(MedicalReport).filter(MedicalReport.user_id == current_user.id).count()
    return {"patients": patients, "assessments": predictions, "reports": reports}
