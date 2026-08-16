# backend/app/models/user.py

from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import json

class User(Base):
    __tablename__ = "users"
   

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    first_name = Column(String(100))
    last_name = Column(String(100))
    level = Column(String(50), default="Collège")
    avatar_url = Column(String(500), nullable=True)
    bio = Column(Text, nullable=True)
    school = Column(String(255), nullable=True)
    phone_number = Column(String(20), nullable=True)
    birth_date = Column(DateTime, nullable=True)
    preferences = Column(Text, nullable=True)  # ✅ Stocké en JSON
    role = Column(String(50), default="student")  # ✅ en minuscules
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
    last_login = Column(DateTime, nullable=True)

    # Relations
    user_subjects = relationship("UserSubject", back_populates="user", cascade="all, delete-orphan")
    chat_history = relationship("ChatHistory", back_populates="user", foreign_keys="ChatHistory.user_id")
    books = relationship("Book", back_populates="user", foreign_keys="Book.user_id")
    book_likes = relationship("BookLike", back_populates="user", foreign_keys="BookLike.user_id")
    book_comments = relationship("BookComment", back_populates="user", foreign_keys="BookComment.user_id")
    comment_likes = relationship("CommentLike", back_populates="user", foreign_keys="CommentLike.user_id")
    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}".strip() if self.first_name and self.last_name else self.first_name or self.last_name or self.email

    @property
    def preferences_dict(self):
        """Retourne les préférences en dictionnaire"""
        if self.preferences:
            try:
                return json.loads(self.preferences)
            except:
                return {}
        return {}

    def __repr__(self):
        return f"<User {self.email}>"