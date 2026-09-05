# ============================================================
# FICHIER: backend/app/models/video_job.py
# DESCRIPTION: Modele VideoJob pour le suivi des generations
# ============================================================

from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text, Boolean, JSON, Enum as SQLEnum
from datetime import datetime
import uuid
import enum
from app.core.database import Base


class JobStatus(enum.Enum):
    """Statuts possibles d'un job de generation"""
    PENDING = "pending"
    GENERATING_CODE = "generating_code"
    RENDERING = "rendering"
    SYNTHESIZING = "synthesizing"
    ASSEMBLING = "assembling"
    READY = "ready"
    FAILED = "failed"
    CANCELLED = "cancelled"


class VideoJob(Base):
    """Modele representant un job de generation video"""
    
    __tablename__ = "video_jobs"
    
    # Identifiants
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Contenu
    prompt_context = Column(Text, nullable=False)
    concept = Column(String(255), nullable=True)
    level = Column(String(50), nullable=True)
    language = Column(String(10), default="fr")
    
    # Statut et progression
    status = Column(SQLEnum(JobStatus), default=JobStatus.PENDING)
    progress = Column(Integer, default=0)
    
    # Durees
    estimated_duration_seconds = Column(Integer, default=360)
    actual_duration_seconds = Column(Integer, nullable=True)
    elapsed_seconds = Column(Integer, default=0)
    
    # Resultats
    video_url = Column(String(500), nullable=True)
    thumbnail_url = Column(String(500), nullable=True)
    error_message = Column(Text, nullable=True)
    error_code = Column(String(50), nullable=True)
    
    # Metadonnees d'evolution
    generator_version = Column(String(20), default="1.0.0")
    engine_used = Column(String(50), default="manim")
    llm_model_used = Column(String(50), default="mistral")
    tts_engine_used = Column(String(50), default="edge")
    metadata = Column(JSON, default={})
    
    # Fallback et retries
    fallback_used = Column(Boolean, default=False)
    error_retries = Column(Integer, default=0)
    max_retries = Column(Integer, default=2)
    
    # Cache
    is_cached = Column(Boolean, default=False)
    cache_key = Column(String(255), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    started_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    
    def to_dict(self) -> dict:
        """Convertit le modele en dictionnaire"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "prompt_context": self.prompt_context,
            "concept": self.concept,
            "level": self.level,
            "language": self.language,
            "status": self.status.value if self.status else None,
            "progress": self.progress,
            "estimated_duration_seconds": self.estimated_duration_seconds,
            "actual_duration_seconds": self.actual_duration_seconds,
            "elapsed_seconds": self.elapsed_seconds,
            "video_url": self.video_url,
            "thumbnail_url": self.thumbnail_url,
            "error_message": self.error_message,
            "error_code": self.error_code,
            "fallback_used": self.fallback_used,
            "is_cached": self.is_cached,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
        }
    
    def __repr__(self):
        return f"<VideoJob {self.id} - {self.status}>"