# OncoSense Research Target

## Initial target

The first scientific target should be **persistent physiological change associated with early health deterioration**, rather than claiming direct cancer diagnosis.

A disease-specific cancer model should only be added after a literature review identifies a defensible wearable phenotype and an appropriate dataset with reliable labels.

## Why this matters

Wearable measurements are affected by infection, stress, sleep, exercise, medication, age, chronic conditions, and device variability. A useful system therefore needs:

1. A personal baseline.
2. Longitudinal persistence rather than single readings.
3. Multi-signal agreement.
4. Confounder handling.
5. A negative/normal state and non-cancer alternatives.
6. Independent evaluation on held-out populations.

## Evaluation plan

For any future disease-specific model, report at minimum:

- sensitivity / recall
- specificity
- precision / PPV
- NPV
- AUROC and AUPRC
- calibration
- false-alert rate per user-month
- lead time before confirmed diagnosis, when labels permit
- subgroup performance
- robustness to missing wearable data

No clinical claim should be made from a prototype model without appropriate clinical validation and regulatory review.
