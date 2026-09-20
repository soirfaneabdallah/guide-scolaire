# backend/app/models/video_report.py

from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import uuid


class VideoReport(Base):
    __tablename__ = "video_reports"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # ✅ Clé étrangère vers VideoScript (script signalé)
    script_id = Column(
        String(36),
        ForeignKey("video_scripts.id"),
        nullable=False,
        index=True,
    )
    
    # ✅ Clé étrangère vers VideoScript (script corrigé)
    corrected_script_id = Column(
        String(36),
        ForeignKey("video_scripts.id"),
        nullable=True,
    )
    
    scene_id = Column(String(50), nullable=True)
    reporter_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    reason = Column(String(100), nullable=False)
    comment = Column(Text, nullable=True)
    
    status = Column(String(50), default="pending")
    resolution_type = Column(String(50), nullable=True)
    
    created_at = Column(DateTime, server_default=func.now())
    resolved_at = Column(DateTime, nullable=True)
    
    # ============================================================
    # RELATIONS (avec foreign_keys explicites)
    # ============================================================
    
    # ✅ Relation vers le script signalé
    script = relationship(
        "VideoScript",
        back_populates="reports",
        foreign_keys=[script_id],  # ✅ PRÉCISER
    )
    
    # ✅ Relation vers le script corrigé
    corrected_script = relationship(
        "VideoScript",
        back_populates="corrections",
        foreign_keys=[corrected_script_id],  # ✅ PRÉCISER
    )
    
    # ✅ Relation vers l'utilisateur qui signale
    reporter = relationship(
        "User",
        foreign_keys=[reporter_id],
    )
    
    def to_dict(self):
        return {
            "id": self.id,
            "script_id": self.script_id,
            "scene_id": self.scene_id,
            "reporter_id": self.reporter_id,
            "reason": self.reason,
            "comment": self.comment,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }