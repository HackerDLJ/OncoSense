from pydantic import BaseModel, Field


class Observation(BaseModel):
    resting_hr: float | None = Field(default=None, gt=20, lt=240)
    hrv: float | None = Field(default=None, gt=0, lt=500)
    respiratory_rate: float | None = Field(default=None, gt=5, lt=60)
    sleep_hours: float | None = Field(default=None, ge=0, le=24)
    activity_minutes: float | None = Field(default=None, ge=0, le=1440)
    wrist_temperature: float | None = Field(default=None, gt=20, lt=45)


class LongitudinalRequest(BaseModel):
    history: list[Observation] = Field(min_length=1, max_length=365)
    current: Observation
    persistent_days: int = Field(default=0, ge=0, le=3650)


class ChangeOut(BaseModel):
    feature: str
    baseline: float
    current: float
    percent_change: float
    z_score: float


class LongitudinalResponse(BaseModel):
    score: float
    level: str
    persistent: bool
    changes: list[ChangeOut]
    message: str
    disclaimer: str = "Research/demo signal only. This does not diagnose or rule out cancer."
