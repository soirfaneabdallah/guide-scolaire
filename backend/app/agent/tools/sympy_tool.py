# ============================================================
# FICHIER: backend/app/agent/tools/sympy_tool.py
# DESCRIPTION: Outil de calcul formel avec SymPy
# ============================================================

import sympy as sp
from sympy import (
    symbols, diff, integrate, simplify, solve, 
    expand, factor, limit, series, sqrt, sin, cos,
    tan, log, exp, pi, E, I, Matrix, Rational,
    latex, pretty, Derivative, Integral, Eq, sympify
)
from sympy.parsing.sympy_parser import parse_expr
from typing import Any, Dict, Optional, List, Union
import logging
import json

from .base_tool import BaseTool, ToolResult

logger = logging.getLogger(__name__)


class SymPyTool(BaseTool):
    """
    Outil de calcul formel utilisant SymPy.
    Permet de faire des mathématiques avancées.
    """
    
    @property
    def name(self) -> str:
        return "sympy"
    
    @property
    def description(self) -> str:
        return """
        Effectue des calculs mathématiques avancés avec SymPy.
        
        OPERATIONS SUPPORTEES:
        - derivative: Calcule la dérivée d'une fonction
        - integrate: Calcule l'intégrale d'une fonction
        - solve: Résout une équation
        - simplify: Simplifie une expression
        - factor: Factorise une expression
        - expand: Développe une expression
        - limit: Calcule une limite
        - series: Calcule un développement en série
        - equation: Résout un système d'équations
        - matrix: Opérations matricielles
        - derivative_order: Dérivée d'ordre n
        - partial_derivative: Dérivée partielle
        - definite_integral: Intégrale définie
        - improper_integral: Intégrale impropre
        - differential_equation: Équation différentielle
        
        EXEMPLES:
        - derivative(expression="x**2 + 3*x", variable="x")
        - integrate(expression="sin(x)", variable="x")
        - solve(equation="x**2 - 4 = 0", variable="x")
        - limit(expression="sin(x)/x", variable="x", point="0")
        - factor(expression="x**2 - 4")
        """
    
    @property
    def parameters_schema(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "operation": {
                    "type": "string",
                    "enum": [
                        "derivative", "integrate", "solve", "simplify", 
                        "factor", "expand", "limit", "series",
                        "equation", "matrix", "derivative_order",
                        "partial_derivative", "definite_integral",
                        "improper_integral", "differential_equation"
                    ],
                    "description": "L'opération à effectuer"
                },
                "expression": {
                    "type": "string",
                    "description": "L'expression mathématique (ex: 'x**2 + 3*x')"
                },
                "variable": {
                    "type": "string",
                    "description": "La variable (ex: 'x')",
                    "default": "x"
                },
                "variables": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "Variables pour dérivées partielles"
                },
                "equation": {
                    "type": "string",
                    "description": "L'équation à résoudre (ex: 'x**2 - 4 = 0')"
                },
                "point": {
                    "type": "string",
                    "description": "Point pour la limite ou la série (ex: '0')"
                },
                "order": {
                    "type": "integer",
                    "description": "Ordre de la dérivée ou de la série",
                    "default": 1
                },
                "n": {
                    "type": "integer",
                    "description": "Nombre de termes pour la série",
                    "default": 5
                },
                "a": {
                    "type": "string",
                    "description": "Borne inférieure (pour intégrale définie)"
                },
                "b": {
                    "type": "string",
                    "description": "Borne supérieure (pour intégrale définie)"
                },
                "matrix_a": {
                    "type": "array",
                    "items": {"type": "array"},
                    "description": "Matrice A pour les opérations matricielles"
                },
                "matrix_b": {
                    "type": "array",
                    "items": {"type": "array"},
                    "description": "Matrice B pour les opérations matricielles"
                },
                "operation_matrix": {
                    "type": "string",
                    "enum": ["determinant", "inverse", "eigenvalues", "eigenvectors", "solve_matrix"],
                    "description": "Opération matricielle"
                },
                "variables_order": {
                    "type": "object",
                    "description": "Variables et leurs ordres pour dérivées partielles"
                }
            },
            "required": ["operation"]
        }
    
    async def execute(self, operation: str, **kwargs) -> ToolResult:
        """
        Exécute l'opération SymPy.
        """
        try:
            logger.info(f"🧮 SymPy operation: {operation}")
            logger.info(f"   Paramètres: {kwargs}")
            
            if operation == "derivative":
                result = await self._derivative(**kwargs)
            elif operation == "derivative_order":
                result = await self._derivative_order(**kwargs)
            elif operation == "partial_derivative":
                result = await self._partial_derivative(**kwargs)
            elif operation == "integrate":
                result = await self._integrate(**kwargs)
            elif operation == "definite_integral":
                result = await self._definite_integral(**kwargs)
            elif operation == "improper_integral":
                result = await self._improper_integral(**kwargs)
            elif operation == "solve":
                result = await self._solve(**kwargs)
            elif operation == "equation":
                result = await self._equation(**kwargs)
            elif operation == "differential_equation":
                result = await self._differential_equation(**kwargs)
            elif operation == "simplify":
                result = await self._simplify(**kwargs)
            elif operation == "factor":
                result = await self._factor(**kwargs)
            elif operation == "expand":
                result = await self._expand(**kwargs)
            elif operation == "limit":
                result = await self._limit(**kwargs)
            elif operation == "series":
                result = await self._series(**kwargs)
            elif operation == "matrix":
                result = await self._matrix(**kwargs)
            else:
                return ToolResult(
                    success=False,
                    error=f"Opération non supportée: {operation}"
                )
            
            return result
            
        except Exception as e:
            logger.error(f"❌ Erreur SymPy: {str(e)}")
            return ToolResult(
                success=False,
                error=str(e),
                metadata={"operation": operation}
            )
    
    # ============================================================
    # DÉRIVÉES
    # ============================================================
    
    async def _derivative(self, expression: str, variable: str = "x", **kwargs) -> ToolResult:
        """Calcule la dérivée d'une fonction."""
        try:
            x = symbols(variable)
            expr = parse_expr(expression)
            
            result = diff(expr, x)
            
            return ToolResult(
                success=True,
                result={
                    "expression": str(expr),
                    "derivative": str(result),
                    "latex": latex(result),
                    "variable": variable
                },
                metadata={
                    "operation": "derivative",
                    "expression": expression,
                    "variable": variable
                }
            )
        except Exception as e:
            return ToolResult(success=False, error=str(e))
    
    async def _derivative_order(self, expression: str, variable: str = "x", order: int = 2, **kwargs) -> ToolResult:
        """Calcule la dérivée d'ordre n."""
        try:
            x = symbols(variable)
            expr = parse_expr(expression)
            
            result = diff(expr, x, order)
            
            return ToolResult(
                success=True,
                result={
                    "expression": str(expr),
                    "derivative": str(result),
                    "order": order,
                    "latex": latex(result)
                },
                metadata={
                    "operation": "derivative_order",
                    "expression": expression,
                    "variable": variable,
                    "order": order
                }
            )
        except Exception as e:
            return ToolResult(success=False, error=str(e))
    
    async def _partial_derivative(self, expression: str, variables_order: Dict[str, int], **kwargs) -> ToolResult:
        """Calcule la dérivée partielle."""
        try:
            expr = parse_expr(expression)
            
            # Créer les symboles
            symbols_dict = {var: symbols(var) for var in variables_order.keys()}
            
            # Appliquer les dérivées partielles
            result = expr
            for var, order in variables_order.items():
                result = diff(result, symbols_dict[var], order)
            
            return ToolResult(
                success=True,
                result={
                    "expression": str(expr),
                    "partial_derivative": str(result),
                    "variables_order": variables_order,
                    "latex": latex(result)
                },
                metadata={
                    "operation": "partial_derivative",
                    "variables_order": variables_order
                }
            )
        except Exception as e:
            return ToolResult(success=False, error=str(e))
    
    # ============================================================
    # INTÉGRALES
    # ============================================================
    
    async def _integrate(self, expression: str, variable: str = "x", **kwargs) -> ToolResult:
        """Calcule l'intégrale d'une fonction."""
        try:
            x = symbols(variable)
            expr = parse_expr(expression)
            
            result = integrate(expr, x)
            
            return ToolResult(
                success=True,
                result={
                    "expression": str(expr),
                    "integral": str(result),
                    "latex": latex(result),
                    "variable": variable
                },
                metadata={
                    "operation": "integrate",
                    "expression": expression,
                    "variable": variable
                }
            )
        except Exception as e:
            return ToolResult(success=False, error=str(e))
    
    async def _definite_integral(self, expression: str, variable: str = "x", a: str = "0", b: str = "1", **kwargs) -> ToolResult:
        """Calcule l'intégrale définie."""
        try:
            x = symbols(variable)
            expr = parse_expr(expression)
            
            # Parser les bornes
            a_expr = parse_expr(a)
            b_expr = parse_expr(b)
            
            result = integrate(expr, (x, a_expr, b_expr))
            
            # Calcul numérique
            numeric_result = float(result.evalf()) if result.is_number else None
            
            return ToolResult(
                success=True,
                result={
                    "expression": str(expr),
                    "integral": str(result),
                    "numeric": numeric_result,
                    "latex": latex(result),
                    "bounds": {"a": a, "b": b}
                },
                metadata={
                    "operation": "definite_integral",
                    "bounds": {"a": a, "b": b}
                }
            )
        except Exception as e:
            return ToolResult(success=False, error=str(e))
    
    async def _improper_integral(self, expression: str, variable: str = "x", **kwargs) -> ToolResult:
        """Calcule l'intégrale impropre (de -∞ à +∞)."""
        try:
            x = symbols(variable)
            expr = parse_expr(expression)
            
            # Intégrale de -∞ à +∞
            result = integrate(expr, (x, -sp.oo, sp.oo))
            
            return ToolResult(
                success=True,
                result={
                    "expression": str(expr),
                    "integral": str(result),
                    "latex": latex(result)
                },
                metadata={
                    "operation": "improper_integral"
                }
            )
        except Exception as e:
            return ToolResult(success=False, error=str(e))
    
    # ============================================================
    # ÉQUATIONS
    # ============================================================
    
    async def _solve(self, expression: str, variable: str = "x", **kwargs) -> ToolResult:
        """Résout une équation (expression = 0)."""
        try:
            x = symbols(variable)
            expr = parse_expr(expression)
            
            solutions = solve(expr, x)
            
            # Formater les solutions
            formatted_solutions = [str(sol) for sol in solutions]
            
            return ToolResult(
                success=True,
                result={
                    "equation": f"{expression} = 0",
                    "solutions": formatted_solutions,
                    "latex_solutions": [latex(sol) for sol in solutions],
                    "variable": variable,
                    "count": len(solutions)
                },
                metadata={
                    "operation": "solve",
                    "equation": f"{expression} = 0"
                }
            )
        except Exception as e:
            return ToolResult(success=False, error=str(e))
    
    async def _equation(self, equation: str, variable: str = "x", **kwargs) -> ToolResult:
        """Résout une équation (ex: 'x**2 - 4 = 0')."""
        try:
            x = symbols(variable)
            
            # Parser l'équation
            left, right = equation.split("=")
            left_expr = parse_expr(left.strip())
            right_expr = parse_expr(right.strip())
            
            # Former l'équation
            eq = Eq(left_expr, right_expr)
            
            # Résoudre
            solutions = solve(eq, x)
            
            formatted_solutions = [str(sol) for sol in solutions]
            
            return ToolResult(
                success=True,
                result={
                    "equation": equation,
                    "solutions": formatted_solutions,
                    "latex_solutions": [latex(sol) for sol in solutions],
                    "variable": variable
                },
                metadata={
                    "operation": "equation",
                    "equation": equation
                }
            )
        except Exception as e:
            return ToolResult(success=False, error=str(e))
    
    async def _differential_equation(self, expression: str, **kwargs) -> ToolResult:
        """
        Résout une équation différentielle simple.
        """
        try:
            # Définir la fonction inconnue
            x = symbols('x')
            f = sp.Function('f')(x)
            
            # Parser l'expression
            # Exemple: "diff(f, x) - 2*f = 0"
            left, right = expression.split("=")
            
            # Remplacer diff(f, x) par Derivative(f, x)
            eq_expr = parse_expr(left.strip()) - parse_expr(right.strip())
            
            # Résoudre
            solution = sp.dsolve(eq_expr, f)
            
            return ToolResult(
                success=True,
                result={
                    "equation": expression,
                    "solution": str(solution),
                    "latex": latex(solution)
                },
                metadata={
                    "operation": "differential_equation"
                }
            )
        except Exception as e:
            return ToolResult(success=False, error=str(e))
    
    # ============================================================
    # SIMPLIFICATION
    # ============================================================
    
    async def _simplify(self, expression: str, **kwargs) -> ToolResult:
        """Simplifie une expression."""
        try:
            expr = parse_expr(expression)
            result = simplify(expr)
            
            return ToolResult(
                success=True,
                result={
                    "original": expression,
                    "simplified": str(result),
                    "latex": latex(result)
                },
                metadata={"operation": "simplify"}
            )
        except Exception as e:
            return ToolResult(success=False, error=str(e))
    
    async def _factor(self, expression: str, **kwargs) -> ToolResult:
        """Factorise une expression."""
        try:
            expr = parse_expr(expression)
            result = factor(expr)
            
            return ToolResult(
                success=True,
                result={
                    "original": expression,
                    "factored": str(result),
                    "latex": latex(result)
                },
                metadata={"operation": "factor"}
            )
        except Exception as e:
            return ToolResult(success=False, error=str(e))
    
    async def _expand(self, expression: str, **kwargs) -> ToolResult:
        """Développe une expression."""
        try:
            expr = parse_expr(expression)
            result = expand(expr)
            
            return ToolResult(
                success=True,
                result={
                    "original": expression,
                    "expanded": str(result),
                    "latex": latex(result)
                },
                metadata={"operation": "expand"}
            )
        except Exception as e:
            return ToolResult(success=False, error=str(e))
    
    # ============================================================
    # LIMITES
    # ============================================================
    
    async def _limit(self, expression: str, variable: str = "x", point: str = "0", **kwargs) -> ToolResult:
        """Calcule une limite."""
        try:
            x = symbols(variable)
            expr = parse_expr(expression)
            
            # Parser le point
            if point == "inf":
                point = sp.oo
            elif point == "-inf":
                point = -sp.oo
            else:
                point = parse_expr(point)
            
            result = limit(expr, x, point)
            
            return ToolResult(
                success=True,
                result={
                    "expression": expression,
                    "limit": str(result),
                    "point": str(point),
                    "latex": latex(result)
                },
                metadata={
                    "operation": "limit",
                    "point": str(point)
                }
            )
        except Exception as e:
            return ToolResult(success=False, error=str(e))
    
    # ============================================================
    # SÉRIES
    # ============================================================
    
    async def _series(self, expression: str, variable: str = "x", point: str = "0", n: int = 5, **kwargs) -> ToolResult:
        """Calcule un développement en série."""
        try:
            x = symbols(variable)
            expr = parse_expr(expression)
            
            # Parser le point
            point_expr = parse_expr(point)
            
            result = series(expr, x, point_expr, n)
            
            return ToolResult(
                success=True,
                result={
                    "expression": expression,
                    "series": str(result),
                    "point": point,
                    "terms": n,
                    "latex": latex(result)
                },
                metadata={
                    "operation": "series",
                    "point": point,
                    "terms": n
                }
            )
        except Exception as e:
            return ToolResult(success=False, error=str(e))
    
    # ============================================================
    # MATRICES
    # ============================================================
    
    async def _matrix(self, operation_matrix: str, matrix_a: Optional[List[List[float]]] = None, matrix_b: Optional[List[List[float]]] = None, **kwargs) -> ToolResult:
        """Opérations matricielles."""
        try:
            if not matrix_a:
                return ToolResult(success=False, error="Matrice A requise")
            
            # Convertir en matrice SymPy
            A = Matrix(matrix_a)
            
            if operation_matrix == "determinant":
                result = A.det()
                return ToolResult(
                    success=True,
                    result={
                        "matrix": str(A),
                        "determinant": float(result) if result.is_number else str(result)
                    },
                    metadata={"operation": "determinant"}
                )
            
            elif operation_matrix == "inverse":
                result = A.inv()
                return ToolResult(
                    success=True,
                    result={
                        "matrix": str(A),
                        "inverse": str(result),
                        "latex": latex(result)
                    },
                    metadata={"operation": "inverse"}
                )
            
            elif operation_matrix == "eigenvalues":
                result = A.eigenvals()
                return ToolResult(
                    success=True,
                    result={
                        "matrix": str(A),
                        "eigenvalues": {str(k): float(v) if v.is_number else str(v) for k, v in result.items()}
                    },
                    metadata={"operation": "eigenvalues"}
                )
            
            elif operation_matrix == "eigenvectors":
                result = A.eigenvects()
                formatted = []
                for val, mult, vecs in result:
                    formatted.append({
                        "eigenvalue": str(val),
                        "multiplicity": mult,
                        "vectors": [str(v) for v in vecs]
                    })
                return ToolResult(
                    success=True,
                    result={
                        "matrix": str(A),
                        "eigenvectors": formatted
                    },
                    metadata={"operation": "eigenvectors"}
                )
            
            elif operation_matrix == "solve_matrix":
                if not matrix_b:
                    return ToolResult(success=False, error="Matrice B requise pour résoudre")
                B = Matrix(matrix_b)
                result = A.solve(B)
                return ToolResult(
                    success=True,
                    result={
                        "matrix_A": str(A),
                        "matrix_B": str(B),
                        "solution": str(result),
                        "latex": latex(result)
                    },
                    metadata={"operation": "solve_matrix"}
                )
            
            else:
                return ToolResult(success=False, error=f"Opération matricielle non supportée: {operation_matrix}")
            
        except Exception as e:
            return ToolResult(success=False, error=str(e))