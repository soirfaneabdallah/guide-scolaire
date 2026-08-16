# backend/app/models/book_like.py

from sqlalchemy import Column, Integer, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from ..core.database import Base

class BookLike(Base):
    __tablename__ = "book_likes"
    __table_args__ = {'extend_existing': True}

    id = Column(Integer, primary_key=True, index=True)
    book_id = Column(Integer, ForeignKey("books.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, server_default=func.now())

    # ✅ Relations
    book = relationship("Book", back_populates="likes", foreign_keys=[book_id])
    user = relationship("User", back_populates="book_likes", foreign_keys=[user_id])