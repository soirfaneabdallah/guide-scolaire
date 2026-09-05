# ============================================================
# FICHIER: ia-service/src/prompts/prompt_builder.py
# DESCRIPTION: Constructeur de prompts pedagogiques
# ============================================================

from dataclasses import dataclass
from enum import Enum
from typing import Optional, List, Dict, Any
from src.prompts.manim_prompts import MANIM_SYSTEM_PROMPT
from src.prompts.script_prompts import SCRIPT_SYSTEM_PROMPT
from src.prompts.intent_prompts import INTENT_SYSTEM_PROMPT


class SchoolLevel(str, Enum):
    SIXIEME = "6ème"
    CINQUIEME = "5ème"
    QUATRIEME = "4ème"
    TROISIEME = "3ème"
    SECONDE = "Seconde"
    PREMIERE = "Première"
    TERMINALE = "Terminale"


class Subject(str, Enum):
    MATHS = "mathématiques"
    PHYSICS = "physique-chimie"
    SVT = "svt"
    FRENCH = "français"
    HISTORY = "histoire-géographie"
    ENGLISH = "anglais"
    ARABIC = "arabe"
    PHILOSOPHY = "philosophie"
    ECONOMICS = "économie"
    GENERAL = "général"


class QueryIntent(str, Enum):
    GREETING = "salutation"
    CONCEPT_EXPLAIN = "explication_concept"
    EXERCISE_HELP = "aide_exercice"
    STEP_BY_STEP = "résolution_étape"
    DEFINITION = "définition"
    MEMORIZATION = "mémorisation"
    EXAM_PREP = "préparation_examen"
    CLARIFICATION = "clarification"
    ENCOURAGEMENT = "encouragement"
    VIDEO_REQUEST = "demande_vidéo"
    UNKNOWN = "inconnu"


@dataclass
class PromptContext:
    question: str
    level: str
    intent: QueryIntent = QueryIntent.UNKNOWN
    subject: Subject = Subject.GENERAL
    history_summary: str = ""
    session_id: Optional[str] = None
    turn_number: int = 1


class PromptBuilder:
    """Construit dynamiquement les prompts pour le LLM."""
    
    @staticmethod
    def detect_intent(question: str) -> QueryIntent:
        """Détecte l'intention à partir de mots-clés."""
        q_lower = question.lower()
        
        if any(kw in q_lower for kw in ["bonjour", "salut", "hello"]):
            return QueryIntent.GREETING
        
        if any(kw in q_lower for kw in ["vidéo", "video", "animation", "anime", "génère"]):
            return QueryIntent.VIDEO_REQUEST
        
        if any(kw in q_lower for kw in ["examen", "contrôle", "bac", "brevet"]):
            return QueryIntent.EXAM_PREP
        
        if any(kw in q_lower for kw in ["retenir", "mémoriser", "par cœur"]):
            return QueryIntent.MEMORIZATION
        
        if any(kw in q_lower for kw in ["pas à pas", "étape par étape", "comment résoudre"]):
            return QueryIntent.STEP_BY_STEP
        
        if any(kw in q_lower for kw in ["qu'est-ce que", "c'est quoi", "définition"]):
            return QueryIntent.DEFINITION
        
        if any(kw in q_lower for kw in ["je comprends pas", "j'arrive pas", "difficile"]):
            return QueryIntent.ENCOURAGEMENT
        
        if any(kw in q_lower for kw in ["exercice", "problème", "je suis bloqué"]):
            return QueryIntent.EXERCISE_HELP
        
        return QueryIntent.CONCEPT_EXPLAIN
    
    @staticmethod
    def detect_subject(question: str) -> Subject:
        """Détecte la matière à partir de mots-clés."""
        q_lower = question.lower()
        
        if any(kw in q_lower for kw in ["équation", "calcul", "fonction", "géométrie"]):
            return Subject.MATHS
        if any(kw in q_lower for kw in ["physique", "chimie", "force", "énergie"]):
            return Subject.PHYSICS
        if any(kw in q_lower for kw in ["svt", "cellule", "adn", "photosynthèse"]):
            return Subject.SVT
        if any(kw in q_lower for kw in ["français", "littérature", "grammaire"]):
            return Subject.FRENCH
        if any(kw in q_lower for kw in ["histoire", "géographie", "guerre"]):
            return Subject.HISTORY
        if any(kw in q_lower for kw in ["english", "anglais", "grammar"]):
            return Subject.ENGLISH
        if any(kw in q_lower for kw in ["arabe", "arabic"]):
            return Subject.ARABIC
        if any(kw in q_lower for kw in ["philosophie", "philo", "kant"]):
            return Subject.PHILOSOPHY
        if any(kw in q_lower for kw in ["économie", "marché", "pib"]):
            return Subject.ECONOMICS
        
        return Subject.GENERAL
    
    @classmethod
    def build(cls, ctx: PromptContext) -> tuple[str, str]:
        """Construit le prompt système et utilisateur."""
        
        # Système
        system_prompt = f"""Tu es GUIDE, un assistant pédagogique intelligent.

NIVEAU DE L'ÉLÈVE: {ctx.level}
MATIÈRE: {ctx.subject.value}
INTENTION DÉTECTÉE: {ctx.intent.value}

RÈGLES:
1. Réponds en français, de manière claire et pédagogique
2. Adapte ton langage au niveau de l'élève
3. Sois encourageant et patient
4. Utilise des exemples concrets
5. Structure ta réponse de manière claire

CONTEXTE DE LA CONVERSATION:
{ctx.history_summary or "Début de la conversation"}
"""
        
        # Utilisateur
        user_prompt = f"""QUESTION DE L'ÉLÈVE:
{ctx.question}

INSTRUCTION:
Donne une réponse claire et pédagogique, adaptée au niveau {ctx.level}.
"""
        
        return system_prompt, user_prompt


def build_prompt(
    question: str,
    level: str,
    subject: str = "général",
    history_summary: str = "",
    turn_number: int = 1
) -> tuple[str, str]:
    """
    Construit les prompts pour le LLM.
    
    Returns:
        (system_prompt, user_prompt)
    """
    intent = PromptBuilder.detect_intent(question)
    detected_subject = PromptBuilder.detect_subject(question)
    
    ctx = PromptContext(
        question=question,
        level=level,
        intent=intent,
        subject=detected_subject,
        history_summary=history_summary,
        turn_number=turn_number
    )
    
    return PromptBuilder.build(ctx)


def build_video_prompt(
    conversation_history: List[Dict[str, str]],
    concept: str,
    level: str,
    subject: str = "général",
    duration_sec: int = 90
) -> tuple[str, str]:
    """
    Construit un prompt spécialisé pour la génération vidéo.
    
    Returns:
        (system_prompt, user_prompt)
    """
    history_lines = []
    for msg in conversation_history[-6:]:
        role = "Élève" if msg.get("role") == "user" else "GUIDE"
        history_lines.append(f"{role}: {msg.get('content', '')[:200]}")
    
    history_summary = "\n".join(history_lines) if history_lines else "Aucun historique."
    
    ctx = PromptContext(
        question=f"Génère une vidéo de {duration_sec}s sur: {concept}",
        level=level,
        intent=QueryIntent.VIDEO_REQUEST,
        subject=PromptBuilder.detect_subject(subject + " " + concept),
        history_summary=history_summary
    )
    
    return PromptBuilder.build(ctx)