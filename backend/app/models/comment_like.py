# backend/app/models/comment_like.py

from sqlalchemy import Column, Integer, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from ..core.database import Base

class CommentLike(Base):
    __tablename__ = "comment_likes"
    __table_args__ = {'extend_existing': True}

    id = Column(Integer, primary_key=True, index=True)
    comment_id = Column(Integer, ForeignKey("book_comments.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, server_default=func.now())

    # Relations
    comment = relationship("BookComment", back_populates="likes")
    user = relationship("User", back_populates="comment_likes")