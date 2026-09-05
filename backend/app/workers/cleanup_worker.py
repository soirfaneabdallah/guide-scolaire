# ============================================================
# FICHIER: backend/app/workers/cleanup_worker.py
# DESCRIPTION: Worker de nettoyage des fichiers temporaires
# ============================================================

import logging
from datetime import datetime, timedelta
from pathlib import Path

from celery import Celery
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.models.video_job import VideoJob, JobStatus
from app.utils.file_utils import FileUtils
from app.core.config import settings

logger = logging.getLogger(__name__)

# Utiliser le meme Celery app que le video_worker
from .video_worker import celery_app


@celery_app.task(name="cleanup_worker.clean_old_jobs")
def clean_old_jobs(days: int = 30):
    """
    Supprime les jobs de plus de X jours.
    
    Args:
        days: Nombre de jours a conserver
    """
    logger.info(f"Cleaning jobs older than {days} days")
    
    db = SessionLocal()
    try:
        cutoff = datetime.utcnow() - timedelta(days=days)
        
        # Jobs termines ou annules
        old_jobs = db.query(VideoJob).filter(
            VideoJob.status.in_([JobStatus.READY, JobStatus.FAILED, JobStatus.CANCELLED]),
            VideoJob.completed_at < cutoff
        ).all()
        
        deleted_count = 0
        for job in old_jobs:
            # Supprimer les fichiers associes
            workspace_path = Path("workspace") / job.id
            if workspace_path.exists():
                import shutil
                shutil.rmtree(workspace_path)
            
            db.delete(job)
            deleted_count += 1
        
        db.commit()
        logger.info(f"Deleted {deleted_count} old jobs")
        return {"deleted": deleted_count}
        
    except Exception as e:
        logger.error(f"Cleanup failed: {str(e)}")
        db.rollback()
        return {"error": str(e)}
    finally:
        db.close()


@celery_app.task(name="cleanup_worker.clean_orphaned_files")
def clean_orphaned_files():
    """
    Nettoie les fichiers orphelins (sans job associe).
    """
    logger.info("Cleaning orphaned files")
    
    db = SessionLocal()
    try:
        # Recuperer tous les IDs de jobs existants
        job_ids = set(db.query(VideoJob.id).all())
        job_ids = {j[0] for j in job_ids}
        
        # Parcourir le dossier workspace
        workspace_dir = Path("workspace")
        if not workspace_dir.exists():
            return {"deleted": 0}
        
        deleted_count = 0
        for job_dir in workspace_dir.iterdir():
            if job_dir.is_dir() and job_dir.name not in job_ids:
                import shutil
                shutil.rmtree(job_dir)
                deleted_count += 1
                logger.info(f"Deleted orphaned directory: {job_dir.name}")
        
        return {"deleted": deleted_count}
        
    except Exception as e:
        logger.error(f"Orphaned files cleanup failed: {str(e)}")
        return {"error": str(e)}
    finally:
        db.close()