# 🧬 OncoSense

**OncoSense** is a personalized longitudinal health-monitoring platform built around Apple Watch + iPhone + HealthKit + WatchConnectivity. It is designed to make real physiological change understandable instead of reducing health data to a single unexplained number.

> ⚠️ **Medical safety:** OncoSense is a tracking, visualization, longitudinal-documentation, screening-support, and communication-support system. It is **not a cancer diagnosis, cancer-risk prediction, treatment recommendation, or replacement for established screening, diagnostic testing, or clinical care.**

## Product scope

OncoSense is intentionally positioned around five things:

1. **Tracking** real health measurements that the user has authorized through Apple Health.
2. **Visualization** of those measurements in a clear, longitudinal view.
3. **Longitudinal documentation** of personal baselines, persistent changes, symptoms, and notes.
4. **Screening support** that helps a person organize screening status and follow-up conversations without determining screening eligibility or diagnosing disease.
5. **Communication support** that helps a person prepare useful information for follow-up conversations with a qualified healthcare professional.

The product does **not** claim to:

- detect cancer from Apple Watch measurements;
- diagnose cancer or recurrence;
- predict a person's cancer risk;
- provide a probability that someone has cancer;
- recommend treatment or tell a clinician what treatment to give;
- replace established cancer screening or diagnostic tests.

The core product statement is:

> **OncoSense helps people understand their own longitudinal health patterns, notice persistent changes from their personal baseline, organize cancer-screening follow-up, document context, and prepare better information for healthcare conversations.**

## Product experience

```text
First launch
    ↓
Swipeable guided walkthrough
    ↓
HealthKit permissions
    ↓
Apple Watch connection
    ↓
Real health measurements
    ↓
Personal baseline
    ↓
Signals + interactive insights
    ↓
Longitudinal trends + interactive insights
    ↓
Cancer screening + care context
    ↓
Symptoms + appointment preparation
    ↓
Better information for follow-up conversations
```

The core idea is **personalized change tracking**. OncoSense compares a person's recent measurements with their own history rather than turning a single population threshold into a diagnosis.

## iPhone UX flows

### First-run walkthrough

The first launch uses a four-page swipeable walkthrough before health permissions are requested. It explains:

1. personal baseline;
2. real HealthKit signals;
3. the iPhone + Apple Watch relationship;
4. context and the product's non-diagnostic scope.

The user can swipe between pages or use Continue/Back controls. The final page starts HealthKit authorization and shows a progress state while setup is running. If authorization fails, the walkthrough remains available so the user can retry instead of being pushed into a broken or half-configured home screen.

### What to do next

The Overview screen has actionable next steps rather than decorative rows:

- **Check Watch connection** opens the live WatchConnectivity status screen.
- **Add today's context** switches directly to the Care tab.
- **Learn how to read your data** opens the Learn sheet with a clear Done action.

These actions are wired to real navigation state so tapping a row does not silently do nothing.

### Signals: tap for insight

Every supported signal in the Signals tab is interactive. Selecting a signal opens a dedicated insight view containing:

- latest real HealthKit value;
- personal average from recorded observations;
- recent history sparkline;
- observation count;
- direction of change when enough observations exist;
- plain-language explanation of what the measurement represents;
- guidance for interpreting the trend in context.

The insight view deliberately describes **the user's recorded data**, not a disease probability or diagnostic threshold. Missing values remain missing.

### Trends: tap the exact trend

Every trend card in the Trends tab is also interactive. Selecting a trend opens the same deeper signal-insight experience using the user's longitudinal history. The trend cards use a bounded set of recent observations to keep rendering responsive, while the detail view presents the full available recent history needed for the personal comparison.

The UI uses lightweight SwiftUI drawing for the sparklines rather than heavyweight chart rendering. Lists use native lazy rendering and the trend screen uses `LazyVStack` to keep scrolling responsive as the local history grows.

### Care: personalized cancer-care context

The Care section is more than a daily symptom form. It now combines personal care context, screening organization, symptom documentation, appointment preparation, and the existing daily check-in.

#### Care journey

The user can identify the context they are currently navigating:

- Screening
- Active treatment
- Follow-up
- Survivorship
- Supporting someone

This is user-entered context for organization and personalization. It does not alter or interpret a medical diagnosis.

#### Screening & early detection tracker

The Care section includes a simple status tracker for common screening pathways:

- Breast
- Cervical
- Colorectal
- Lung
- Other / clinician advised

Each pathway can be marked **Not tracked**, **Planned**, or **Completed**. This is intentionally a documentation and preparation tool. OncoSense does not decide that a person is eligible for screening, does not determine that screening is due, and does not interpret a screening result as cancer.

Cancer screening is a clinical pathway, not a smartwatch prediction. Screening abnormalities require appropriate follow-up and diagnostic evaluation. Eligibility and timing depend on factors such as age, risk, sex, local guidance, available services, and clinical history.

#### What I want to discuss

Users can quickly record changes they want to mention to a healthcare professional, including:

- new lump or swelling;
- unusual bleeding;
- persistent cough or voice change;
- bowel or bladder changes;
- unexplained weight change;
- persistent pain;
- persistent fatigue;
- another user-defined concern.

These selections are documentation prompts, not cancer predictions.

#### Appointment preparation

The user can save:

- the next appointment date and time;
- questions for the care team;
- a compact care snapshot showing screening items completed/planned, discussion topics, and questions prepared.

Questions and care context remain local to the device in the current implementation.

#### Daily check-in

The existing quick check-in remains available for:

- fatigue with a 0–5 scale;
- appetite with a 0–5 scale;
- pain with a 0–10 scale;
- fever/hot-feeling toggle;
- optional free-text context;
- recent check-in timeline.

The interface uses quick-tap scales instead of forcing repeated Stepper interactions. After saving, the entry is stored locally, the form resets to a clean state, and a brief confirmation appears. Text entry supports Return/Done submission, explicit keyboard dismissal, interactive keyboard dismissal, and automatic keyboard dismissal after saving.

Care entries are shown beside the user's wearable context conceptually, but they are not converted into a diagnosis. The purpose is to preserve context around a physiological change, organize screening follow-up, and make healthcare conversations easier.

## Current Apple experience

### 📱 iPhone companion

- First-run walkthrough explaining the product before requesting health data.
- Real HealthKit measurements with explicit missing-data states.
- Ten supported signals: resting heart rate, heart rate, HRV, respiratory rate, sleeping wrist temperature, sleep duration, exercise time, steps, active energy, and weight when available.
- Data-coverage indicator so the user can see how much real information is available.
- Personal-pattern summary with contributors, data quality, and observed persistence.
- Interactive signal insight screens for individual measurements.
- Interactive trend cards with longitudinal detail views.
- Apple Watch connection screen with reachability, session, queued-transfer, and last-sync state.
- Personalized cancer-care context and screening tracker.
- Symptom/discussion documentation for follow-up conversations.
- Appointment preparation and question list.
- Personalized local Care Check-in for fatigue, appetite, pain, fever, and free-text notes.
- Keyboard-safe Care entry with explicit Done and automatic dismissal after submit/save.
- Learn screen that explains the product scope and what the signals do and do not mean.
- Actionable Overview next steps connected to the Watch sheet, Care tab, and Learn sheet.
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

**Important:** `isReachable` means an immediate WatchConnectivity communication path is available. It is **not** the same thing as “paired,” and it is not required for queued `transferUserInfo` or application-context synchronization. The app therefore keeps these states separate instead of showing a false “connected” status.

### Physical-device pairing checklist

For a real iPhone + Apple Watch test, do this in order:

1. Pair the Apple Watch with the iPhone in the normal Apple Watch setup flow.
2. Turn **Bluetooth and Wi-Fi on** on both devices.
3. Keep the devices near each other and unlocked during the first installation.
4. In Xcode, install/run the **OncoSenseWatch** target on the physical Apple Watch at least once.
5. Install/run the **OncoSense** iPhone target on the paired iPhone.
6. Launch both apps once. Allow HealthKit permissions when prompted.
7. Return to OncoSense's Watch connection screen and wait for the WatchConnectivity session to activate.
8. Test **Refresh & Sync**. A queued request can work without immediate reachability, so a temporary `Not reachable` state should not be treated as a data-loss error.

If Xcode reports `RemotePairingError` / `Timed out while attempting to establish tunnel`, that is a **physical-device/Xcode transport problem**, not a SwiftUI connection-state problem. Reconnect the iPhone to the Mac with a cable, make sure the iPhone and Watch are both reachable, keep Wi-Fi enabled, unlock the devices, and re-pair the development device in Xcode before testing WatchConnectivity again.

If the Watch screen says **“counterpart app not installed”**, install the iPhone companion and Watch target on the same paired device set. The code cannot programmatically install the missing companion app.

## CI and build verification

The repository uses GitHub Actions to verify both sides of the product:

- backend Python compilation, tests, and application import;
- watchOS Simulator build;
- iOS Simulator build.

The iOS CI build intentionally does **not** force an iPhone Simulator SDK onto the Watch target. Doing that makes Xcode compile the watch target as an iOS target and produces misleading errors such as unavailable WatchConnectivity APIs and incorrect `TARGETED_DEVICE_FAMILY` warnings. The build uses the destination to let each target retain its own platform SDK.

The generated Xcode project is disposable. Run `xcodegen generate` after pulling changes instead of treating `OncoSense.xcodeproj` as the source of truth.

## Why OncoSense is not a cancer-detection button

Cancer screening, diagnosis, early diagnosis, and longitudinal health monitoring are different activities. Screening aims to identify findings suggestive of a specific cancer or pre-cancer in an appropriate target population; an abnormal screening result generally requires further diagnostic evaluation. A wearable measurement is not by itself a cancer diagnosis.

Wearable sensors are an active research area in health and cancer research, including longitudinal measures such as sleep, activity, heart rate, and temperature. Research opportunity is not the same as clinical validation.

Therefore, the current product does something narrower and safer for a real-world prototype:

> **It makes persistent changes in a person's real physiological data easier to see, understand, document, organize alongside screening follow-up, and discuss with a clinician.**

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

It is building a trustworthy longitudinal health companion: **real data in, personal context beside it, screening follow-up organized clearly, understandable trends out, and better information ready for the next healthcare conversation.**
