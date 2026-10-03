# OncoSense Cancer ML

## What is trained now?

OncoSense now includes a reproducible **breast-cancer research benchmark** trained on the Wisconsin Diagnostic Breast Cancer dataset exposed by scikit-learn. The dataset contains 30 tumor-cell morphology measurements and labels for malignant/benign tumors.

The baseline is standardized logistic regression. Training uses a fixed 80/20 stratified split and 5-fold stratified cross-validation. The checked-in artifact records the feature names, scaler parameters, coefficients, and evaluation metrics so the result is auditable.

Observed benchmark metrics from the training run:

- Test accuracy: **98.25%**
- Test ROC-AUC: **0.9954**
- 5-fold CV ROC-AUC: **0.9953 ± 0.0053**
- Test confusion matrix: `[[41, 1], [1, 71]]`

These numbers are benchmark results on this dataset, not evidence of clinical performance and not evidence that an Apple Watch can detect cancer.

## Why this is not yet the Watch model

The current benchmark's inputs are tumor morphology measurements. Apple Watch cannot measure those variables. Connecting this model directly to Watch data would therefore be scientifically invalid.

The real OncoSense wearable model needs a dataset containing **both longitudinal wearable/physiological measurements and cancer outcomes** for the same participants. A strong research source is the NIH All of Us Research Program, which provides longitudinal EHR data plus wearable data, including Fitbit, and has also published Apple HealthKit data into its Researcher Workbench. Access to individual-level registered/controlled data requires the program's researcher access process.

## Target production research pipeline

```text
Apple HealthKit / Watch
        |
        v
Longitudinal physiological features
        |
        +-----------------------------+
        |                             |
        v                             v
Cancer outcome labels             Confounders
from EHR/clinical data            infection, age,
        |                         medication, etc.
        +-------------+---------------+
                      v
              Time-aware ML model
                      |
             external validation
                      |
             calibration + AUROC
                      |
             Watch/iPhone signal
```

The wearable model should be trained only after we have a properly paired cohort. The repository deliberately keeps the morphology benchmark separate so nobody mistakes it for a wearable cancer detector.

## Reproduce the benchmark

```bash
pip install -r requirements.txt
python ml/train_breast_cancer.py
```

The training script regenerates `ml/artifacts/breast_cancer_logreg.json`.

## Research datasets

- **All of Us Research Program:** wearable data, EHRs, physical measurements and other participant data. Individual-level registered/controlled access is governed by the program's access framework.
- **NCI Genomic Data Commons / TCGA:** large cancer clinical/genomic datasets useful for cancer biology and multimodal research, but they are not wearable datasets and should not be substituted for paired Watch+cancer outcomes.

## Safety

OncoSense is a research project. A model score is not a diagnosis, and a low score cannot rule out cancer. Clinical deployment would require independent prospective validation, subgroup analysis, calibration, false-positive/false-negative analysis, clinical oversight, and applicable regulatory review.
