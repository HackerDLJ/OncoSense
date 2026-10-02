"""Train a research-only wearable cancer-signal model on a synthetic demo dataset.

This is deliberately NOT presented as clinical evidence. The synthetic generator
exists so the complete Watch -> feature engineering -> ML -> inference pipeline
can be developed and tested before a properly consented longitudinal wearable
cancer dataset is obtained.
"""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import classification_report, roc_auc_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

ROOT = Path(__file__).resolve().parents[2]
ARTIFACT = ROOT / "ml" / "artifacts" / "wearable_signal_demo.json"
FEATURES = [
    "resting_hr_delta_pct",
    "hrv_delta_pct",
    "respiratory_rate_delta_pct",
    "temperature_delta_c",
    "sleep_delta_pct",
    "activity_delta_pct",
    "persistence_days",
]


def make_demo_data(n: int = 5000, seed: int = 42):
    rng = np.random.default_rng(seed)
    x = rng.normal(0, 1, size=(n, len(FEATURES)))
    x[:, 0] = rng.normal(0, 10, n)
    x[:, 1] = rng.normal(0, 15, n)
    x[:, 2] = rng.normal(0, 8, n)
    x[:, 3] = rng.normal(0, 0.25, n)
    x[:, 4] = rng.normal(0, 15, n)
    x[:, 5] = rng.normal(0, 20, n)
    x[:, 6] = rng.uniform(1, 45, n)

    # Synthetic research label only: persistent, multi-signal change.
    signal = (
        0.035 * x[:, 0]
        - 0.025 * x[:, 1]
        + 0.035 * x[:, 2]
        + 0.8 * x[:, 3]
        - 0.025 * x[:, 4]
        - 0.02 * x[:, 5]
        + 0.035 * x[:, 6]
        + rng.normal(0, 0.8, n)
    )
    y = (signal > 1.15).astype(int)
    return x, y


def main() -> None:
    X, y = make_demo_data()
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, stratify=y, random_state=42
    )
    model = Pipeline([
        ("scaler", StandardScaler()),
        ("classifier", HistGradientBoostingClassifier(
            max_iter=150, learning_rate=0.08, max_leaf_nodes=15, random_state=42
        )),
    ])
    model.fit(X_train, y_train)
    probability = model.predict_proba(X_test)[:, 1]
    prediction = (probability >= 0.5).astype(int)
    metrics = {
        "demo_roc_auc": float(roc_auc_score(y_test, probability)),
        "classification_report": classification_report(y_test, prediction, output_dict=True),
        "samples": int(len(y)),
        "positive_rate": float(y.mean()),
    }
    ARTIFACT.parent.mkdir(parents=True, exist_ok=True)
    ARTIFACT.write_text(json.dumps({
        "model": "hist_gradient_boosting",
        "feature_names": FEATURES,
        "metrics": metrics,
        "status": "synthetic_pipeline_demo_only",
        "warning": "This model must not be used for medical decisions. Replace synthetic labels with a validated longitudinal wearable cancer dataset before any disease claim.",
    }, indent=2), encoding="utf-8")
    print(json.dumps(metrics, indent=2))


if __name__ == "__main__":
    main()
