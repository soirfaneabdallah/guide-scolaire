# ============================================================
# FICHIER: ia-service/src/services/script/narrator.py
# DESCRIPTION: Génération de la narration (version détaillée)
# ============================================================

import logging

from src.services.llm.qwen import QwenLLM
from src.prompts.narrator_prompts import build_narrator_prompt

logger = logging.getLogger(__name__)


class NarratorService:
    """Génère le texte de narration pour chaque scène"""

    def __init__(self):
        self.llm = QwenLLM()

    async def narrate(
        self,
        concept: str,
        title: str,
        phase: str = "explication",
        level: str = "4ème",
        narration_hint: str = "",
    ) -> str:
        """Génère la narration détaillée pour une scène"""
        logger.info(f"✍️ [Narrator] Scène : {title} ({phase})")

        system, user = build_narrator_prompt(
            concept=concept,
            title=title,
            phase=phase,
            level=level,
            narration_hint=narration_hint,
        )

        response = await self.llm.generate(
            prompt=f"{system}\n\n{user}",
            temperature=0.7,
            max_tokens=1024,  # Plus de tokens pour narration détaillée
        )

        narration = response.strip()

        if not narration or len(narration) < 50:
            narration = (
                f"Dans cette scène, nous allons voir {concept}. "
                f"Prenons le temps de bien comprendre chaque étape."
            )

        logger.info(f"✅ [Narrator] {len(narration)} caractères")
        return narration