# ============================================================
# FICHIER: backend/app/agent/tools/registry.py
# DESCRIPTION: Registre des outils disponibles
# ============================================================

from typing import Dict, Optional, List, Type
from .base_tool import BaseTool
import logging

logger = logging.getLogger(__name__)


class ToolRegistry:
    """
    Registre central des outils disponibles pour l'agent.
    """
    
    _instance = None
    _tools: Dict[str, BaseTool] = {}
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def register(self, tool: BaseTool) -> None:
        """Enregistre un outil dans le registre."""
        self._tools[tool.name] = tool
        logger.info(f"✅ Outil enregistre: {tool.name}")
    
    def unregister(self, tool_name: str) -> None:
        """Desenregistre un outil."""
        if tool_name in self._tools:
            del self._tools[tool_name]
            logger.info(f"🗑️ Outil desenregistre: {tool_name}")
    
    def get_tool(self, tool_name: str) -> Optional[BaseTool]:
        """Recupere un outil par son nom."""
        return self._tools.get(tool_name)
    
    def get_all_tools(self) -> List[BaseTool]:
        """Recupere tous les outils enregistres."""
        return list(self._tools.values())
    
    def get_tools_description(self) -> str:
        """Genere la description des outils pour le prompt."""
        if not self._tools:
            return "Aucun outil disponible."
        
        descriptions = []
        for name, tool in self._tools.items():
            descriptions.append(f"- {name}: {tool.description}")
            descriptions.append(f"  Parametres: {tool.parameters_schema}")
        
        return "\n".join(descriptions)
    
    def get_tools_for_prompt(self) -> str:
        """Genere une description concise pour le prompt LLM."""
        if not self._tools:
            return "No tools available"
        
        lines = []
        for name, tool in self._tools.items():
            params = tool.parameters_schema
            param_desc = []
            if "properties" in params:
                for prop, details in params["properties"].items():
                    required = " (required)" if prop in params.get("required", []) else ""
                    param_desc.append(f"    - {prop}{required}: {details.get('description', '')}")
            lines.append(f"{name}: {tool.description}")
            if param_desc:
                lines.append("  Parameters:")
                lines.extend(param_desc)
            lines.append("")
        
        return "\n".join(lines)
    
    def clear(self) -> None:
        """Vide le registre."""
        self._tools.clear()
        logger.info("🧹 Registre des outils vide")


# Instance globale
tool_registry = ToolRegistry()