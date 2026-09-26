# ============================================================
# FICHIER: ia-service/src/services/script/coder.py
# DESCRIPTION: Génération de code Manim (version pédagogique)
# ============================================================

import re
import logging

from src.services.llm.qwen import QwenLLM
from src.prompts.coder_prompts import build_coder_prompt

logger = logging.getLogger(__name__)


class CoderService:
    """Génère le code Manim pour chaque scène"""

    def __init__(self):
        self.llm = QwenLLM()

    async def code(
        self,
        concept: str,
        narration: str,
        phase: str = "explication",
        level: str = "4ème",
        duration: int = 60,
    ) -> str:
        """Génère le code Manim détaillé pour une scène"""
        logger.info(f"💻 [Coder] Scène : {concept[:60]}... ({duration}s)")

        system, user = build_coder_prompt(
            concept=concept,
            narration=narration,
            phase=phase,
            level=level,
            duration=duration,
        )

        response = await self.llm.generate(
            prompt=f"{system}\n\n{user}",
            temperature=0.3,
            max_tokens=4096,  # Plus de tokens pour code détaillé
        )

        code = self._extract_code(response)

        if not code:
            logger.warning("⚠️ [Coder] Aucun code, fallback")
            code = self._fallback_code(concept)

        logger.info(f"✅ [Coder] {len(code)} caractères")
        return code

    def _extract_code(self, text: str) -> str:
        """Extrait le code Python des backticks"""
        match = re.search(r'```python\s*(.*?)\s*```', text, re.DOTALL)
        if match:
            return match.group(1).strip()

        match = re.search(r'```\s*(.*?)\s*```', text, re.DOTALL)
        if match:
            return match.group(1).strip()

        if "from manim" in text and "class" in text:
            return text.strip()

        return ""

    def _fallback_code(self, concept: str) -> str:
        """Code Manim par défaut (version longue)"""
        return f'''from manim import *


class MainScene(Scene):
    def construct(self):
        # t=0.0 : Titre
        title = Text("{concept[:40]}", color=BLUE, font_size=48)
        self.play(Write(title))
        self.wait(2)

        # t=4.0 : Définition
        definition = Text(
            "Voici une définition...",
            color=WHITE,
            font_size=32,
        )
        definition.next_to(title, DOWN, buff=1)
        self.play(Write(definition))
        self.wait(3)

        # t=10.0 : Exemple
        example = MathTex("a^2 + b^2 = c^2", color=YELLOW)
        self.play(Transform(definition, example))
        self.wait(3)

        # t=15.0 : Fin
        self.play(FadeOut(title), FadeOut(example))
        self.wait(2)
'''