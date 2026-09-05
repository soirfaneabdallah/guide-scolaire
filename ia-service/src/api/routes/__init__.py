# ============================================================
# FICHIER: ia-service/src/api/__init__.py
# DESCRIPTION: Export des routes API
# ============================================================

from .routes import router, AskRequest, AskResponse

__all__ = [
    "router",
    "AskRequest",
    "AskResponse",
]