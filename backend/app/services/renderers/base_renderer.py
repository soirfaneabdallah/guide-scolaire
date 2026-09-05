# ============================================================
# FICHIER: backend/app/services/renderers/base_renderer.py
# DESCRIPTION: Interface de base pour les renderers
# ============================================================

from abc import ABC, abstractmethod
from typing import Optional, List, Dict, Any


class BaseRenderer(ABC):
    """
    Interface de base pour tous les renderers d'animations.
    Permet de switcher entre Docker, local, cloud, etc.
    """
    
    @abstractmethod
    async def render(
        self,
        code: str,
        job_id: str,
        workspace: dict,
        **kwargs
    ) -> Optional[str]:
        """
        Execute le rendu de l'animation.
        
        Args:
            code: Code source
            job_id: ID du job
            workspace: Espace de travail
            **kwargs: Arguments supplementaires
            
        Returns:
            Optional[str]: Chemin du fichier rendu ou None
        """
        pass
    
    @abstractmethod
    async def validate_environment(self) -> bool:
        """
        Valide que l'environnement est pret pour le rendu.
        
        Returns:
            bool: True si l'environnement est valide
        """
        pass
    
    @abstractmethod
    def get_requirements(self) -> List[str]:
        """
        Recupere la liste des dependances requises.
        
        Returns:
            List[str]: Liste des dependances
        """
        pass
    
    @property
    @abstractmethod
    def name(self) -> str:
        """Nom du renderer"""
        pass