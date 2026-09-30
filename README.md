# 🧬 OncoSense

**OncoSense** is evolving into a personalized longitudinal health-intelligence research platform built around Apple Watch + iPhone + AI. Instead of claiming that a wearable can directly diagnose cancer, OncoSense learns a person's physiological baseline and looks for persistent multi-signal changes that may warrant medical evaluation.

> ⚠️ **Medical safety:** OncoSense is a research/demo prototype. Its outputs are not a cancer diagnosis, cancer screening result, cancer stage, treatment recommendation, or medical advice. Do not use it for clinical decisions. Any disease-specific model requires appropriate data, rigorous validation, privacy/security controls, regulatory review, and qualified healthcare oversight.

## Product concept

```text
Apple Watch / Apple Health
          ↓
Personal physiological baseline
          ↓
Longitudinal feature extraction
          ↓
Multi-signal anomaly detection
          ↓
Persistence analysis
          ↓
Explainable Change Signature
          ↓
iPhone dashboard
          ↓
Optional clinician discussion
```

The key research idea is **personalized change detection** rather than a generic "cancer = yes/no" classifier. A single abnormal measurement should not trigger a strong signal; persistent changes across multiple independent physiological dimensions are treated as more informative research signals.

## Current capabilities

### Backend

- 🔐 JWT authentication
- 👤 Patient records and clinical prototype APIs
- 📊 Dashboard/clinical endpoints
- 🧠 Personalized longitudinal baseline engine
- 📈 Multi-signal anomaly scoring
- 🔎 Explainable feature-level changes
- ⏳ Persistence-aware attention levels
- 🗄️ SQLite local development + PostgreSQL configuration
- 🌐 FastAPI OpenAPI documentation

### Apple Watch research layer

Swift source is provided under `watchOS/OncoSenseWatch/` for an Apple Watch target. The prototype includes:

- HealthKit authorization manager
- Resting heart-rate access
- HRV access
- Respiratory-rate access
- Activity/exercise signals
- Sleeping wrist-temperature access where supported
- Oxygen-saturation access where supported
- Baseline/monitoring Watch UI
- Change Signature UI

Actual HealthKit availability depends on the Apple Watch model, watchOS/iOS versions, region, and user permissions.

## Architecture

```text
                  ┌────────────────────┐
                  │    Apple Watch     │
                  │ HealthKit / sensors │
                  └─────────┬──────────┘
                            ↓
                  ┌────────────────────┐
                  │ Personal Baseline  │
                  └─────────┬──────────┘
                            ↓
                  ┌────────────────────┐
                  │ Longitudinal Engine │
                  └─────────┬──────────┘
                            ↓
                  ┌────────────────────┐
                  │ Change Signature   │
                  └─────────┬──────────┘
                            ↓
                  ┌────────────────────┐
                  │ iPhone Companion   │
                  └─────────┬──────────┘
                            ↓
                  ┌────────────────────┐
                  │ Research Backend   │
                  └─────────┬──────────┘
                            ↓
                  ┌────────────────────┐
                  │ ML / Validation    │
                  └────────────────────┘
```

## Run the backend locally

```bash
cd backend
python -m venv .venv
source .venv/bin/activate       # Windows: .venv\\Scripts\\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Open `http://127.0.0.1:8000/docs` for the API documentation.

The new longitudinal endpoint is:

```text
POST /api/longitudinal/analyze
```

## Apple Watch development

Open the repository in Xcode and create an iOS companion + watchOS app target. Add the Swift files under `watchOS/OncoSenseWatch/`, enable the HealthKit capability, add the required HealthKit usage descriptions, and use WatchConnectivity for transferring summarized observations to the iPhone.

See [`docs/APPLE_WATCH_BUILD.md`](docs/APPLE_WATCH_BUILD.md) for the research architecture and setup notes.

## Research roadmap

1. Collect consented longitudinal wearable observations.
2. Build reproducible preprocessing and missing-data handling.
3. Evaluate anomaly detection without disease labels first.
4. Select one cancer-specific research question and target population.
5. Train disease-specific models only on appropriate labeled datasets.
6. Evaluate sensitivity, specificity, AUROC/AUPRC, calibration, false-positive burden, subgroup performance, and temporal generalization.
7. Perform prospective validation before making clinical claims.

**OncoSense's goal is not to make a smartwatch pretend to be a CT scanner. The goal is to investigate whether a person's own longitudinal physiological data can reveal meaningful early changes that deserve a closer look.**
