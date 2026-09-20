# ============================================================
# FICHIER: backend/app/api/v1/routes/videos.py
# DESCRIPTION: Endpoints pour les vidéos
# ============================================================

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional, List
import logging

from ....core.database import get_db
from ....core.dependencies import get_current_active_user
from ....models.user import User
from ....models.subject import Subject
from ....models.video_script import VideoScript
from ....models.chapter import Chapter
from ....models.user_progress import UserProgress
from ....schemas.video_schemas import (
    VideoScriptResponse,
    VideoScriptDetailResponse,
    VideoListResponse,
    ChapterResponse,
    UserProgressResponse,
    UpdateProgressRequest,
    VideoReportRequest,
    VideoReportResponse,
)
from ....repositories.video_repository import VideoRepository

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/videos", tags=["Videos"])


# ============================================================
# LISTER LES VIDÉOS PAR MATIÈRE ET NIVEAU
# ============================================================

@router.get("/by-subject/{subject_id}", response_model=VideoListResponse)
async def get_videos_by_subject(
    subject_id: int,
    level: Optional[str] = Query(None, description="Filtrer par niveau"),
    chapter: Optional[str] = Query(None, description="Filtrer par chapitre"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Récupère les vidéos d'une matière.
    
    Si `level` n'est pas fourni, utilise le niveau de l'utilisateur.
    """
    # ✅ Niveau par défaut = niveau de l'utilisateur
    effective_level = level or current_user.level or "3ème"
    
    logger.info(f"📹 Vidéos pour matière {subject_id}, niveau {effective_level}")
    
    repo = VideoRepository(db)
    
    # Récupérer les vidéos
    videos, total = repo.get_videos_by_subject(
        subject_id=subject_id,
        level=effective_level,
        chapter=chapter,
        page=page,
        page_size=page_size,
    )
    
    # Ajouter la progression utilisateur
    videos_with_progress = []
    for video in videos:
        progress = repo.get_user_progress(current_user.id, video.id)
        video_dict = video.to_dict()
        if progress:
            video_dict["user_progress"] = progress.to_dict()
        videos_with_progress.append(VideoScriptResponse(**video_dict))
    
    return VideoListResponse(
        videos=videos_with_progress,
        total=total,
        page=page,
        page_size=page_size,
        has_next=(page * page_size) < total,
    )


# ============================================================
# DÉTAIL D'UNE VIDÉO
# ============================================================

@router.get("/{script_id}", response_model=VideoScriptDetailResponse)
async def get_video_detail(
    script_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Récupère le détail d'une vidéo (avec les scènes).
    """
    repo = VideoRepository(db)
    video = repo.get_video_by_id(script_id)
    
    if not video:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vidéo non trouvée"
        )
    
    # Incrémenter les vues
    repo.increment_views(script_id)
    
    # Ajouter la progression
    progress = repo.get_user_progress(current_user.id, script_id)
    video_dict = video.to_dict()
    video_dict["scenes"] = video.scenes or []
    if progress:
        video_dict["user_progress"] = progress.to_dict()
    
    return VideoScriptDetailResponse(**video_dict)


# ============================================================
# CHAPITRES D'UNE MATIÈRE
# ============================================================

@router.get("/chapters/{subject_id}", response_model=List[ChapterResponse])
async def get_chapters_by_subject(
    subject_id: int,
    level: Optional[str] = Query(None),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Récupère les chapitres d'une matière.
    """
    effective_level = level or current_user.level or "3ème"
    
    repo = VideoRepository(db)
    chapters = repo.get_chapters_by_subject(subject_id, effective_level)
    
    # Ajouter le nombre de vidéos
    chapters_with_count = []
    for chapter in chapters:
        video_count = repo.count_videos_in_chapter(
            subject_id=subject_id,
            level=effective_level,
            chapter=chapter.name,
        )
        completed_count = repo.count_completed_in_chapter(
            user_id=current_user.id,
            subject_id=subject_id,
            level=effective_level,
            chapter=chapter.name,
        )
        
        chapter_dict = chapter.to_dict()
        chapter_dict["video_count"] = video_count
        chapter_dict["completed_count"] = completed_count
        chapters_with_count.append(ChapterResponse(**chapter_dict))
    
    return chapters_with_count


# ============================================================
# PROGRESSION
# ============================================================

@router.post("/{script_id}/progress", response_model=UserProgressResponse)
async def update_progress(
    script_id: str,
    request: UpdateProgressRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Met à jour la progression de l'utilisateur sur une vidéo.
    """
    repo = VideoRepository(db)
    
    progress = repo.update_progress(
        user_id=current_user.id,
        script_id=script_id,
        last_position=request.last_position_seconds,
        watched_seconds=request.watched_seconds,
        completed=request.completed,
    )
    
    return UserProgressResponse(**progress.to_dict())


# ============================================================
# SIGNALEMENT
# ============================================================

@router.post("/{script_id}/report", response_model=VideoReportResponse)
async def report_video(
    script_id: str,
    request: VideoReportRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Signale une vidéo (pour correction ciblée).
    """
    repo = VideoRepository(db)
    
    report = repo.create_report(
        user_id=current_user.id,
        script_id=script_id,
        scene_id=request.scene_id,
        reason=request.reason,
        comment=request.comment,
    )
    
    return VideoReportResponse(**report.to_dict())