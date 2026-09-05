# ============================================================
# FICHIER: backend/app/services/storage/base_storage.py
# DESCRIPTION: Interface de base pour les services de stockage
# ============================================================

from abc import ABC, abstractmethod
from typing import Optional, Dict, Any


class BaseStorage(ABC):
    """
    Interface de base pour tous les services de stockage.
    Permet de switcher entre local, Firebase, S3, etc.
    """
    
    @abstractmethod
    async def save_video(
        self,
        file_path: str,
        job_id: str,
        user_id: int,
        **kwargs
    ) -> Optional[str]:
        """
        Sauvegarde une video et retourne son URL.
        
        Args:
            file_path: Chemin local du fichier
            job_id: ID du job
            user_id: ID de l'utilisateur
            **kwargs: Arguments supplementaires
            
        Returns:
            Optional[str]: URL publique de la video ou None
        """
        pass
    
    @abstractmethod
    async def save_thumbnail(
        self,
        file_path: str,
        job_id: str,
        user_id: int,
        **kwargs
    ) -> Optional[str]:
        """
        Sauvegarde une miniature et retourne son URL.
        
        Args:
            file_path: Chemin local du fichier
            job_id: ID du job
            user_id: ID de l'utilisateur
            
        Returns:
            Optional[str]: URL publique de la miniature ou None
        """
        pass
    
    @abstractmethod
    async def delete_video(self, video_url: str) -> bool:
        """
        Supprime une video de l'espace de stockage.
        
        Args:
            video_url: URL de la video a supprimer
            
        Returns:
            bool: True si supprime, False sinon
        """
        pass
    
    @abstractmethod
    def get_file_size(self, file_path: str) -> int:
        """
        Recupere la taille d'un fichier en bytes.
        
        Args:
            file_path: Chemin du fichier
            
        Returns:
            int: Taille en bytes
        """
        pass