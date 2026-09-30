# OncoSense Apple Watch Research Build

## Product direction

OncoSense is being developed as a **personalized longitudinal physiological-change research platform**. The Apple Watch is a sensing interface; it is not treated as a cancer diagnostic device.

### Signal pipeline

```text
Apple Watch / Apple Health
        -> authorized health signals
        -> personal baseline
        -> longitudinal feature extraction
        -> multi-signal anomaly detection
        -> persistent-change analysis
        -> iPhone explanation
        -> optional clinician discussion
```

## Current research signals

- Resting heart rate
- Heart-rate variability (SDNN)
- Respiratory rate
- Sleep duration
- Exercise/activity time
- Sleeping wrist temperature where supported
- Oxygen saturation where supported

Availability depends on Apple Watch hardware, watchOS/iOS versions, region, and user authorization.

## What the current prototype does

1. Builds a personal baseline from historical observations.
2. Compares a current observation with that baseline.
3. Calculates standardized and percentage changes.
4. Detects multi-signal deviations.
5. Adds a persistence condition so a single noisy measurement does not automatically create a high-attention signal.
6. Produces an explainable list of the strongest changing features.

## What it does NOT do

It does not diagnose, rule out, stage, or predict cancer for an individual. The anomaly score is a research/demo signal. Any cancer-specific model must be trained and externally validated on appropriate datasets before clinical use.

## Apple project setup

The repository contains Swift source for a watchOS target under `watchOS/OncoSenseWatch/`.

Create an Xcode workspace with:

- watchOS App target: `OncoSenseWatch`
- iOS companion target: `OncoSense`
- HealthKit capability enabled on both targets as required
- HealthKit usage descriptions in the relevant Info.plist
- WatchConnectivity for watch-to-iPhone transfer

The backend remains useful for research data ingestion and server-side experiments, while production health data should be minimized, encrypted, and handled according to applicable privacy and medical-device requirements.

## Research roadmap

1. Collect consented longitudinal wearable data.
2. Establish reproducible preprocessing and missing-data handling.
3. Evaluate anomaly detection without cancer labels first.
4. Define one cancer-specific research question and target population.
5. Train disease-specific models only with clinically appropriate labeled data.
6. Evaluate sensitivity, specificity, AUROC/AUPRC, calibration, false-positive burden, subgroup performance, and temporal generalization.
7. Conduct prospective validation before making clinical claims.
