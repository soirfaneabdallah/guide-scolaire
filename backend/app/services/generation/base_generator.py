# ============================================================
# FICHIER: backend/app/services/generation/base_generator.py
# DESCRIPTION: Classe abstraite pour les generateurs d'animations
# ============================================================

from abc import ABC, abstractmethod
from typing import Optional, List


class BaseGenerator(ABC):
    """
    Interface de base pour tous les generateurs d'animations.
    Permet d'ajouter facilement de nouveaux moteurs (ThreeJS, Unity, etc.)
    """
    
    @abstractmethod
    async def generate(self, code: str, job_id: str, workspace: dict) -> Optional[str]:
        """
        Genere l'animation a partir du code.
        
        Args:
            code: Code source de l'animation
            job_id: ID du job
            workspace: Espace de travail
            
        Returns:
            Optional[str]: Chemin du fichier genere ou None
        """
        pass
    
    @abstractmethod
    def validate_code(self, code: str) -> bool:
        """
        Valide le code avant execution.
        
        Args:
            code: Code a valider
            
        Returns:
            bool: True si le code est valide
        """
        pass
    
    @property
    @abstractmethod
    def supported_formats(self) -> List[str]:
        """
        Formats supportes par ce generateur.
        
        Returns:
            List[str]: Liste des formats (mp4, gif, webm, etc.)
        """
        pass
    
    @property
    @abstractmethod
    def name(self) -> str:
        """
        Nom du generateur.
        
        Returns:
            str: Nom du generateur
        """
        pass