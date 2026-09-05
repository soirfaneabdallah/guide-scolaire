# ============================================================
# FICHIER: backend/app/agent/tools/base_tool.py
# DESCRIPTION: Interface de base pour tous les outils
# ============================================================

from abc import ABC, abstractmethod
from typing import Any, Dict, Optional
from pydantic import BaseModel, Field
import logging
import time

logger = logging.getLogger(__name__)


class ToolResult(BaseModel):
    """Resultat d'un outil"""
    success: bool
    result: Optional[Any] = None
    error: Optional[str] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)
    duration_ms: Optional[float] = None


class BaseTool(ABC):
    """
    Interface de base pour tous les outils disponibles à l'agent.
    """
    
    @property
    @abstractmethod
    def name(self) -> str:
        """Nom unique de l'outil"""
        pass
    
    @property
    @abstractmethod
    def description(self) -> str:
        """Description de l'outil (pour le prompt de l'agent)"""
        pass
    
    @property
    @abstractmethod
    def parameters_schema(self) -> Dict[str, Any]:
        """Schema des parametres (JSON Schema)"""
        pass
    
    @abstractmethod
    async def execute(self, **kwargs) -> ToolResult:
        """Execute l'outil avec les parametres donnes"""
        pass
    
    async def validate_arguments(self, arguments: Dict[str, Any]) -> bool:
        """Valide les arguments avant execution"""
        return True
    
    async def on_error(self, error: Exception) -> ToolResult:
        """Gestion d'erreur"""
        logger.error(f"Tool {self.name} error: {str(error)}")
        return ToolResult(success=False, error=str(error))
    
    async def run(self, **kwargs) -> ToolResult:
        """Point d'entree pour l'execution avec chronometrage"""
        start_time = time.time()
        try:
            result = await self.execute(**kwargs)
            result.duration_ms = (time.time() - start_time) * 1000
            return result
        except Exception as e:
            return await self.on_error(e)