# backend/app/models/video_script.py

from sqlalchemy import Column, Integer, String, Text, Float, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import uuid


class VideoScript(Base):
    __tablename__ = "video_scripts"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    title = Column(String(255), nullable=False, index=True)
    description = Column(Text, nullable=True)
    
    subject_id = Column(Integer, ForeignKey("subjects.id"), nullable=False, index=True)
    level = Column(String(50), nullable=False, index=True)
    chapter = Column(String(100), nullable=True, index=True)
    tags = Column(JSON, default=list)
    
    thumbnail_url = Column(String(500), nullable=True)
    thumbnail_prompt = Column(Text, nullable=True)
    
    scenes = Column(JSON, nullable=False, default=list)
    
    scene_count = Column(Integer, default=0)
    estimated_duration_seconds = Column(Integer, default=0)
    language = Column(String(10), default="fr")
    
    views_count = Column(Integer, default=0)
    rating_average = Column(Float, default=0.0)
    rating_count = Column(Integer, default=0)
    report_count = Column(Integer, default=0)
    
    version = Column(Integer, default=1)
    parent_script_id = Column(String(36), ForeignKey("video_scripts.id"), nullable=True)
    correction_reason = Column(Text, nullable=True)
    
    is_validated = Column(Boolean, default=False)
    validated_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    validated_at = Column(DateTime, nullable=True)
    
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    is_generated = Column(Boolean, default=True)
    
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
    
    # ============================================================
    # RELATIONS
    # ============================================================
    
    subject = relationship("Subject", back_populates="video_scripts")
    
    progress = relationship(
        "UserProgress",
        back_populates="script",
        cascade="all, delete-orphan",
    )
    
    # ✅ FIX : Spécifier foreign_keys pour éviter l'ambiguïté
    reports = relationship(
        "VideoReport",
        back_populates="script",
        cascade="all, delete-orphan",
        foreign_keys="VideoReport.script_id",  # ✅ PRÉCISER
    )
    
    # ✅ NOUVELLE RELATION pour les corrections
    corrections = relationship(
        "VideoReport",
        back_populates="corrected_script",
        foreign_keys="VideoReport.corrected_script_id",  # ✅ PRÉCISER
    )
    
    def to_dict(self):
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "subject_id": self.subject_id,
            "level": self.level,
            "chapter": self.chapter,
            "tags": self.tags or [],
            "thumbnail_url": self.thumbnail_url,
            "scene_count": self.scene_count,
            "estimated_duration_seconds": self.estimated_duration_seconds,
            "views_count": self.views_count,
            "rating_average": round(self.rating_average, 1),
            "rating_count": self.rating_count,
            "is_validated": self.is_validated,
            "is_generated": self.is_generated,
            "version": self.version,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
    
    def __repr__(self):
        return f"<VideoScript {self.id} - {self.title}>"