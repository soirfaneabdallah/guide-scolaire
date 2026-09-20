# ============================================================
# FICHIER: backend/app/models/__init__.py
# DESCRIPTION: Import centralisé de tous les modèles
# ============================================================

# ✅ IMPORTANT : L'ordre d'import compte pour SQLAlchemy
# Les modèles de base d'abord, puis ceux qui en dépendent

# ============================================================
# MODÈLES DE BASE
# ============================================================
from .user import User
from .subject import Subject, UserSubject


# ============================================================
# MODÈLES VIDÉO
# ============================================================
from .video_script import VideoScript
from .chapter import Chapter
from .user_progress import UserProgress
from .video_report import VideoReport

# ============================================================
# MODÈLES CHAT
# ============================================================
from .chat_history import ChatHistory

# ============================================================
# MODÈLES LIVRES
# ============================================================
from .book import Book
from .book_comment import BookComment
from .book_like import BookLike
from .comment_like import CommentLike

# ============================================================
# EXPORTS
# ============================================================
__all__ = [
    # Base
    "User",
    "Subject",
    "UserSubject",
    # Vidéo
    "VideoScript",
    "Chapter",
    "UserProgress",
    "VideoReport",
    # Chat
    "ChatHistory",
    # Livres
    "Book",
    "BookComment",
    "BookLike",
    "CommentLike",
]