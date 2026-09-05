# ============================================================
# FICHIER: backend/app/services/assembly/base_assembler.py
# DESCRIPTION: Interface de base pour les assembleurs video
# ============================================================

from abc import ABC, abstractmethod
from typing import List, Optional, Dict, Any
from app.schemas.video_schemas import NarrationScript


class BaseAssembler(ABC):
    """
    Interface de base pour tous les assembleurs video.
    Permet de changer facilement de moteur d'assemblage.
    """
    
    @abstractmethod
    async def assemble(
        self,
        video_path: str,
        audio_paths: List[str],
        script: NarrationScript,
        job_id: str,
        workspace: dict,
        **kwargs
    ) -> Optional[str]:
        """
        Assemble la video et les pistes audio en un seul fichier.
        
        Args:
            video_path: Chemin de la video brute
            audio_paths: Chemins des fichiers audio
            script: Script de narration
            job_id: ID du job
            workspace: Espace de travail
            **kwargs: Arguments supplementaires
            
        Returns:
            Optional[str]: Chemin du fichier final ou None
        """
        pass
    
    @abstractmethod
    def get_video_duration(self, video_path: str) -> int:
        """
        Recupere la duree d'une video en secondes.
        
        Args:
            video_path: Chemin de la video
            
        Returns:
            int: Duree en secondes
        """
        pass
    
    @abstractmethod
    def get_audio_duration(self, audio_path: str) -> float:
        """
        Recupere la duree d'un fichier audio en secondes.
        
        Args:
            audio_path: Chemin du fichier audio
            
        Returns:
            float: Duree en secondes
        """
        pass
    
    @property
    @abstractmethod
    def supported_formats(self) -> List[str]:
        """
        Formats supportes par l'assembleur.
        
        Returns:
            List[str]: Liste des formats
        """
        pass