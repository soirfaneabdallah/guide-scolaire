# ============================================================
# FICHIER: backend/app/models/video_cache.py
# DESCRIPTION: Modele VideoCache pour le cache des videos
# ============================================================

from sqlalchemy import Column, Integer, String, DateTime, JSON, Boolean, Text
from datetime import datetime
from app.core.database import Base


class VideoCache(Base):
    """Modele representant une video en cache"""
    
    __tablename__ = "video_cache"
    
    # Identifiants
    id = Column(Integer, primary_key=True, index=True)
    cache_key = Column(String(255), unique=True, index=True, nullable=False)
    
    # Contenu
    concept = Column(String(255), nullable=False)
    level = Column(String(50), nullable=True)
    language = Column(String(10), default="fr")
    
    # Resultats
    video_url = Column(String(500), nullable=False)
    thumbnail_url = Column(String(500), nullable=True)
    duration_seconds = Column(Integer, nullable=True)
    
    # Metadonnees
    engine_used = Column(String(50), default="manim")
    quality = Column(String(20), default="medium")
    size_bytes = Column(Integer, nullable=True)
    
    # Statistiques
    views_count = Column(Integer, default=0)
    likes_count = Column(Integer, default=0)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=True)
    
    def is_expired(self) -> bool:
        """Verifie si le cache est expire"""
        if self.expires_at is None:
            return False
        return datetime.utcnow() > self.expires_at
    
    def to_dict(self) -> dict:
        """Convertit le modele en dictionnaire"""
        return {
            "id": self.id,
            "cache_key": self.cache_key,
            "concept": self.concept,
            "level": self.level,
            "language": self.language,
            "video_url": self.video_url,
            "thumbnail_url": self.thumbnail_url,
            "duration_seconds": self.duration_seconds,
            "engine_used": self.engine_used,
            "quality": self.quality,
            "size_bytes": self.size_bytes,
            "views_count": self.views_count,
            "likes_count": self.likes_count,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "expires_at": self.expires_at.isoformat() if self.expires_at else None,
            "is_expired": self.is_expired(),
        }