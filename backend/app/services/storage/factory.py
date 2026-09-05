# ============================================================
# FICHIER: backend/app/services/storage/factory.py
# DESCRIPTION: Factory de services de stockage
# ============================================================

from enum import Enum
from typing import Dict, Type, Optional

from .base_storage import BaseStorage
from .local_storage import LocalStorage
from .firebase_storage import FirebaseStorage


class StorageType(Enum):
    """Types de stockage disponibles"""
    LOCAL = "local"
    FIREBASE = "firebase"
    S3 = "s3"  # Future extension


class StorageFactory:
    """
    Factory pour les services de stockage.
    """
    
    _storages: Dict[str, Type[BaseStorage]] = {}
    
    @classmethod
    def register(cls, storage_type: StorageType, storage_class: Type[BaseStorage]):
        """
        Enregistre un nouveau service de stockage.
        
        Args:
            storage_type: Type de stockage
            storage_class: Classe du service
        """
        cls._storages[storage_type.value] = storage_class
        print(f"✅ Stockage enregistre: {storage_type.value}")
    
    @classmethod
    def get_storage(cls, storage_type: StorageType, **kwargs) -> Optional[BaseStorage]:
        """
        Recupere une instance du service de stockage.
        
        Args:
            storage_type: Type de stockage
            **kwargs: Arguments pour l'initialisation
            
        Returns:
            Optional[BaseStorage]: Instance du service ou None
        """
        storage_class = cls._storages.get(storage_type.value)
        if not storage_class:
            return None
        return storage_class(**kwargs)
    
    @classmethod
    def get_preferred_storage(cls, **kwargs) -> BaseStorage:
        """
        Recupere le service de stockage prefere.
        Par defaut: local, puis Firebase si configure.
        
        Returns:
            BaseStorage: Service de stockage
        """
        # Essayer Firebase si disponible
        try:
            firebase = cls.get_storage(StorageType.FIREBASE, **kwargs)
            if firebase:
                return firebase
        except Exception:
            pass
        
        # Fallback sur local
        return cls.get_storage(StorageType.LOCAL, **kwargs)


# Enregistrer les services de stockage par defaut
StorageFactory.register(StorageType.LOCAL, LocalStorage)
StorageFactory.register(StorageType.FIREBASE, FirebaseStorage)