# ============================================================
# FICHIER: backend/app/repositories/video_job_repository.py
# DESCRIPTION: Repository pour les VideoJob
# ============================================================

from typing import Optional, List, Dict, Any
from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import desc, and_

from app.models.video_job import VideoJob, JobStatus


class VideoJobRepository:
    """
    Repository pour les operations CRUD sur VideoJob.
    """
    
    def __init__(self, db: Session):
        self.db = db
    
    def create(self, **kwargs) -> VideoJob:
        """
        Cree un nouveau job.
        """
        job = VideoJob(**kwargs)
        self.db.add(job)
        self.db.commit()
        self.db.refresh(job)
        return job
    
    def get_by_id(self, job_id: str, user_id: Optional[int] = None) -> Optional[VideoJob]:
        """
        Recupere un job par son ID.
        """
        query = self.db.query(VideoJob).filter(VideoJob.id == job_id)
        if user_id:
            query = query.filter(VideoJob.user_id == user_id)
        return query.first()
    
    def get_by_user(self, user_id: int, limit: int = 50, offset: int = 0) -> List[VideoJob]:
        """
        Recupere les jobs d'un utilisateur.
        """
        return self.db.query(VideoJob).filter(
            VideoJob.user_id == user_id
        ).order_by(desc(VideoJob.created_at)).offset(offset).limit(limit).all()
    
    def get_by_status(self, status: JobStatus, limit: int = 100) -> List[VideoJob]:
        """
        Recupere les jobs par statut.
        """
        return self.db.query(VideoJob).filter(
            VideoJob.status == status
        ).order_by(VideoJob.created_at).limit(limit).all()
    
    def update_status(self, job_id: str, status: JobStatus, **kwargs) -> Optional[VideoJob]:
        """
        Met a jour le statut d'un job.
        """
        job = self.get_by_id(job_id)
        if not job:
            return None
        
        job.status = status
        for key, value in kwargs.items():
            if hasattr(job, key):
                setattr(job, key, value)
        
        job.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(job)
        return job
    
    def update_progress(self, job_id: str, progress: int, **kwargs) -> Optional[VideoJob]:
        """
        Met a jour la progression d'un job.
        """
        job = self.get_by_id(job_id)
        if not job:
            return None
        
        job.progress = min(100, progress)
        for key, value in kwargs.items():
            if hasattr(job, key):
                setattr(job, key, value)
        
        job.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(job)
        return job
    
    def complete_job(self, job_id: str, video_url: str, **kwargs) -> Optional[VideoJob]:
        """
        Marque un job comme termine.
        """
        job = self.get_by_id(job_id)
        if not job:
            return None
        
        job.status = JobStatus.READY
        job.progress = 100
        job.video_url = video_url
        job.completed_at = datetime.utcnow()
        
        for key, value in kwargs.items():
            if hasattr(job, key):
                setattr(job, key, value)
        
        self.db.commit()
        self.db.refresh(job)
        return job
    
    def fail_job(self, job_id: str, error_message: str) -> Optional[VideoJob]:
        """
        Marque un job comme echoue.
        """
        job = self.get_by_id(job_id)
        if not job:
            return None
        
        job.status = JobStatus.FAILED
        job.error_message = error_message
        job.progress = 0
        job.updated_at = datetime.utcnow()
        
        self.db.commit()
        self.db.refresh(job)
        return job
    
    def cancel_job(self, job_id: str) -> Optional[VideoJob]:
        """
        Annule un job.
        """
        job = self.get_by_id(job_id)
        if not job:
            return None
        
        job.status = JobStatus.CANCELLED
        job.updated_at = datetime.utcnow()
        
        self.db.commit()
        self.db.refresh(job)
        return job
    
    def count_pending_jobs(self) -> int:
        """
        Compte les jobs en attente.
        """
        return self.db.query(VideoJob).filter(
            VideoJob.status.in_([JobStatus.PENDING, JobStatus.GENERATING_CODE])
        ).count()
    
    def get_stats(self) -> Dict[str, Any]:
        """
        Recupere les statistiques des jobs.
        """
        total = self.db.query(VideoJob).count()
        pending = self.db.query(VideoJob).filter(
            VideoJob.status.in_([JobStatus.PENDING, JobStatus.GENERATING_CODE])
        ).count()
        ready = self.db.query(VideoJob).filter(VideoJob.status == JobStatus.READY).count()
        failed = self.db.query(VideoJob).filter(VideoJob.status == JobStatus.FAILED).count()
        
        return {
            "total": total,
            "pending": pending,
            "ready": ready,
            "failed": failed,
        }