# backend/app/models/subject.py

from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from ..core.database import Base

class Subject(Base):
    """Matière par défaut (pour tous les utilisateurs)"""
    __tablename__ = "subjects"
    

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    slug = Column(String(100), unique=True, nullable=False)
    icon = Column(String(50), nullable=True)
    color = Column(String(50), nullable=True)
    is_default = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relations
    user_subjects = relationship("UserSubject", back_populates="subject", cascade="all, delete-orphan")
    books = relationship("Book", back_populates="subject", foreign_keys="Book.subject_id")
    chat_history = relationship("ChatHistory", back_populates="subject", foreign_keys="ChatHistory.subject_id")


class UserSubject(Base):
    """Matières personnalisées par utilisateur"""
    __tablename__ = "user_subjects"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    subject_id = Column(Integer, ForeignKey("subjects.id"), nullable=False)
    custom_name = Column(String(100), nullable=True)
    custom_icon = Column(String(50), nullable=True)
    custom_color = Column(String(50), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relations
    user = relationship("User", back_populates="user_subjects")
    subject = relationship("Subject", back_populates="user_subjects")

    __table_args__ = (
        UniqueConstraint('user_id', 'subject_id', name='uq_user_subject'),
    )