# ============================================================
# FICHIER: ia-service/src/services/llm/__init__.py
# DESCRIPTION: Export des services LLM
# ============================================================

from .base_llm import BaseLLM
#from .ollama_client import OllamaClient
from .qwen import QwenLLM  # ✅ CORRIGÉ
from .prompt_optimizer import PromptOptimizer

__all__ = [
    "BaseLLM",
    #"OllamaClient",
    "QwenLLM",  # ✅ CORRIGÉ
    "PromptOptimizer",
]