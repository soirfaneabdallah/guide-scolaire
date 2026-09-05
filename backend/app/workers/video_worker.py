# ============================================================
# FICHIER: backend/app/workers/video_worker.py
# DESCRIPTION: Worker Celery principal pour la generation video
# ============================================================

import asyncio
import logging
from datetime import datetime
from typing import Optional

from celery import Celery
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.models.video_job import VideoJob, JobStatus
from app.models.video_quota import UserQuota
from app.services.video.orchestration_service import VideoOrchestrationService
from app.services.video.quota_service import QuotaService
from app.services.video.cache_service import CacheService
from app.services.video.notification_service import NotificationService
from app.core.config import settings

logger = logging.getLogger(__name__)

# Initialiser Celery
celery_app = Celery(
    "video_worker",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_time_limit=3600,  # 1 heure max
    task_soft_time_limit=3000,  # 50 minutes
)


@celery_app.task(bind=True, name="video_worker.generate_video")
def generate_video(self, job_id: str, quota_id: int):
    """
    Tache Celery pour generer une video.
    """
    logger.info(f"Starting video generation for job {job_id}")
    
    # Creer un event loop pour les appels async
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    
    try:
        # Executer la generation
        result = loop.run_until_complete(
            _process_generation(job_id, quota_id)
        )
        
        logger.info(f"Job {job_id} completed: {result}")
        return result
        
    except Exception as e:
        logger.error(f"Job {job_id} failed: {str(e)}")
        
        # Mettre a jour le statut en base
        db = SessionLocal()
        try:
            job = db.query(VideoJob).filter_by(id=job_id).first()
            if job:
                job.status = JobStatus.FAILED
                job.error_message = str(e)
                job.progress = 0
                db.commit()
        finally:
            db.close()
        
        raise
    finally:
        loop.close()


async def _process_generation(job_id: str, quota_id: int):
    """
    Traite la generation video.
    """
    orchestration = VideoOrchestrationService()
    
    # Verifier le cache
    db = SessionLocal()
    try:
        job = db.query(VideoJob).filter_by(id=job_id).first()
        if not job:
            raise Exception(f"Job {job_id} not found")
        
        # Verifier si une video existe deja en cache
        cache_service = CacheService()
        cached = await cache_service.get_cached_video(
            concept=job.concept or job.prompt_context[:50],
            level=job.level,
            language=job.language
        )
        
        if cached:
            logger.info(f"Job {job_id}: Video found in cache")
            job.video_url = cached["video_url"]
            job.thumbnail_url = cached.get("thumbnail_url")
            job.status = JobStatus.READY
            job.progress = 100
            job.is_cached = True
            job.cache_key = cached["cache_key"]
            job.completed_at = datetime.utcnow()
            db.commit()
            
            # Notifier l'utilisateur
            await NotificationService.notify_video_ready(
                user_id=job.user_id,
                job_id=job.id,
                video_url=job.video_url
            )
            
            return {"status": "ready", "cached": True}
        
    finally:
        db.close()
    
    # Traiter le job normalement
    await orchestration.process_job(job_id, quota_id)
    
    return {"status": "completed", "cached": False}


@celery_app.task(name="video_worker.cleanup_temp_files")
def cleanup_temp_files():
    """
    Nettoie les fichiers temporaires.
    """
    from app.utils.file_utils import FileUtils
    
    logger.info("Starting cleanup of temporary files")
    
    try:
        # Nettoyer les fichiers de plus de 24h
        deleted = FileUtils.cleanup_old_files(
            directory="workspace",
            max_age_hours=24
        )
        
        logger.info(f"Cleaned up {len(deleted)} temporary files")
        return {"deleted": len(deleted)}
        
    except Exception as e:
        logger.error(f"Cleanup failed: {str(e)}")
        return {"error": str(e)}


@celery_app.task(name="video_worker.quota_reset")
def reset_quotas():
    """
    Reinitialise les quotas quotidiens.
    """
    from app.services.video.quota_service import QuotaService
    import asyncio
    
    logger.info("Starting quota reset")
    
    try:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        quota_service = QuotaService()
        loop.run_until_complete(quota_service.reset_all_quotas())
        
        logger.info("Quotas reset completed")
        return {"status": "completed"}
        
    except Exception as e:
        logger.error(f"Quota reset failed: {str(e)}")
        return {"error": str(e)}
    finally:
        loop.close()