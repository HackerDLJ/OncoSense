from fastapi import APIRouter, HTTPException

from app.schemas.longitudinal import LongitudinalRequest, LongitudinalResponse
from app.services.longitudinal import analyze, build_baseline

router = APIRouter(prefix="/longitudinal", tags=["Longitudinal Health"])


def _clean(model):
    return {k: v for k, v in model.model_dump().items() if v is not None}


@router.post("/analyze", response_model=LongitudinalResponse)
async def analyze_longitudinal(request: LongitudinalRequest):
    try:
        baseline = build_baseline([_clean(row) for row in request.history])
        result = analyze(baseline, _clean(request.current), request.persistent_days)
        return result
    except (ValueError, KeyError) as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
