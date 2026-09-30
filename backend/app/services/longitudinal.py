"""Personal-baseline and longitudinal anomaly engine for OncoSense.

This module deliberately detects persistent physiological change, not cancer.
It is a research/demo signal and must not be presented as a diagnosis.
"""
from __future__ import annotations

from dataclasses import dataclass
from math import sqrt
from statistics import mean, pstdev
from typing import Iterable


FEATURES = (
    "resting_hr",
    "hrv",
    "respiratory_rate",
    "sleep_hours",
    "activity_minutes",
    "wrist_temperature",
)


@dataclass(frozen=True)
class Baseline:
    means: dict[str, float]
    stds: dict[str, float]


@dataclass(frozen=True)
class FeatureChange:
    feature: str
    baseline: float
    current: float
    percent_change: float
    z_score: float


@dataclass(frozen=True)
class AnomalyResult:
    score: float
    level: str
    persistent: bool
    changes: list[FeatureChange]
    message: str


def _safe_std(values: Iterable[float]) -> float:
    values = list(values)
    if len(values) < 2:
        return max(abs(values[0]) * 0.05, 1.0) if values else 1.0
    return max(pstdev(values), 1e-6)


def build_baseline(history: list[dict[str, float]]) -> Baseline:
    if not history:
        raise ValueError("At least one historical observation is required")
    means = {f: mean([float(row[f]) for row in history if f in row]) for f in FEATURES if any(f in r for r in history)}
    stds = {f: _safe_std([float(row[f]) for row in history if f in row]) for f in means}
    return Baseline(means=means, stds=stds)


def analyze(baseline: Baseline, current: dict[str, float], persistent_days: int = 0) -> AnomalyResult:
    changes: list[FeatureChange] = []
    for feature, base in baseline.means.items():
        if feature not in current:
            continue
        value = float(current[feature])
        pct = ((value - base) / abs(base) * 100.0) if base else 0.0
        z = (value - base) / baseline.stds[feature]
        if abs(z) >= 1.0 or abs(pct) >= 10.0:
            changes.append(FeatureChange(feature, base, value, pct, z))

    if not changes:
        return AnomalyResult(0.0, "normal", False, [], "No meaningful deviation from personal baseline detected.")

    magnitude = sqrt(sum(min(abs(c.z_score), 4.0) ** 2 for c in changes))
    multi_signal_bonus = 1.0 + min(len(changes), 4) * 0.12
    score = min(100.0, 100.0 * (1.0 - 1.0 / (1.0 + magnitude / 2.0)) * multi_signal_bonus)
    score = round(min(score, 100.0), 1)
    persistent = persistent_days >= 14

    if score >= 70 and persistent:
        level = "high_attention"
        message = "Persistent multi-signal physiological change detected. Consider discussing the pattern with a qualified clinician."
    elif score >= 40 or persistent:
        level = "watch"
        message = "A sustained change from your personal baseline is present. Continue monitoring and consider medical advice if it persists or symptoms occur."
    else:
        level = "normal_variation"
        message = "Some physiological variation is present, but the current pattern is not persistent enough for a strong alert."

    return AnomalyResult(score, level, persistent, sorted(changes, key=lambda c: abs(c.z_score), reverse=True), message)
