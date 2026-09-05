# ============================================================
# FICHIER: backend/app/services/renderers/factory.py
# DESCRIPTION: Factory de renderers
# ============================================================

from enum import Enum
from typing import Dict, Type, Optional

from .base_renderer import BaseRenderer
from .docker_renderer import DockerRenderer
from .local_renderer import LocalRenderer


class RendererType(Enum):
    """Types de renderers disponibles"""
    DOCKER = "docker"
    LOCAL = "local"
    CLOUD = "cloud"  # Future extension


class RendererFactory:
    """
    Factory pour les renderers d'animations.
    """
    
    _renderers: Dict[str, Type[BaseRenderer]] = {}
    
    @classmethod
    def register(cls, renderer_type: RendererType, renderer_class: Type[BaseRenderer]):
        """
        Enregistre un nouveau renderer.
        
        Args:
            renderer_type: Type du renderer
            renderer_class: Classe du renderer
        """
        cls._renderers[renderer_type.value] = renderer_class
        print(f"✅ Renderer enregistre: {renderer_type.value}")
    
    @classmethod
    def get_renderer(cls, renderer_type: RendererType, **kwargs) -> Optional[BaseRenderer]:
        """
        Recupere une instance du renderer.
        
        Args:
            renderer_type: Type du renderer
            **kwargs: Arguments pour l'initialisation
            
        Returns:
            Optional[BaseRenderer]: Instance du renderer ou None
        """
        renderer_class = cls._renderers.get(renderer_type.value)
        if not renderer_class:
            return None
        return renderer_class(**kwargs)
    
    @classmethod
    def get_preferred_renderer(cls, **kwargs) -> Optional[BaseRenderer]:
        """
        Recupere le renderer prefere (Docker en production, Local en dev).
        
        Returns:
            Optional[BaseRenderer]: Renderer prefere ou None
        """
        # Essayer Docker d'abord
        docker_renderer = cls.get_renderer(RendererType.DOCKER, **kwargs)
        if docker_renderer and docker_renderer.validate_environment():
            return docker_renderer
        
        # Fallback sur Local
        local_renderer = cls.get_renderer(RendererType.LOCAL, **kwargs)
        if local_renderer and local_renderer.validate_environment():
            return local_renderer
        
        return None


# Enregistrer les renderers par defaut
RendererFactory.register(RendererType.DOCKER, DockerRenderer)
RendererFactory.register(RendererType.LOCAL, LocalRenderer)