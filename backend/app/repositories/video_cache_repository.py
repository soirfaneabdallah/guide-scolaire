# ============================================================
# FICHIER: backend/app/repositories/video_cache_repository.py
# DESCRIPTION: Repository pour les VideoCache
# ============================================================

from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.models.video_cache import VideoCache
from app.core.constants.video_constants import CACHE_TTL_DAYS


class VideoCacheRepository:
    """
    Repository pour les operations CRUD sur VideoCache.
    """
    
    def __init__(self, db: Session):
        self.db = db
    
    def get_by_key(self, cache_key: str) -> Optional[VideoCache]:
        """
        Recupere une entree cache par sa cle.
        """
        return self.db.query(VideoCache).filter_by(cache_key=cache_key).first()
    
    def get_by_concept(self, concept: str, level: Optional[str] = None) -> Optional[VideoCache]:
        """
        Recupere une entree cache par concept.
        """
        query = self.db.query(VideoCache).filter(
            VideoCache.concept == concept,
            VideoCache.is_expired() == False
        )
        if level:
            query = query.filter(VideoCache.level == level)
        return query.first()
    
    def create(self, **kwargs) -> VideoCache:
        """
        Cree une nouvelle entree cache.
        """
        # Ajouter la date d'expiration si non fournie
        if "expires_at" not in kwargs:
            kwargs["expires_at"] = datetime.utcnow() + timedelta(days=CACHE_TTL_DAYS)
        
        cache = VideoCache(**kwargs)
        self.db.add(cache)
        self.db.commit()
        self.db.refresh(cache)
        return cache
    
    def update(self, cache_key: str, **kwargs) -> Optional[VideoCache]:
        """
        Met a jour une entree cache.
        """
        cache = self.get_by_key(cache_key)
        if not cache:
            return None
        
        for key, value in kwargs.items():
            if hasattr(cache, key):
                setattr(cache, key, value)
        
        self.db.commit()
        self.db.refresh(cache)
        return cache
    
    def increment_views(self, cache_key: str) -> Optional[VideoCache]:
        """
        Incremente le compteur de vues.
        """
        cache = self.get_by_key(cache_key)
        if not cache:
            return None
        
        cache.views_count += 1
        self.db.commit()
        self.db.refresh(cache)
        return cache
    
    def delete_expired(self) -> int:
        """
        Supprime les entrees expirees.
        """
        deleted = self.db.query(VideoCache).filter(
            VideoCache.expires_at < datetime.utcnow()
        ).delete()
        self.db.commit()
        return deleted
    
    def get_popular(self, limit: int = 10) -> List[VideoCache]:
        """
        Recupere les videos les plus populaires.
        """
        return self.db.query(VideoCache).filter(
            VideoCache.is_expired() == False
        ).order_by(desc(VideoCache.views_count)).limit(limit).all()
    
    def get_stats(self) -> Dict[str, Any]:
        """
        Recupere les statistiques du cache.
        """
        total = self.db.query(VideoCache).count()
        expired = self.db.query(VideoCache).filter(
            VideoCache.expires_at < datetime.utcnow()
        ).count()
        
        return {
            "total": total,
            "expired": expired,
            "active": total - expired,
            "total_views": self.db.query(VideoCache.views_count).all()
        }