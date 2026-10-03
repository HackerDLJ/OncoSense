"""Inference for the research breast-cancer benchmark artifact."""
from __future__ import annotations

import json
from pathlib import Path
from math import exp

ROOT = Path(__file__).resolve().parents[1]
ARTIFACT = ROOT / "ml" / "artifacts" / "breast_cancer_logreg.json"


def _sigmoid(x: float) -> float:
    if x >= 0:
        z = exp(-x)
        return 1.0 / (1.0 + z)
    z = exp(x)
    return z / (1.0 + z)


def predict(features: dict[str, float]) -> dict[str, object]:
    artifact = json.loads(ARTIFACT.read_text(encoding="utf-8"))
    names = artifact["feature_names"]
    missing = [name for name in names if name not in features]
    if missing:
        raise ValueError(f"Missing features: {missing}")

    score = float(artifact["intercept"])
    for i, name in enumerate(names):
        value = (float(features[name]) - artifact["mean"][i]) / artifact["scale"][i]
        score += value * artifact["coef"][i]

    benign_probability = _sigmoid(score)
    malignant_probability = 1.0 - benign_probability
    return {
        "model": artifact["model"],
        "malignant_probability": round(malignant_probability, 4),
        "benign_probability": round(benign_probability, 4),
        "research_label": "malignant-signal" if malignant_probability >= 0.5 else "benign-signal",
        "clinical_use": False,
        "note": "Research benchmark only. These features are tumor morphology measurements and cannot be collected by Apple Watch.",
    }
