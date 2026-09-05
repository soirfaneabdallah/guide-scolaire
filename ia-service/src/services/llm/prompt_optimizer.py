# ============================================================
# FICHIER: backend/app/services/llm/prompt_optimizer.py
# DESCRIPTION: Optimisation des prompts pour le LLM
# ============================================================

from typing import Optional, Dict, Any
from datetime import datetime


class PromptOptimizer:
    """
    Optimise les prompts pour de meilleurs resultats.
    Ajoute des informations contextuelles et structure les requetes.
    """
    
    @staticmethod
    def optimize_manim_prompt(
        prompt: str,
        concept: Optional[str] = None,
        level: Optional[str] = None,
        duration: int = 180
    ) -> str:
        """
        Optimise le prompt pour la generation de code Manim.
        """
        context = []
        
        if concept:
            context.append(f"CONCEPT: {concept}")
        if level:
            context.append(f"NIVEAU: {level}")
        
        context.append(f"DUREE: {duration} secondes")
        context.append(f"DATE: {datetime.now().strftime('%Y-%m-%d')}")
        
        context_str = "\n".join(context)
        
        return f"""
[CONTEXTE]
{context_str}

[DEMANDE]
{prompt}

[INSTRUCTIONS SUPPLEMENTAIRES]
- Utilise des couleurs attrayantes (BLUE, RED, YELLOW, GREEN)
- Ajoute des animations progressives (Write, Transform, FadeIn)
- Structure le code avec des commentaires clairs
- Inclus des marqueurs temporels # t=0.0, # t=5.2
- Assure-toi que le code est executable
"""
    
    @staticmethod
    def optimize_script_prompt(
        code: str,
        concept: str,
        level: str = "college"
    ) -> str:
        """
        Optimise le prompt pour la generation de script.
        """
        return f"""
[CONCEPT]
{concept}

[NIVEAU]
{level}

[CODE MANIM]
{code[:2000]}

[INSTRUCTIONS]
- Extrais les marqueurs temporels du code (# t=0.0)
- Chaque segment doit correspondre a une partie de l'animation
- Le texte doit etre clair pour un eleve de {level}
- Utilise un vocabulaire adapte au niveau
- La vitesse de parole doit etre d'environ 130 mots/minute
"""
    
    @staticmethod
    def get_fallback_prompt(text: str) -> str:
        """
        Prompt de fallback pour la detection d'intention.
        """
        return f"""
Analyse le message suivant et determine si l'utilisateur demande une video animee.

MESSAGE: {text}

Reponds UNIQUEMENT au format JSON:
{{"wants_video": true/false, "concept": "nom du concept", "confidence": 0.0-1.0}}
"""