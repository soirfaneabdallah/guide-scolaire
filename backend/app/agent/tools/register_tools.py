# ============================================================
# FICHIER: backend/app/agent/tools/register_tools.py
# DESCRIPTION: Enregistrement des outils au demarrage
# ============================================================

import logging
from .registry import tool_registry
from .search_tool import SearchTool
from .calculator_tool import CalculatorTool
from .video_tool import VideoTool

logger = logging.getLogger(__name__)


def register_all_tools():
    """
    Enregistre tous les outils disponibles.
    A appeler au demarrage de l'application.
    """
    logger.info("🔧 Enregistrement des outils...")
    
    # Outil de recherche
    search_tool = SearchTool()
    tool_registry.register(search_tool)
    
    # Outil de calcul
    calculator_tool = CalculatorTool()
    tool_registry.register(calculator_tool)
    
    # Outil de video
    video_tool = VideoTool()
    tool_registry.register(video_tool)
    
    logger.info(f"✅ {len(tool_registry.get_all_tools())} outils enregistres")
    
    # Afficher les outils disponibles
    for tool in tool_registry.get_all_tools():
        logger.info(f"   - {tool.name}: {tool.description[:50]}...")