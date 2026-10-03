from fastapi import APIRouter, HTTPException

from app.schemas.longitudinal import LongitudinalRequest, LongitudinalResponse
from app.services.longitudinal import analyze, build_baseline

router = APIRouter(prefix="/longitudinal", tags=["Longitudinal Health"])


def _clean(model):
    return {k: v for k, v in model.model_dump().items() if v is not None}


def _watch_view(result):
    labels = {
        "normal": ("LOW", "Your recent physiological pattern is stable.", "green"),
        "normal_variation": ("LOW", "Some variation is present, but no persistent pattern is currently strong.", "green"),
        "watch": ("WATCH", "A persistent change from your personal baseline needs attention.", "yellow"),
        "high_attention": ("EARLY SIGNAL", "A persistent multi-signal change has been detected and should be reviewed with a qualified clinician.", "orange"),
    }
    title, message, color = labels.get(result.level, labels["watch"])
    return {"state": title, "headline": message, "color": color}


@router.post("/analyze", response_model=LongitudinalResponse)
async def analyze_longitudinal(request: LongitudinalRequest):
    try:
        baseline = build_baseline([_clean(row) for row in request.history])
        result = analyze(baseline, _clean(request.current), request.persistent_days)
        return result
    except (ValueError, KeyError) as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc


@router.post("/watch-screen")
async def watch_screen(request: LongitudinalRequest):
    """Return a watch-friendly screening card from the longitudinal engine.

    This is a research signal. It is not a cancer diagnosis and does not estimate
    a clinically validated cancer probability.
    """
    try:
        baseline = build_baseline([_clean(row) for row in request.history])
        result = analyze(baseline, _clean(request.current), request.persistent_days)
        view = _watch_view(result)
        return {
            **view,
            "score": result.score,
            "persistent": result.persistent,
            "duration_days": request.persistent_days,
            "signals": [
                {
                    "name": change.feature.replace("_", " ").title(),
                    "change_percent": round(change.percent_change, 1),
                    "z_score": round(change.z_score, 2),
                }
                for change in result.changes[:5]
            ],
            "message": result.message,
            "model_status": "wearable research prototype",
            "disclaimer": "OncoSense detects physiological change patterns. It does not diagnose, exclude, or confirm cancer.",
        }
    except (ValueError, KeyError) as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
