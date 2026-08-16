# backend/app/models/__init__.py

from .user import User
from .subject import Subject, UserSubject

from .chat_history import ChatHistory
from .book import Book
from .book_comment import BookComment
from .book_like import BookLike
from .comment_like import CommentLike

# ✅ Exporter clairement
__all__ = [
    "User",
    "Subject", 
    "UserSubject",
    "ChatHistory",
    "Book",
    "BookComment",
    "BookLike",
    "CommentLike",
]