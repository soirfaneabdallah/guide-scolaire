# ============================================================
# FICHIER: backend/app/api/v1/routes/video_admin.py
# DESCRIPTION: Endpoints admin pour la gestion des videos
# ============================================================

from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Optional
from datetime import datetime
from app.models.user import User
from app.models.video_job import VideoJob
from app.models.video_quota import UserQuota
from app.api.dependencies import get_admin_user, get_db
from sqlalchemy.orm import Session
from sqlalchemy import func

router = APIRouter(prefix="/admin/videos", tags=["admin", "videos"])


@router.get("/stats")
async def get_video_stats(
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    """Statistiques globales des videos"""
    total_jobs = db.query(VideoJob).count()
    
    status_counts = db.query(
        VideoJob.status,
        func.count(VideoJob.id)
    ).group_by(VideoJob.status).all()
    
    today = datetime.utcnow().date()
    today_jobs = db.query(VideoJob).filter(
        func.date(VideoJob.created_at) == today
    ).count()
    
    total_quota_used = db.query(func.sum(UserQuota.used_seconds_today)).scalar() or 0
    
    return {
        "total_jobs": total_jobs,
        "today_jobs": today_jobs,
        "status_distribution": {s.value: c for s, c in status_counts},
        "total_quota_used_minutes": round(total_quota_used / 60, 1),
    }


@router.get("/jobs")
async def get_all_jobs(
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
    status: Optional[str] = None,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    """Liste tous les jobs de generation"""
    query = db.query(VideoJob)
    if status:
        query = query.filter(VideoJob.status == status)
    
    total = query.count()
    jobs = query.order_by(VideoJob.created_at.desc()).offset(offset).limit(limit).all()
    
    return {
        "total": total,
        "limit": limit,
        "offset": offset,
        "jobs": [job.to_dict() for job in jobs]
    }


@router.get("/quotas")
async def get_all_quotas(
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    """Liste tous les quotas utilisateurs"""
    query = db.query(UserQuota)
    total = query.count()
    quotas = query.offset(offset).limit(limit).all()
    
    return {
        "total": total,
        "limit": limit,
        "offset": offset,
        "quotas": [q.to_dict() for q in quotas]
    }


@router.put("/quota/{user_id}")
async def update_user_quota(
    user_id: int,
    daily_limit_seconds: int,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    """Met a jour le quota d'un utilisateur"""
    quota = db.query(UserQuota).filter_by(user_id=user_id).first()
    if not quota:
        raise HTTPException(status_code=404, detail="Quota non trouve")
    
    quota.daily_limit_seconds = daily_limit_seconds
    db.commit()
    
    return {"message": "Quota mis a jour", "new_limit": daily_limit_seconds}