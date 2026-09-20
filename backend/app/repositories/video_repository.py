# ============================================================
# FICHIER: backend/app/repositories/video_repository.py
# DESCRIPTION: Repository pour les vidéos
# ============================================================

from typing import Optional, List, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from datetime import datetime

from ..models.video_script import VideoScript
from ..models.chapter import Chapter
from ..models.user_progress import UserProgress
from ..models.video_report import VideoReport
import logging

logger = logging.getLogger(__name__)


class VideoRepository:
    """Repository pour les opérations sur les vidéos"""
    
    def __init__(self, db: Session):
        self.db = db
    
    # ============================================================
    # VIDÉOS
    # ============================================================
    
    def get_videos_by_subject(
        self,
        subject_id: int,
        level: str,
        chapter: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> Tuple[List[VideoScript], int]:
        """Récupère les vidéos d'une matière et d'un niveau"""
        query = self.db.query(VideoScript).filter(
            VideoScript.subject_id == subject_id,
            VideoScript.level == level,
        )
        
        if chapter:
            query = query.filter(VideoScript.chapter == chapter)
        
        total = query.count()
        
        videos = query.order_by(
            VideoScript.created_at.desc()
        ).offset((page - 1) * page_size).limit(page_size).all()
        
        return videos, total
    
    def get_video_by_id(self, script_id: str) -> Optional[VideoScript]:
        """Récupère une vidéo par son ID"""
        return self.db.query(VideoScript).filter(
            VideoScript.id == script_id
        ).first()
    
    def increment_views(self, script_id: str):
        """Incrémente le compteur de vues"""
        video = self.get_video_by_id(script_id)
        if video:
            video.views_count += 1
            self.db.commit()
    
    # ============================================================
    # CHAPITRES
    # ============================================================
    
    def get_chapters_by_subject(
        self,
        subject_id: int,
        level: str,
    ) -> List[Chapter]:
        """Récupère les chapitres d'une matière"""
        return self.db.query(Chapter).filter(
            Chapter.subject_id == subject_id,
            or_(
                Chapter.level == level,
                Chapter.level == None,
            )
        ).order_by(Chapter.order_index).all()
    
    def count_videos_in_chapter(
        self,
        subject_id: int,
        level: str,
        chapter: str,
    ) -> int:
        """Compte les vidéos d'un chapitre"""
        return self.db.query(VideoScript).filter(
            VideoScript.subject_id == subject_id,
            VideoScript.level == level,
            VideoScript.chapter == chapter,
        ).count()
    
    def count_completed_in_chapter(
        self,
        user_id: int,
        subject_id: int,
        level: str,
        chapter: str,
    ) -> int:
        """Compte les vidéos complétées d'un chapitre"""
        return self.db.query(UserProgress).join(VideoScript).filter(
            UserProgress.user_id == user_id,
            UserProgress.completed == True,
            VideoScript.subject_id == subject_id,
            VideoScript.level == level,
            VideoScript.chapter == chapter,
        ).count()
    
    # ============================================================
    # PROGRESSION
    # ============================================================
    
    def get_user_progress(
        self,
        user_id: int,
        script_id: str,
    ) -> Optional[UserProgress]:
        """Récupère la progression d'un utilisateur"""
        return self.db.query(UserProgress).filter(
            UserProgress.user_id == user_id,
            UserProgress.script_id == script_id,
        ).first()
    
    def update_progress(
        self,
        user_id: int,
        script_id: str,
        last_position: float,
        watched_seconds: float,
        completed: Optional[bool] = None,
    ) -> UserProgress:
        """Met à jour la progression"""
        progress = self.get_user_progress(user_id, script_id)
        
        if not progress:
            progress = UserProgress(
                user_id=user_id,
                script_id=script_id,
            )
            self.db.add(progress)
        
        progress.last_position_seconds = last_position
        progress.watched_seconds = max(progress.watched_seconds, watched_seconds)
        
        if completed is not None:
            progress.completed = completed
            if completed and not progress.completed_at:
                progress.completed_at = datetime.utcnow()
        
        self.db.commit()
        self.db.refresh(progress)
        return progress
    
    # ============================================================
    # SIGNALEMENT
    # ============================================================
    
    def create_report(
        self,
        user_id: int,
        script_id: str,
        scene_id: Optional[str],
        reason: str,
        comment: Optional[str],
    ) -> VideoReport:
        """Crée un signalement"""
        report = VideoReport(
            reporter_id=user_id,
            script_id=script_id,
            scene_id=scene_id,
            reason=reason,
            comment=comment,
        )
        self.db.add(report)
        
        # Incrémenter le compteur
        video = self.get_video_by_id(script_id)
        if video:
            video.report_count += 1
        
        self.db.commit()
        self.db.refresh(report)
        return report