# ============================================================
# FICHIER: backend/app/services/generation/factory.py
# DESCRIPTION: Factory de generateurs d'animations
# ============================================================

from enum import Enum
from typing import Dict, Type, Optional, List

from .base_generator import BaseGenerator
from .manim_generator import ManimGenerator
from .matplotlib_generator import MatplotlibGenerator
from app.core.constants.video_constants import PREFERRED_GENERATORS


class GeneratorType(Enum):
    """Types de generateurs disponibles"""
    MANIM = "manim"
    MATPLOTLIB = "matplotlib"
    THREEJS = "threejs"  # Future extension
    UNITY = "unity"  # Future extension


class GeneratorFactory:
    """
    Factory permettant d'ajouter facilement de nouveaux generateurs.
    Pattern Registry pour une extensibilite maximale.
    """
    
    _generators: Dict[str, Type[BaseGenerator]] = {}
    
    @classmethod
    def register(cls, generator_type: GeneratorType, generator_class: Type[BaseGenerator]):
        """
        Enregistre un nouveau generateur.
        
        Args:
            generator_type: Type du generateur
            generator_class: Classe du generateur
        """
        cls._generators[generator_type.value] = generator_class
        print(f"✅ Generateur enregistre: {generator_type.value}")
    
    @classmethod
    def get_generator(cls, generator_type: GeneratorType) -> Optional[BaseGenerator]:
        """
        Recupere une instance du generateur.
        
        Args:
            generator_type: Type du generateur
            
        Returns:
            Optional[BaseGenerator]: Instance du generateur ou None
        """
        generator_class = cls._generators.get(generator_type.value)
        if not generator_class:
            return None
        return generator_class()
    
    @classmethod
    def get_available_generators(cls) -> List[str]:
        """
        Liste les generateurs disponibles.
        
        Returns:
            List[str]: Liste des noms des generateurs
        """
        return list(cls._generators.keys())
    
    @classmethod
    def get_preferred_generator(cls) -> Optional[BaseGenerator]:
        """
        Recupere le generateur prefere selon la configuration.
        
        Returns:
            Optional[BaseGenerator]: Generateur prefere ou None
        """
        for preferred in PREFERRED_GENERATORS:
            generator = cls.get_generator(GeneratorType(preferred))
            if generator:
                return generator
        return None


# Enregistrer les generateurs par defaut
GeneratorFactory.register(GeneratorType.MANIM, ManimGenerator)
GeneratorFactory.register(GeneratorType.MATPLOTLIB, MatplotlibGenerator)