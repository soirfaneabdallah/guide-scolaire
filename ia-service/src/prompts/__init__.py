# ============================================================
# FICHIER: ia-service/src/prompts/__init__.py
# DESCRIPTION: Export des prompts
# ============================================================

from .manim_prompts import (
    MANIM_SYSTEM_PROMPT,
    MANIM_USER_PROMPT_TEMPLATE,
    MANIM_ERROR_CORRECTION_PROMPT
)

from .script_prompts import (
    SCRIPT_SYSTEM_PROMPT,
    SCRIPT_USER_PROMPT_TEMPLATE,
    SCRIPT_FALLBACK_PROMPT
)

from .intent_prompts import (
    INTENT_SYSTEM_PROMPT,
    INTENT_USER_PROMPT_TEMPLATE,
    INTENT_FALLBACK_PROMPT
)

from .fallback_prompts import (
    FALLBACK_SYSTEM_PROMPT,
    FALLBACK_USER_PROMPT_TEMPLATE,
    FALLBACK_CONCEPT_EXTRACTION,
    FALLBACK_SCRIPT_PROMPT,
    FALLBACK_ERROR_CORRECTION
)

from .prompt_builder import (
    build_prompt,
    build_video_prompt,
    PromptBuilder,
    PromptContext,
    QueryIntent,
    Subject,
    SchoolLevel
)

__all__ = [
    # Manim
    "MANIM_SYSTEM_PROMPT",
    "MANIM_USER_PROMPT_TEMPLATE",
    "MANIM_ERROR_CORRECTION_PROMPT",
    
    # Script
    "SCRIPT_SYSTEM_PROMPT",
    "SCRIPT_USER_PROMPT_TEMPLATE",
    "SCRIPT_FALLBACK_PROMPT",
    
    # Intent
    "INTENT_SYSTEM_PROMPT",
    "INTENT_USER_PROMPT_TEMPLATE",
    "INTENT_FALLBACK_PROMPT",
    
    # Fallback
    "FALLBACK_SYSTEM_PROMPT",
    "FALLBACK_USER_PROMPT_TEMPLATE",
    "FALLBACK_CONCEPT_EXTRACTION",
    "FALLBACK_SCRIPT_PROMPT",
    "FALLBACK_ERROR_CORRECTION",
    
    # Builder
    "build_prompt",
    "build_video_prompt",
    "PromptBuilder",
    "PromptContext",
    "QueryIntent",
    "Subject",
    "SchoolLevel",
]