# backend/app/models/chat_history.py

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from ..core.database import Base

class ChatHistory(Base):
    """Historique des conversations par utilisateur et matière"""
    __tablename__ = "chat_history"
    __table_args__ = {'extend_existing': True}

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    subject_id = Column(Integer, ForeignKey("subjects.id"), nullable=False, index=True)
    
    # Message
    content = Column(Text, nullable=False)
    is_user = Column(Boolean, default=True)
    is_error = Column(Boolean, default=False)
    
    # Métadonnées
    level = Column(String(50), nullable=True)
    model_used = Column(String(100), nullable=True)
    processing_time = Column(Integer, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relations
    user = relationship("User", back_populates="chat_history", foreign_keys=[user_id])
    subject = relationship("Subject", back_populates="chat_history", foreign_keys=[subject_id])