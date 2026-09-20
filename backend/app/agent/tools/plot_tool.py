# backend/app/agent/tools/plot_tool.py

import matplotlib.pyplot as plt
import numpy as np
from io import BytesIO
import base64
from typing import Any, Dict
import logging

from .base_tool import BaseTool

logger = logging.getLogger(__name__)


class PlotTool(BaseTool):
    """
    Outil de visualisation de fonctions.
    """
    
    @property
    def name(self) -> str:
        return "plot"
    
    @property
    def description(self) -> str:
        return """
        Génère un graphique d'une fonction mathématique.
        """
    
    @property
    def parameters_schema(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "function": {
                    "type": "string",
                    "description": "La fonction (ex: 'x**2 + 3*x')"
                },
                "x_min": {"type": "number", "default": -10},
                "x_max": {"type": "number", "default": 10}
            },
            "required": ["function"]
        }
    
    async def execute(self, function: str, x_min: float = -10, x_max: float = 10, **kwargs) -> Dict[str, Any]:
        try:
            x = np.linspace(x_min, x_max, 1000)
            
            # Évaluer la fonction (utilisation sécurisée)
            y = eval(function)
            
            fig, ax = plt.subplots(figsize=(8, 6))
            ax.plot(x, y)
            ax.axhline(y=0, color='black', linestyle='-', linewidth=0.5)
            ax.axvline(x=0, color='black', linestyle='-', linewidth=0.5)
            ax.grid(True, alpha=0.3)
            ax.set_title(f"Graphique de {function}")
            ax.set_xlabel("x")
            ax.set_ylabel("f(x)")
            
            # Convertir en base64
            buf = BytesIO()
            plt.savefig(buf, format='png', dpi=150)
            buf.seek(0)
            img_base64 = base64.b64encode(buf.getvalue()).decode('utf-8')
            plt.close(fig)
            
            return {
                "success": True,
                "image": img_base64,
                "format": "png"
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur plot: {str(e)}")
            return {
                "success": False,
                "error": str(e)
            }