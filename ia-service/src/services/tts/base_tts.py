# ============================================================
# FICHIER: backend/app/services/tts/base_tts.py
# DESCRIPTION: Interface de base pour les services TTS
# ============================================================

from abc import ABC, abstractmethod
from typing import List, Optional
from src.schemas.video_schemas import NarrationScript


class BaseTTS(ABC):
    """
    Interface de base pour tous les moteurs TTS.
    Permet de changer facilement de fournisseur.
    """
    
    @abstractmethod
    async def generate_audio(
        self,
        text: str,
        output_path: str,
        voice: Optional[str] = None
    ) -> str:
        """
        Genere un fichier audio a partir du texte.
        
        Args:
            text: Texte a synthetiser
            output_path: Chemin de sortie
            voice: Voix a utiliser (optionnel)
            
        Returns:
            str: Chemin du fichier audio genere
        """
        pass
    
    @abstractmethod
    async def generate_segments(
        self,
        script: NarrationScript,
        job_id: str,
        workspace: dict,
        voice: Optional[str] = None
    ) -> List[str]:
        """
        Genere les segments audio pour un script complet.
        
        Args:
            script: Script de narration
            job_id: ID du job
            workspace: Espace de travail
            voice: Voix a utiliser
            
        Returns:
            List[str]: Chemins des fichiers audio
        """
        pass
    
    @abstractmethod
    async def get_voices(self) -> List[str]:
        """
        Recupere la liste des voix disponibles.
        
        Returns:
            List[str]: Liste des voix
        """
        pass
