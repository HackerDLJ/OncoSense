# 🧬 OncoSense

**OncoSense** is a runnable clinical-support prototype for oncology workflows. The repository now includes a FastAPI backend, authentication, patient records, transparent risk-support assessment, report keyword extraction, persistence, and a browser dashboard.

> ⚠️ **Medical safety:** OncoSense is a research/demo prototype. Its outputs are not a cancer diagnosis, screening result, treatment recommendation, or medical advice. Do not use it for clinical decisions. A production medical system requires validated datasets/models, clinical validation, security/privacy controls, regulatory review, and qualified healthcare oversight.

## Current capabilities

- 🔐 Register/login with JWT access and refresh tokens
- 👤 Create and list patient profiles
- 📊 Dashboard counters for patients, assessments, and reports
- 🧮 Transparent risk-support heuristic with visible contributing factors
- 📄 De-identified report-text keyword extraction
- 🗄️ Zero-config SQLite local development
- 🐘 PostgreSQL configuration for production-style deployments
- 🌐 Browser dashboard served by FastAPI at `/app/`
- 🩺 OpenAPI documentation at `/docs`

## Architecture

```text
Browser dashboard
      │
      ▼
FastAPI API
 ┌────┴──────────────┐
 │                   │
Auth             Clinical API
 │                   ├── Patients
JWT                 ├── Risk support
 │                   └── Report parser
 ▼                   ▼
SQLite/PostgreSQL  SQLAlchemy models
```

## Run locally

```bash
cd backend
python -m venv .venv
source .venv/bin/activate       # Windows: .venv\\Scripts\\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Open:

- `http://127.0.0.1:8000/app/` → dashboard
- `http://127.0.0.1:8000/docs` → API documentation
- `http://127.0.0.1:8000/health` → health check

SQLite is the default, so PostgreSQL is not required for the local demo. Set `DATABASE_URL` to a PostgreSQL connection string when deploying.

## What is intentionally not claimed

The current risk endpoint is a **transparent software demonstration heuristic**, not a trained cancer-prediction model. It must not be represented as clinically accurate. The next research stage should replace the heuristic with a properly trained and independently validated model using an appropriate, legally usable dataset and clinically meaningful evaluation protocol.
