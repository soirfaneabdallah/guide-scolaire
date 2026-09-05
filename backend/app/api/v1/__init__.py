# ============================================================
# FICHIER: backend/app/api/v1/__init__.py
# DESCRIPTION: Export des routeurs de l'API v1
# ============================================================

from .routes import (
    auth,
    #users,
    subjects,
    chat,
    agent,  # ✅ Ajout du routeur agent
)

__all__ = [
    "auth",
    "users",
    "subjects",
    "chat",
    "agent",
]