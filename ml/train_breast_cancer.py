"""Train an auditable breast-cancer classification baseline.

Dataset: sklearn's copy of the Wisconsin Diagnostic Breast Cancer dataset.
This model is a research benchmark for the ML stack only. It is NOT a wearable
model and must not be interpreted as a clinical cancer diagnosis system.

Run:
    python ml/train_breast_cancer.py
"""
from __future__ import annotations

import json
from pathlib import Path

from sklearn.datasets import load_breast_cancer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, roc_auc_score
from sklearn.model_selection import StratifiedKFold, cross_val_score, train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

ROOT = Path(__file__).resolve().parents[1]
ARTIFACT = ROOT / "ml" / "artifacts" / "breast_cancer_logreg.json"


def main() -> None:
    X, y = load_breast_cancer(return_X_y=True, as_frame=True)
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, stratify=y, random_state=42
    )

    model = Pipeline(
        [
            ("scaler", StandardScaler()),
            ("classifier", LogisticRegression(max_iter=5000, C=1.0)),
        ]
    )
    model.fit(X_train, y_train)

    probability = model.predict_proba(X_test)[:, 1]
    prediction = model.predict(X_test)
    cv = cross_val_score(
        model,
        X,
        y,
        cv=StratifiedKFold(n_splits=5, shuffle=True, random_state=42),
        scoring="roc_auc",
    )

    scaler = model.named_steps["scaler"]
    classifier = model.named_steps["classifier"]
    artifact = {
        "model": "standardized_logistic_regression",
        "dataset": "Wisconsin Diagnostic Breast Cancer (sklearn/UCI-derived)",
        "target_mapping": {"0": "malignant", "1": "benign"},
        "feature_names": list(X.columns),
        "mean": scaler.mean_.tolist(),
        "scale": scaler.scale_.tolist(),
        "coef": classifier.coef_[0].tolist(),
        "intercept": float(classifier.intercept_[0]),
        "classes": classifier.classes_.tolist(),
        "test_size": 0.20,
        "random_state": 42,
        "metrics": {
            "test_accuracy": float(accuracy_score(y_test, prediction)),
            "test_roc_auc": float(roc_auc_score(y_test, probability)),
            "cv5_roc_auc_mean": float(cv.mean()),
            "cv5_roc_auc_std": float(cv.std()),
            "confusion_matrix": confusion_matrix(y_test, prediction).tolist(),
            "classification_report": classification_report(
                y_test, prediction, output_dict=True
            ),
        },
        "limitations": [
            "This dataset contains tumor-cell morphology measurements, not Apple Watch signals.",
            "The benchmark therefore cannot validate cancer detection from wearable data.",
            "Clinical deployment requires prospective external validation and regulatory review.",
        ],
    }

    ARTIFACT.parent.mkdir(parents=True, exist_ok=True)
    ARTIFACT.write_text(json.dumps(artifact, indent=2), encoding="utf-8")
    print(json.dumps(artifact["metrics"], indent=2))
    print(f"Saved model artifact to {ARTIFACT}")


if __name__ == "__main__":
    main()
