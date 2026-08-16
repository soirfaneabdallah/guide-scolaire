# backend/app/models/book.py

from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Boolean, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from ..core.database import Base

class Book(Base):
    __tablename__ = "books"
    __table_args__ = {'extend_existing': True}

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False, index=True)
    description = Column(Text, nullable=False)
    author = Column(String(255), nullable=False)
    cover_image = Column(String(500), nullable=True)
    file_url = Column(String(500), nullable=True)
    level = Column(String(50), nullable=True)
    subject_id = Column(Integer, ForeignKey("subjects.id"), nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    is_public = Column(Boolean, default=True)
    views_count = Column(Integer, default=0)
    likes_count = Column(Integer, default=0)
    comments_count = Column(Integer, default=0)
    average_rating = Column(Float, default=0.0)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())

    # ✅ Relations
    user = relationship("User", back_populates="books", foreign_keys=[user_id])
    subject = relationship("Subject", back_populates="books", foreign_keys=[subject_id])
    comments = relationship("BookComment", back_populates="book", cascade="all, delete-orphan", foreign_keys="BookComment.book_id")
    likes = relationship("BookLike", back_populates="book", cascade="all, delete-orphan", foreign_keys="BookLike.book_id")

    def to_dict(self):
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "author": self.author,
            "cover_image": self.cover_image,
            "file_url": self.file_url,
            "level": self.level,
            "subject_id": self.subject_id,
            "subject": self.subject.name if self.subject else None,
            "user_id": self.user_id,
            "user_name": self.user.full_name if self.user else "Anonyme",
            "is_public": self.is_public,
            "views_count": self.views_count,
            "likes_count": self.likes_count,
            "comments_count": self.comments_count,
            "average_rating": self.average_rating,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }