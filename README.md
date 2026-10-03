# 🧬 OncoSense

**OncoSense** is a personalized longitudinal health-monitoring platform built around Apple Watch + iPhone + HealthKit + WatchConnectivity. It is designed to make real physiological change understandable instead of reducing health data to a single unexplained number.

> ⚠️ **Medical safety:** OncoSense is a tracking, visualization, longitudinal-documentation, and communication-support system. It is **not** a cancer diagnosis, cancer-risk prediction, treatment recommendation, or replacement for established screening, diagnostic testing, or clinical care.

## Product scope

OncoSense is intentionally positioned around four things:

1. **Tracking** real health measurements that the user has authorized through Apple Health.
2. **Visualization** of those measurements in a clear, longitudinal view.
3. **Longitudinal documentation** of personal baselines, persistent changes, symptoms, and notes.
4. **Communication support** that helps a person prepare useful information for follow-up conversations with a qualified healthcare professional.

The product does **not** claim to:

- detect cancer;
- diagnose cancer or recurrence;
- predict a person's cancer risk;
- provide a probability that someone has cancer;
- recommend treatment or tell a clinician what treatment to give;
- replace established cancer screening or diagnostic tests.

The core product statement is:

> **OncoSense helps people understand their own longitudinal health patterns, notice persistent changes from their personal baseline, document context, and prepare better information for follow-up conversations.**

## Product experience

```text
First launch
    ↓
Guided setup
    ↓
HealthKit permissions
    ↓
Apple Watch connection
    ↓
Real health measurements
    ↓
Personal baseline
    ↓
Longitudinal trends
    ↓
Persistent-change view
    ↓
Explainable pattern context
    ↓
Care check-in + communication support
```

The core idea is **personalized change tracking**. OncoSense compares a person's recent measurements with their own history rather than turning a single population threshold into a diagnosis.

## Current Apple experience

### 📱 iPhone companion

- First-run walkthrough explaining the product before requesting health data.
- Real HealthKit measurements with explicit missing-data states.
- Ten supported signals: resting heart rate, heart rate, HRV, respiratory rate, sleeping wrist temperature, sleep duration, exercise time, steps, active energy, and weight when available.
- Data-coverage indicator so the user can see how much real information is available.
- Personal-pattern summary with contributors, data quality, and observed persistence.
- Longitudinal trend cards built from actual observations.
- Apple Watch connection screen with reachability, session, queued-transfer, and last-sync state.
- Local Care Check-in for fatigue, appetite, pain, fever, and free-text notes.
- Keyboard-safe Care entry with an explicit Done action and automatic dismissal after saving.
- Learn screen that explains the product scope and what the signals do and do not mean.
- Adaptive SwiftUI materials and accessible hierarchy.

### ⌚ Apple Watch

The Watch is deliberately glanceable rather than a miniature iPhone. It focuses on:

- Real HealthKit readings.
- Personal pattern state.
- Data coverage.
- iPhone reachability.
- Explicit Refresh & Sync action.
- Queued transfer state.
- Supported health signals when available.
- First-run Watch setup.

The Watch is a sensing and glanceable-context interface. It is not presented as a cancer diagnostic device.

## Real data, not demo numbers

The Apple layer reads from HealthKit only after the user grants permission. HealthKit is Apple's central repository for health and fitness data from iPhone, Apple Watch, and compatible sources.

The current reader covers these HealthKit types:

- Resting heart rate
- Heart rate
- Heart-rate variability (SDNN)
- Respiratory rate
- Sleeping wrist temperature
- Sleep analysis
- Exercise time
- Step count
- Active energy burned
- Body mass

HealthKit data availability depends on the device, OS version, source, region, and permissions granted by the user. HealthKit also intentionally does not tell an app whether a particular read permission was denied versus no readable data being available, so OncoSense represents unavailable measurements as **No data** rather than pretending to know why a value is missing.

## Watch ↔ iPhone sync

```text
⌚ Watch HealthKit
       ↓
HealthSnapshot
       ↓
WatchConnectivity
  ┌────┴─────────────┐
  │                  │
reachable       temporarily offline
  │                  │
context         queued userInfo
  │                  │
  └────────┬─────────┘
           ↓
      📱 iPhone history
```

OncoSense uses `updateApplicationContext` for the latest state and `transferUserInfo` for queued delivery. The iPhone UI exposes reachability and outstanding transfer state so synchronization is visible instead of being represented by a decorative icon.

## Why OncoSense is not a cancer-detection button

Cancer screening, diagnosis, and longitudinal health monitoring are different activities. An abnormal screening result generally requires additional clinical evaluation, while a wearable measurement is not by itself a diagnosis.

Wearable sensors are an active research area in health and cancer research, including longitudinal measures such as sleep, activity, heart rate, and temperature. Research opportunity is not the same as clinical validation.

Therefore, the current product does something narrower and more useful for a real-world prototype:

> **It makes persistent changes in a person's real physiological data easier to see, understand, document, and discuss with a clinician.**

A persistent change is a reason to pay attention to the trend and context, not proof of a particular disease.

## Research ML and backend scope

The repository contains research components for experimentation, including anomaly scoring and disease-dataset benchmarks. These components are **not presented as clinical models and are not used by the Apple app to diagnose cancer or produce a cancer probability for users**.

The backend remains available for research workflows such as:

- JWT authentication
- Patient records and prototype APIs
- Longitudinal baseline computation
- Multi-signal change scoring
- Explainable feature-level changes
- Persistence-aware attention levels
- SQLite local development + PostgreSQL configuration
- FastAPI OpenAPI documentation

Any disease-specific ML experiment must be treated as a separate research benchmark. It requires appropriate labeled data, external validation, calibration, subgroup analysis, privacy/security controls, regulatory review where applicable, and qualified clinical oversight before any clinical claim could be considered.

## Run the backend locally

```bash
cd backend
python -m venv .venv
source .venv/bin/activate       # Windows: .venv\\Scripts\\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Open `http://127.0.0.1:8000/docs` for the API documentation.

## Apple development

```bash
brew install xcodegen
cd OncoSense
git checkout main
git pull origin main
xcodegen generate
open OncoSense.xcodeproj
```

Select `OncoSense` for the iPhone and the paired `OncoSenseWatch` target for the Apple Watch. Enable HealthKit capabilities and use the repository's generated project configuration rather than manually editing the generated Xcode project.

For WatchConnectivity testing, install the iPhone application together with its embedded Watch companion on a paired physical iPhone + Apple Watch. Simulator-only testing is not sufficient for validating the complete real-device communication path.

## Research roadmap

1. Collect consented longitudinal wearable observations.
2. Improve daily/weekly aggregation and missing-data handling.
3. Evaluate change detection without disease labels first.
4. Select a narrowly defined research question and target population.
5. Train disease-specific models only on appropriate labeled datasets as a separate research track.
6. Evaluate sensitivity, specificity, AUROC/AUPRC, calibration, false-positive burden, subgroup performance, and temporal generalization.
7. Perform prospective validation before making clinical claims.
8. If clinical use is ever pursued, complete the appropriate regulatory, security, privacy, and clinical-validation pathway.

## The product philosophy

OncoSense is not trying to make a smartwatch pretend to be a CT scanner.

It is building a trustworthy longitudinal health companion: **real data in, personal context beside it, understandable trends out, and better information ready for the next healthcare conversation.**
