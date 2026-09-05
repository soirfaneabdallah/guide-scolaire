# ============================================================
# FICHIER: backend/app/agent/tools/calculator_tool.py
# DESCRIPTION: Outil de calcul
# ============================================================

import ast
import operator
import math
import logging
from typing import Any, Dict

from .base_tool import BaseTool, ToolResult

logger = logging.getLogger(__name__)


class CalculatorTool(BaseTool):
    """
    Outil pour effectuer des calculs mathematiques.
    """
    
    @property
    def name(self) -> str:
        return "calculator"
    
    @property
    def description(self) -> str:
        return """Effectue des calculs mathematiques.
        Utile pour resoudre des equations, calculer des resultats,
        verifier des valeurs ou effectuer des operations arithmetiques.
        Supporte: +, -, *, /, **, sqrt, sin, cos, tan, log, abs, etc."""
    
    @property
    def parameters_schema(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "expression": {
                    "type": "string",
                    "description": "L'expression mathematique a calculer (ex: '2 + 2', 'sqrt(16)', 'sin(30)' )"
                }
            },
            "required": ["expression"]
        }
    
    # Operations autorisees
    _OPERATORS = {
        "+": operator.add,
        "-": operator.sub,
        "*": operator.mul,
        "/": operator.truediv,
        "**": operator.pow,
        "//": operator.floordiv,
        "%": operator.mod,
    }
    
    _FUNCTIONS = {
        "sqrt": math.sqrt,
        "sin": math.sin,
        "cos": math.cos,
        "tan": math.tan,
        "log": math.log,
        "log10": math.log10,
        "exp": math.exp,
        "abs": abs,
        "round": round,
        "ceil": math.ceil,
        "floor": math.floor,
        "pi": math.pi,
        "e": math.e,
    }
    
    def _is_safe(self, expression: str) -> bool:
        """Verifie que l'expression est sure."""
        forbidden = ["__import__", "eval", "exec", "compile", "open", "file", "input"]
        for word in forbidden:
            if word in expression:
                return False
        return True
    
    def _evaluate(self, expression: str) -> float:
        """Evalue l'expression de maniere sure."""
        # Nettoyer l'expression
        expr = expression.strip()
        
        # Remplacer les constantes
        for name, value in self._FUNCTIONS.items():
            if name in expr:
                expr = expr.replace(name, f"math_{name}")
        
        # Construire un environnement de securite
        safe_dict = {
            "math_abs": abs,
            "math_round": round,
            "math_ceil": math.ceil,
            "math_floor": math.floor,
            "math_pi": math.pi,
            "math_e": math.e,
        }
        
        # Ajouter les fonctions
        for name, func in self._FUNCTIONS.items():
            safe_dict[f"math_{name}"] = func
        
        # Tenter d'evaluer
        try:
            # Parser l'AST
            node = ast.parse(expr, mode="eval")
            
            # Verifier les noeuds autorises
            for n in ast.walk(node):
                if isinstance(n, ast.Call):
                    func_name = getattr(n.func, "id", None)
                    if func_name and not func_name.startswith("math_"):
                        raise ValueError(f"Fonction non autorisee: {func_name}")
            
            # Executer
            result = eval(compile(node, "<string>", "eval"), {"__builtins__": {}}, safe_dict)
            return float(result)
            
        except Exception as e:
            raise ValueError(f"Erreur de calcul: {str(e)}")
    
    async def execute(self, expression: str, **kwargs) -> ToolResult:
        """Execute le calcul."""
        try:
            logger.info(f"🧮 Calcul: {expression}")
            
            if not self._is_safe(expression):
                return ToolResult(
                    success=False,
                    error="Expression non autorisee"
                )
            
            result = self._evaluate(expression)
            
            return ToolResult(
                success=True,
                result=result,
                metadata={
                    "expression": expression,
                    "result_type": type(result).__name__
                }
            )
            
        except Exception as e:
            logger.error(f"❌ Erreur calcul: {str(e)}")
            return await self.on_error(e)