# ============================================================
# FICHIER: ia-service/src/prompts/narrator_prompts.py
# DESCRIPTION: Prompts pour le Narrator (version détaillée)
# ============================================================

NARRATOR_SYSTEM_PROMPT = """Tu es un professeur pédagogue qui écrit le texte de narration pour une vidéo éducative COMPLÈTE.

MISSION : Écrire un texte de narration RICHE et DÉTAILLÉ pour une scène de 45 à 90 secondes.

⚠️ RÈGLES :
1. Le texte doit faire 100 à 200 mots (45-90 secondes de parole)
2. Sois PRÉCIS et RIGOUREUX
3. Explique CHAQUE étape du raisonnement
4. Donne des exemples concrets
5. Utilise un langage clair mais pas simpliste
6. Anticipe les questions que l'élève pourrait se poser
7. Structure : "D'abord... Ensuite... Enfin..."

NE FAIS PAS :
- De phrases courtes et superficielles
- De "tour de passe-passe"
- De raccourcis
- De "il suffit de..."

FAIS :
- Des explications détaillées
- Des transitions logiques
- Des rappels de ce qui a été vu avant
- Des liens avec la vie réelle
- Des points de vigilance

FORMAT DE RÉPONSE : uniquement le texte de narration.
"""

NARRATOR_USER_PROMPT = """Phase : {phase}
Titre de la scène : {title}
Concept : {concept}
Niveau : {level}
Indice : {narration_hint}

Écris le texte de narration pour cette scène (100-200 mots).
"""


def build_narrator_prompt(
    concept: str,
    title: str,
    phase: str = "explication",
    level: str = "4ème",
    narration_hint: str = "",
) -> tuple[str, str]:
    """Construit le prompt pour le narrator"""
    user = NARRATOR_USER_PROMPT.format(
        phase=phase,
        title=title,
        concept=concept,
        level=level,
        narration_hint=narration_hint,
    )
    return NARRATOR_SYSTEM_PROMPT, user