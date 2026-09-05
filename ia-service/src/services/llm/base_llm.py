# ============================================================
# FICHIER: ia-service/src/services/llm/base_llm.py
# DESCRIPTION: Interface de base pour les clients LLM
# ============================================================

from abc import ABC, abstractmethod
from typing import Optional, Dict, Any
from src.models.schemas import ManimGenerationResult, NarrationScript


class BaseLLM(ABC):
    """
    Interface de base pour tous les clients LLM.
    Permet de switcher facilement entre Ollama, OpenAI, Claude, etc.
    """
    
    @abstractmethod
    async def generate_manim_code(
        self,
        prompt: str,
        concept: Optional[str] = None,
        level: Optional[str] = None,
        duration: int = 180
    ) -> ManimGenerationResult:
        """
        Genere le code Manim pour une animation.
        
        Args:
            prompt: Prompt de l'utilisateur
            concept: Concept a illustrer
            level: Niveau scolaire
            duration: Duree souhaitee en secondes
            
        Returns:
            ManimGenerationResult: Code genere ou erreur
        """
        pass
    
    @abstractmethod
    async def generate_narration_script(
        self,
        code: str,
        concept: str,
        level: str = "college"
    ) -> NarrationScript:
        """
        Genere le script de narration a partir du code Manim.
        
        Args:
            code: Code Manim
            concept: Concept explique
            level: Niveau scolaire
            
        Returns:
            NarrationScript: Script avec segments
        """
        pass
    
    @abstractmethod
    async def detect_intent(self, text: str) -> Dict[str, Any]:
        """
        Detecte si le message demande une video.
        
        Args:
            text: Message utilisateur
            
        Returns:
            Dict: Resultat de la detection
        """
        pass
