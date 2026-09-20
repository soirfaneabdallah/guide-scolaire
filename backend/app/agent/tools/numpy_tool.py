# backend/app/agent/tools/numpy_tool.py

import numpy as np
from scipy import integrate, optimize, stats
from typing import Any, Dict
import logging

from .base_tool import BaseTool

logger = logging.getLogger(__name__)


class NumPyTool(BaseTool):
    """
    Outil de calcul numérique utilisant NumPy et SciPy.
    """
    
    @property
    def name(self) -> str:
        return "numpy"
    
    @property
    def description(self) -> str:
        return """
        Effectue des calculs numériques avec NumPy et SciPy.
        Supporte:
        - Intégration numérique: integrate(f, a, b)
        - Optimisation: minimize(f, x0)
        - Statistiques: mean, std, median, etc.
        - Algèbre linéaire: solve(A, b), eigenvalues, etc.
        """
    
    @property
    def parameters_schema(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "operation": {
                    "type": "string",
                    "enum": ["integrate", "optimize", "statistics", "linear_algebra"],
                    "description": "L'opération à effectuer"
                },
                "function": {
                    "type": "string",
                    "description": "La fonction (ex: 'x**2 + 2*x')"
                },
                "a": {"type": "number", "description": "Borne inférieure"},
                "b": {"type": "number", "description": "Borne supérieure"},
                "data": {"type": "array", "description": "Données pour statistiques"}
            },
            "required": ["operation"]
        }
    
    async def execute(self, operation: str, **kwargs) -> Dict[str, Any]:
        # Implémentation...
        pass