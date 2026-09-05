# ============================================================
# FICHIER: ia-service/src/__init__.py
# DESCRIPTION: Package principal du service IA
# ============================================================

from .services.llm.base_llm import BaseLLM

from .services.llm.qwen import QwenLLM  # CORRIGÉ: QwenLLM au lieu de QwenClient
from .services.llm.prompt_optimizer import PromptOptimizer

__all__ = [
    "BaseLLM",
    #"OllamaClient",
    "QwenLLM",  #  CORRIGÉ
    "PromptOptimizer",
]