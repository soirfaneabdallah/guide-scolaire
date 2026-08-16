# backend/app/models/book_comment.py

from sqlalchemy import Column, Integer, Text, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from ..core.database import Base


class BookComment(Base):
    __tablename__ = "book_comments"
    __table_args__ = {'extend_existing': True}

    id = Column(Integer, primary_key=True, index=True)
    content = Column(Text, nullable=False)
    book_id = Column(Integer, ForeignKey("books.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    parent_id = Column(Integer, ForeignKey("book_comments.id"), nullable=True)
    is_edited = Column(Boolean, default=False)
    likes_count = Column(Integer, default=0)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())

    # ✅ Relations
    book = relationship("Book", back_populates="comments", foreign_keys=[book_id])
    user = relationship("User", back_populates="book_comments", foreign_keys=[user_id])
    
    # ✅ Self-relationship pour les réponses
    parent = relationship("BookComment", remote_side=[id], backref="replies")
    
    # ✅ Relation avec les likes
    likes = relationship("CommentLike", back_populates="comment", cascade="all, delete-orphan")

    def to_dict(self, include_replies=True, user_id=None):
        result = {
            "id": self.id,
            "content": self.content,
            "book_id": self.book_id,
            "user_id": self.user_id,
            "user_name": self.user.full_name if self.user else "Anonyme",
            "user_avatar": self.user.avatar_url if self.user else None,
            "parent_id": self.parent_id,
            "is_edited": self.is_edited,
            "likes_count": self.likes_count,
            "is_liked": any(like.user_id == user_id for like in self.likes) if user_id else False,  # ✅ Vérifier si l'utilisateur a liké
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
        
        if include_replies and hasattr(self, 'replies'):
            result["replies"] = [r.to_dict(include_replies=False, user_id=user_id) for r in self.replies if r.id != self.id]
        else:
            result["replies"] = []
            
        return result