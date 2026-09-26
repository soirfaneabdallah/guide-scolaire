# ============================================================
# FICHIER: ia-service/src/services/script/planner.py
# DESCRIPTION: Décomposition d'un sujet en scènes (version pédagogique)
# ============================================================

import json
import re
import logging
from typing import Dict, Any

from src.services.llm.qwen import QwenLLM
from src.prompts.planner_prompts import build_planner_prompt

logger = logging.getLogger(__name__)


class PlannerService:
    """Décompose un sujet en scènes pédagogiques COMPLÈTES"""

    def __init__(self):
        self.llm = QwenLLM()

    async def plan(
        self,
        prompt: str,
        subject: str = "Général",
        level: str = "4ème",
        language: str = "fr",
        target_duration: int = 720,  # 12 minutes
    ) -> Dict[str, Any]:
        """Décompose un sujet en scènes (10-15 scènes de 45-90s)"""
        logger.info(f"🧠 [Planner] Décomposition complète : {prompt[:60]}...")

        system, user = build_planner_prompt(
            prompt=prompt,
            subject=subject,
            level=level,
            language=language,
            target_duration=target_duration,
        )

        response = await self.llm.generate(
            prompt=f"{system}\n\n{user}",
            temperature=0.7,
            max_tokens=4096,  # Plus de tokens pour plus de scènes
        )

        plan = self._parse_json(response)

        if not plan or "scenes" not in plan:
            logger.warning("⚠️ [Planner] Fallback : plan par défaut")
            return self._fallback_plan(prompt, level)

        # ✅ Accepter 10-15 scènes (pas 3-5)
        plan["scenes"] = plan["scenes"][:15]

        # ✅ S'assurer que chaque scène a les bonnes métadonnées
        for i, scene in enumerate(plan["scenes"], 1):
            scene["order"] = i
            if "phase" not in scene:
                scene["phase"] = self._guess_phase(i, len(plan["scenes"]))

        logger.info(f"✅ [Planner] {len(plan['scenes'])} scènes générées")
        return plan

    def _guess_phase(self, order: int, total: int) -> str:
        """Devine la phase pédagogique basée sur l'ordre"""
        ratio = order / total
        if ratio <= 0.15:
            return "introduction"
        elif ratio <= 0.25:
            return "definition"
        elif ratio <= 0.45:
            return "explication"
        elif ratio <= 0.75:
            return "exemple"
        elif ratio <= 0.9:
            return "exercice"
        return "recapitulatif"

    def _parse_json(self, text: str) -> Dict[str, Any]:
        """Extrait le JSON de la réponse"""
        try:
            match = re.search(r'\{.*\}', text, re.DOTALL)
            if match:
                return json.loads(match.group())
        except Exception as e:
            logger.error(f"❌ [Planner] Erreur parsing : {e}")
        return {}

    def _fallback_plan(self, prompt: str, level: str) -> Dict[str, Any]:
        """Plan par défaut complet (12 scènes)"""
        return {
            "title": prompt[:80],
            "description": f"Cours complet sur : {prompt}",
            "scenes": [
                {
                    "order": 1,
                    "phase": "introduction",
                    "title": "Pourquoi ce concept est important",
                    "concept": prompt,
                    "narration_hint": "Explique l'importance du concept dans la vie réelle",
                },
                {
                    "order": 2,
                    "phase": "introduction",
                    "title": "Plan de la vidéo",
                    "concept": prompt,
                    "narration_hint": "Annonce ce qu'on va voir",
                },
                {
                    "order": 3,
                    "phase": "definition",
                    "title": "Définition précise",
                    "concept": prompt,
                    "narration_hint": "Donne la définition rigoureuse",
                },
                {
                    "order": 4,
                    "phase": "explication",
                    "title": "Première propriété",
                    "concept": prompt,
                    "narration_hint": "Explique la première propriété",
                },
                {
                    "order": 5,
                    "phase": "explication",
                    "title": "Deuxième propriété",
                    "concept": prompt,
                    "narration_hint": "Explique la deuxième propriété",
                },
                {
                    "order": 6,
                    "phase": "explication",
                    "title": "Démonstration",
                    "concept": prompt,
                    "narration_hint": "Démontre le concept",
                },
                {
                    "order": 7,
                    "phase": "exemple",
                    "title": "Exemple simple",
                    "concept": prompt,
                    "narration_hint": "Résous un exemple simple",
                },
                {
                    "order": 8,
                    "phase": "exemple",
                    "title": "Exemple intermédiaire",
                    "concept": prompt,
                    "narration_hint": "Résous un exemple plus complexe",
                },
                {
                    "order": 9,
                    "phase": "exemple",
                    "title": "Exemple complexe",
                    "concept": prompt,
                    "narration_hint": "Résous un exemple avancé",
                },
                {
                    "order": 10,
                    "phase": "exercice",
                    "title": "Exercice guidé",
                    "concept": prompt,
                    "narration_hint": "Résous un exercice pas à pas",
                },
                {
                    "order": 11,
                    "phase": "exercice",
                    "title": "Exercice d'application",
                    "concept": prompt,
                    "narration_hint": "Propose un exercice à faire soi-même",
                },
                {
                    "order": 12,
                    "phase": "recapitulatif",
                    "title": "Récapitulatif",
                    "concept": prompt,
                    "narration_hint": "Résume les points clés",
                },
            ],
        }