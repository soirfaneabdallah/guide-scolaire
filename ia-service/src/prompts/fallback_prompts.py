# ============================================================
# FICHIER: ia-service/src/prompts/fallback_prompts.py
# DESCRIPTION: Prompts de fallback pour la detection d'intention
# ============================================================

FALLBACK_SYSTEM_PROMPT = """
Tu es un assistant qui analyse les messages utilisateur.
Detecte si l'utilisateur demande une video animee.

REGLES:
1. Si l'utilisateur mentionne "video", "animation", "genere" -> probablement oui
2. Si l'utilisateur pose une question simple -> probablement non
3. Retourne UNIQUEMENT du JSON

FORMAT DE REPONSE:
{"wants_video": true/false, "concept": "nom du concept", "confidence": 0.0-1.0}
"""

FALLBACK_USER_PROMPT_TEMPLATE = """
MESSAGE: {text}

ANALYSE ET RETOURNE LE JSON.
"""

FALLBACK_CONCEPT_EXTRACTION = """
Extrais le concept principal de ce message:
MESSAGE: {text}

Retourne UNIQUEMENT le nom du concept (3-5 mots maximum).
"""

FALLBACK_SCRIPT_PROMPT = """
CONCEPT: {concept}
NIVEAU: {level}

Genere un script de narration simple pour expliquer ce concept.
RETOURNE UNIQUEMENT LE JSON.

FORMAT:
[
    {"start": 0.0, "end": 10.0, "text": "Texte..."},
    {"start": 10.0, "end": 20.0, "text": "Texte..."}
]
"""

FALLBACK_ERROR_CORRECTION = """
Le code suivant a produit une erreur:

CODE:
{code}

ERREUR:
{error}

Corrige le code pour qu'il soit executable.
RETOURNE UNIQUEMENT LE CODE CORRIGE.
"""