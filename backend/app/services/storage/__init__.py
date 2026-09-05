# ============================================================
# FICHIER: backend/app/services/storage/__init__.py
# DESCRIPTION: Export des services de stockage
# ============================================================

from .base_storage import BaseStorage
from .local_storage import LocalStorage
from .firebase_storage import FirebaseStorage
from .factory import StorageFactory, StorageType

__all__ = [
    "BaseStorage",
    "LocalStorage",
    "FirebaseStorage",
    "StorageFactory",
    "StorageType",
]