import base64
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.ml import StressAnalysisRequest, StressAnalysisResponse
from app.services.ml_stress_service import ml_stress_service

router = APIRouter(prefix="/ml", tags=["Voice Stress ML Engine"])


@router.post("/stress-analysis", response_model=StressAnalysisResponse)
def analyze_vocal_distress(
    request: StressAnalysisRequest,
    current_user: User = Depends(get_current_user),
):
    """
    Analyzes base64 audio snippet or extracted acoustic features to assess vocal distress level.
    Ephemeral computation: no audio waveforms are saved to the persistent database.
    """
    return ml_stress_service.analyze(request)


@router.post("/stress-analysis/file", response_model=StressAnalysisResponse)
async def analyze_vocal_distress_file(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    """
    Accepts raw audio file (.wav) upload for vocal agitation analysis.
    """
    if file.content_type and "audio" not in file.content_type and not file.filename.endswith(".wav"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file must be an audio format (.wav recommended).",
        )

    content = await file.read()
    b64_content = base64.b64encode(content).decode("utf-8")
    req = StressAnalysisRequest(raw_audio_base64=b64_content)
    return ml_stress_service.analyze(req)
