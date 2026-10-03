# Wearable cancer-signal research model

This module is the bridge between OncoSense's Apple Watch feature pipeline and a future validated cancer model.

## Current status

`train_wearable_demo.py` trains on **synthetic data**. It is a software/integration test, not a medical model and not evidence that Apple Watch data can diagnose cancer.

The model features are designed around the signals the product can potentially receive from HealthKit:

- resting heart-rate change
- HRV change
- respiratory-rate change
- temperature change
- sleep change
- activity change
- persistence duration

## Why synthetic data first?

The public breast-cancer benchmark in `ml/train_breast_cancer.py` uses tumor morphology features, which cannot be fed by an Apple Watch. A real wearable model requires longitudinal wearable observations linked to cancer outcomes in an appropriate research dataset. Until that data is available, synthetic data lets us validate the complete feature schema, training code, inference contract, and Watch-to-backend integration without inventing clinical evidence.

## Next research step

Replace the synthetic generator with a properly accessed, consented, longitudinal wearable dataset containing:

1. timestamped wearable observations,
2. cancer diagnosis/outcome labels,
3. relevant confounders and demographics,
4. sufficient follow-up before diagnosis,
5. a held-out external validation cohort.

Evaluation should report sensitivity, specificity, AUROC, AUPRC, calibration, false-positive rate, lead time, subgroup performance, and missing-data robustness. No cancer-related claim should be made from the model until external validation supports it.
