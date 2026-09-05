# ============================================================
# FICHIER: backend/app/api/v1/routes/video_generation.py
# DESCRIPTION: Endpoints pour la generation de videos
# ============================================================

from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from typing import Optional
from datetime import datetime
from app.schemas.video_schemas import (
    VideoGenerationRequest,
    VideoGenerationResponse,
    VideoJobResponse,
    VideoQuotaResponse,
    GenerationProgressResponse
)
from app.services.video.orchestration_service import VideoOrchestrationService
from app.services.video.quota_service import QuotaService
from app.api.dependencies import get_current_user, get_video_service, get_quota_service
from app.models.user import User

router = APIRouter(prefix="/videos", tags=["videos"])


@router.post("/generate", response_model=VideoGenerationResponse)
async def generate_video(
    request: VideoGenerationRequest,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    video_service: VideoOrchestrationService = Depends(get_video_service),
    quota_service: QuotaService = Depends(get_quota_service),
):
    """
    Lance la generation d'une video pedagogique animee.
    
    - Verifie le quota de l'utilisateur
    - Cree un job de generation
    - Lance le traitement en arriere-plan
    - Retourne l'ID du job pour suivi
    """
    # Verifier le quota
    quota = await quota_service.get_or_create_quota(current_user.id)
    if not quota.can_generate:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "QUOTA_EXCEEDED",
                "message": "Votre quota journalier de 30 min de video est atteint. Revenez demain !",
                "remaining_seconds": 0
            }
        )
    
    # Lancer la generation
    job = await video_service.start_generation(
        user_id=current_user.id,
        prompt=request.prompt,
        concept=request.concept,
        level=request.level,
        duration_seconds=request.duration_seconds,
        language=request.language
    )
    
    # Lancer le worker en arriere-plan
    background_tasks.add_task(
        video_service.process_job,
        job_id=job.id,
        quota_id=quota.id
    )
    
    return VideoGenerationResponse(
        job_id=job.id,
        status=job.status,
        quota_remaining_seconds=quota.remaining_seconds,
        quota_remaining_minutes=round(quota.remaining_seconds / 60, 1),
        estimated_time_seconds=job.estimated_duration_seconds,
        message=f"Generation lancee ! Il vous reste {round(quota.remaining_seconds / 60, 1)} min de video aujourd'hui."
    )


@router.get("/status/{job_id}", response_model=VideoJobResponse)
async def get_job_status(
    job_id: str,
    current_user: User = Depends(get_current_user),
    video_service: VideoOrchestrationService = Depends(get_video_service),
):
    """Recupere le statut d'un job de generation."""
    job = await video_service.get_job(job_id, current_user.id)
    if not job:
        raise HTTPException(status_code=404, detail="Job non trouve")
    return job


@router.get("/progress/{job_id}", response_model=GenerationProgressResponse)
async def get_generation_progress(
    job_id: str,
    current_user: User = Depends(get_current_user),
    video_service: VideoOrchestrationService = Depends(get_video_service),
):
    """Recupere la progression detaillee d'un job."""
    progress = await video_service.get_progress(job_id, current_user.id)
    if not progress:
        raise HTTPException(status_code=404, detail="Job non trouve")
    return progress


@router.get("/quota", response_model=VideoQuotaResponse)
async def get_user_quota(
    current_user: User = Depends(get_current_user),
    quota_service: QuotaService = Depends(get_quota_service),
):
    """Recupere le quota video de l'utilisateur."""
    quota = await quota_service.get_or_create_quota(current_user.id)
    return quota


@router.delete("/job/{job_id}")
async def cancel_job(
    job_id: str,
    current_user: User = Depends(get_current_user),
    video_service: VideoOrchestrationService = Depends(get_video_service),
):
    """Annule un job de generation en cours."""
    success = await video_service.cancel_job(job_id, current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Job non trouve")
    return {"message": "Job annule avec succes"}