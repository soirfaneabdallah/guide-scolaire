# ============================================================
# FICHIER: ia-service/src/prompts/__init__.py
# DESCRIPTION: Export de tous les prompts (chat + vidéo)
# ============================================================

# ============================================================
# PROMPTS CHAT (existants)
# ============================================================

# ✅ Import depuis l'ancien fichier prompt.py (dans src/llm/)
try:
    from src.llm.prompt import build_prompt, build_video_prompt
except ImportError:
    # Fallback : définir des fonctions vides
    def build_prompt(*args, **kwargs):
        return "", ""
    def build_video_prompt(*args, **kwargs):
        return "", ""


# ============================================================
# PROMPTS VIDÉO (nouveaux)
# ============================================================

from .planner_prompts import build_planner_prompt
from .narrator_prompts import build_narrator_prompt
from .coder_prompts import build_coder_prompt


# ============================================================
# EXPORTS
# ============================================================

__all__ = [
    # Chat
    "build_prompt",
    "build_video_prompt",
    
    # Vidéo
    "build_planner_prompt",
    "build_narrator_prompt",
    "build_coder_prompt",
]