# ============================================================
# FICHIER: backend/app/models/user_progress.py
# DESCRIPTION: Progression de l'utilisateur sur les vidéos
# ============================================================

from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import uuid


class UserProgress(Base):
    """
    Progression d'un utilisateur sur une vidéo.
    """
    __tablename__ = "user_progress"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # Qui et quoi
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    script_id = Column(String(36), ForeignKey("video_scripts.id"), nullable=False, index=True)
    
    # Progression
    last_position_seconds = Column(Float, default=0)
    watched_seconds = Column(Float, default=0)
    completed = Column(Boolean, default=False)
    
    # Interaction
    liked = Column(Boolean, nullable=True)
    rating = Column(Integer, nullable=True)  # 1-5
    
    # Timestamps
    started_at = Column(DateTime, server_default=func.now())
    last_watched_at = Column(DateTime, onupdate=func.now())
    completed_at = Column(DateTime, nullable=True)
    
    # Relations
    user = relationship("User", back_populates="progress")
    script = relationship("VideoScript", back_populates="progress")
    
    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "script_id": self.script_id,
            "last_position_seconds": self.last_position_seconds,
            "watched_seconds": self.watched_seconds,
            "completed": self.completed,
            "liked": self.liked,
            "rating": self.rating,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "last_watched_at": self.last_watched_at.isoformat() if self.last_watched_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
        }