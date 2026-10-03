# 🧬 OncoSense

**OncoSense** is a personalized longitudinal health-monitoring research platform built around Apple Watch + iPhone + HealthKit + WatchConnectivity. It is designed to make physiological change understandable instead of reducing health data to a single unexplained number.

> ⚠️ **Medical safety:** OncoSense is a research monitoring system, not a cancer diagnosis or a replacement for established cancer screening, diagnostic testing, or clinical care. A wearable pattern can have many causes. Disease-specific claims require appropriate labeled data, external validation, calibration, privacy/security controls, regulatory review, and qualified healthcare oversight.

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
Persistent-change analysis
    ↓
Explainable pattern view
    ↓
Care check-in + clinician conversation context
```

The core idea is **personalized change detection**. OncoSense compares a person's recent measurements with their own history rather than treating a single population threshold as a diagnosis.

## Current Apple experience

### 📱 iPhone companion

- First-run walkthrough explaining the app before asking for data.
- Real HealthKit measurements with explicit missing-data states.
- Ten supported signals: resting heart rate, heart rate, HRV, respiratory rate, sleeping wrist temperature, sleep duration, exercise time, steps, active energy, and weight when available.
- Data-coverage indicator so the user can see exactly how much information is available.
- Personal-pattern summary with contributors, data quality, and observed persistence.
- Longitudinal trend cards with real observations.
- Apple Watch connection screen with reachability, session, queued-transfer, and last-sync state.
- Local Care Check-in for fatigue, appetite, pain, fever, and free-text notes.
- Learn screen explaining what the system does and does not mean.
- Light/dark adaptive SwiftUI materials and accessible hierarchy.

### ⌚ Apple Watch

The Watch is deliberately glanceable rather than a miniature iPhone. It focuses on:

- Real HealthKit readings.
- Personal pattern state.
- Data coverage.
- iPhone reachability.
- Explicit Refresh & Sync action.
- Queued transfer count.
- Ten supported health signals when available.
- First-run Watch setup.

Apple's watchOS guidance emphasizes focused, glanceable experiences and shallow navigation, which is why the Watch UI is intentionally compact. citeturn3search0turn3search5

## Real data, not demo numbers

The Apple layer reads from HealthKit only after the user grants permission. HealthKit is Apple's central repository for health and fitness data from iPhone, Apple Watch, and compatible sources. citeturn0search1turn0search7

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

HealthKit data availability depends on the device, OS version, source, region, and the permissions granted by the user. HealthKit also intentionally does not tell an app whether a particular read permission was denied versus no readable data being available, so OncoSense represents unavailable measurements as **No data** rather than pretending to know why the value is missing. citeturn0search8

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

OncoSense uses `updateApplicationContext` for the latest state and `transferUserInfo` for queued delivery. The iPhone UI exposes reachability and outstanding transfer state so synchronization is visible instead of being a silent icon.

## Why the app is not a "cancer = yes/no" button

Cancer screening and diagnosis are not interchangeable. The National Cancer Institute notes that screening tests are designed to find certain cancers early and that abnormal screening results generally require additional testing; screening itself is not diagnosis. citeturn0search2turn0search6

Wearable sensors are an active research area in cancer research, including longitudinal measures of sleep, activity, heart rate, temperature, and other physiological signals, but research opportunity is not the same thing as clinical validation. citeturn0search17

Therefore, the current product goal is narrower and technically honest:

> **Make persistent changes in a person's real physiological data easier to see, understand, document, and discuss with a clinician.**

## Research backend

The backend remains available for research workflows:

- JWT authentication
- Patient records and clinical prototype APIs
- Longitudinal baseline engine
- Multi-signal anomaly scoring
- Explainable feature-level changes
- Persistence-aware attention levels
- SQLite local development + PostgreSQL configuration
- FastAPI OpenAPI documentation

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

Select `OncoSense` for the iPhone and `OncoSenseWatch` for the paired Apple Watch. Enable HealthKit capabilities and use the repository's generated project configuration rather than manually editing the generated Xcode project.

## Research roadmap

1. Collect consented longitudinal wearable observations.
2. Add robust daily/weekly aggregation and missing-data handling.
3. Evaluate anomaly detection without disease labels first.
4. Select one cancer-specific research question and target population.
5. Train disease-specific models only on appropriate labeled datasets.
6. Evaluate sensitivity, specificity, AUROC/AUPRC, calibration, false-positive burden, subgroup performance, and temporal generalization.
7. Perform prospective validation before making clinical claims.

**OncoSense is not trying to make a smartwatch pretend to be a CT scanner. It is building the longitudinal data and user experience needed to investigate whether personal physiological change can become a useful early signal for further medical attention.**
