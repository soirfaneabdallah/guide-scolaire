# ============================================================
# FICHIER: backend/app/agent/tools/search_tool.py
# DESCRIPTION: Outil de recherche (RAG)
# ============================================================

from typing import Any, Dict, Optional
import logging

from .base_tool import BaseTool, ToolResult
from ...services.ia_client import IAClient

logger = logging.getLogger(__name__)


class SearchTool(BaseTool):
    """
    Outil pour rechercher des informations via le service RAG.
    """
    
    def __init__(self, ia_client: Optional[IAClient] = None):
        self._ia_client = ia_client or IAClient()
    
    @property
    def name(self) -> str:
        return "search"
    
    @property
    def description(self) -> str:
        return """Recherche des informations dans la base de connaissances.
        Utile pour trouver des definitions, des concepts, des explications,
        des exemples ou des references sur un sujet."""
    
    @property
    def parameters_schema(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "La requete de recherche (ex: 'theoreme de Pythagore')"
                },
                "subject": {
                    "type": "string",
                    "description": "Filtre par matiere (ex: 'mathematiques', 'francais')",
                    "optional": True
                },
                "level": {
                    "type": "string",
                    "description": "Filtre par niveau (ex: '3eme', 'Terminale')",
                    "optional": True
                },
                "top_k": {
                    "type": "integer",
                    "description": "Nombre de resultats a retourner (defaut: 5)",
                    "default": 5
                }
            },
            "required": ["query"]
        }
    
    async def execute(
        self,
        query: str,
        subject: Optional[str] = None,
        level: Optional[str] = None,
        top_k: int = 5,
        **kwargs
    ) -> ToolResult:
        """Execute une recherche."""
        try:
            logger.info(f"🔍 Recherche: {query}")
            logger.info(f"   Filtres: sujet={subject}, niveau={level}")
            
            # ✅ Appel au service IA pour la recherche RAG
            # Pour l'instant, on simule une recherche
            # Plus tard, on appellera l'API RAG de ia-service
            
            # Simulation de resultats
            results = [
                {
                    "content": f"Information sur '{query}': Ce concept est fondamental en {subject or 'mathematiques'}.",
                    "source": "base_de_connaissances",
                    "subject": subject or "general",
                    "level": level or "tous",
                    "score": 0.95
                },
                {
                    "content": f"Exemple d'application de '{query}' dans la vie quotidienne.",
                    "source": "exemples",
                    "subject": subject or "general",
                    "level": level or "tous",
                    "score": 0.82
                },
                {
                    "content": f"Definition detaillee de '{query}' adaptee au niveau {level or 'college'}.",
                    "source": "cours",
                    "subject": subject or "general",
                    "level": level or "tous",
                    "score": 0.78
                }
            ]
            
            # Filtrer les resultats si necessaire
            if subject:
                results = [r for r in results if r["subject"] == subject or r["subject"] == "general"]
            
            if level:
                results = [r for r in results if r["level"] == level or r["level"] == "tous"]
            
            # Limiter
            results = results[:top_k]
            
            if not results:
                return ToolResult(
                    success=False,
                    error="Aucun resultat trouve pour cette recherche",
                    metadata={"query": query}
                )
            
            return ToolResult(
                success=True,
                result=results,
                metadata={
                    "query": query,
                    "count": len(results),
                    "subject": subject,
                    "level": level
                }
            )
            
        except Exception as e:
            logger.error(f"❌ Erreur recherche: {str(e)}")
            return await self.on_error(e)