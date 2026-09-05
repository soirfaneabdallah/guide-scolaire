# ============================================================
# FICHIER: backend/app/models/video_analytics.py
# DESCRIPTION: Modele VideoAnalytics pour les statistiques
# ============================================================

from sqlalchemy import Column, Integer, String, DateTime, JSON, ForeignKey, Float
from datetime import datetime
from app.core.database import Base


class VideoAnalytics(Base):
    """Modele representant les analytics d'une video"""
    
    __tablename__ = "video_analytics"
    
    # Identifiants
    id = Column(Integer, primary_key=True, index=True)
    job_id = Column(String(36), ForeignKey("video_jobs.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Temps de chaque etape
    code_generation_time = Column(Float, nullable=True)  # secondes
    rendering_time = Column(Float, nullable=True)
    tts_time = Column(Float, nullable=True)
    assembly_time = Column(Float, nullable=True)
    total_time = Column(Float, nullable=True)
    
    # Qualite
    quality_score = Column(Float, nullable=True)  # 0-100
    user_rating = Column(Integer, nullable=True)  # 1-5
    user_feedback = Column(String(500), nullable=True)
    
    # Metadonnees
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(String(500), nullable=True)
    metadata = Column(JSON, default={})
    
    # Timestamp
    created_at = Column(DateTime, default=datetime.utcnow)
    
    def to_dict(self) -> dict:
        """Convertit le modele en dictionnaire"""
        return {
            "id": self.id,
            "job_id": self.job_id,
            "user_id": self.user_id,
            "code_generation_time": self.code_generation_time,
            "rendering_time": self.rendering_time,
            "tts_time": self.tts_time,
            "assembly_time": self.assembly_time,
            "total_time": self.total_time,
            "quality_score": self.quality_score,
            "user_rating": self.user_rating,
            "user_feedback": self.user_feedback,
            "metadata": self.metadata,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }