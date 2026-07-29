# backend/app/api/v1/routes/chat.py

import logging
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from ....core.database import get_db
from ....core.dependencies import get_current_active_user
from ....models.user import User
from ...schemas.auth_schemas import UserResponse
from typing import List, Optional
import random

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/chat", tags=["Chat"])

# --- Schémas ---
class ChatRequest(BaseModel):
    question: str = Field(..., min_length=1, max_length=2000)
    user_id: Optional[int] = None

class ChatResponse(BaseModel):
    id: str
    answer: str
    suggestions: List[str] = []
    confidence: Optional[float] = None

# --- Endpoint ---
@router.post("/ask", response_model=ChatResponse)
async def ask_question(
    request: ChatRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Endpoint principal du chat. Reçoit une question et retourne une réponse.
    """
    # Vérification d'autorisation : l'utilisateur ne peut voir que ses propres données
    if request.user_id is not None and request.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous ne pouvez pas accéder aux données d'un autre utilisateur",
        )

    try:
        # TODO: Intégration du modèle IA (Mistral, OpenAI, etc.)
        # Pour l'instant, réponse simulée avec suggestions contextuelles
        response = _generate_response(request.question, current_user)

        logger.info(
            f"Chat request from user {current_user.id}: '{request.question[:50]}...'"
        )

        return ChatResponse(
            id=str(int(DateTime.now().timestamp() * 1000)),
            answer=response["answer"],
            suggestions=response["suggestions"],
            confidence=response["confidence"],
        )

    except Exception as e:
        logger.error(f"Chat error: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Une erreur est survenue lors du traitement de votre question.",
        )


def _generate_response(question: str, user: User) -> dict:
    """
    Simule une réponse intelligente avec suggestions.
    """
    # Analyse simple du mot-clé
    question_lower = question.lower()
    response_templates = {
        "fraction": {
            "answer": "Les fractions représentent une partie d'un tout.\n\n"
                      "Exemple : 3/4 signifie 3 parts sur 4.\n"
                      "Pour additionner deux fractions, on met au même dénominateur.\n"
                      "```\n1/2 + 1/3 = 3/6 + 2/6 = 5/6\n```",
            "suggestions": ["Comment multiplier des fractions ?", "Fractions décimales"],
            "confidence": 0.92
        },
        "pythagore": {
            "answer": "Le théorème de Pythagore s'applique aux triangles rectangles.\n\n"
                      "**Formule :** a² + b² = c²\n"
                      "où c est l'hypoténuse (le côté le plus long).",
            "suggestions": ["Exemple d'application", "Contraposée du théorème"],
            "confidence": 0.95
        },
        "conjuguer": {
            "answer": "La conjugaison est la modification du verbe selon le temps, la personne et le mode.\n\n"
                      "Exemple au passé composé du verbe **manger** :\n"
                      "j'ai mangé, tu as mangé, il/elle a mangé, nous avons mangé...",
            "suggestions": ["Préparer un exercice de conjugaison", "Le futur simple"],
            "confidence": 0.88
        },
        "moyenne": {
            "answer": "La moyenne se calcule en additionnant toutes les valeurs et en divisant par le nombre de valeurs.\n\n"
                      "**Formule :**\n"
                      "```\nmoyenne = somme des valeurs / nombre de valeurs\n```\n"
                      "Exemple : (12 + 15 + 18) / 3 = 15",
            "suggestions": ["Moyenne pondérée", "Exercice de calcul"],
            "confidence": 0.90
        },
    }

    # Recherche du mot-clé dans la question
    for keyword, response in response_templates.items():
        if keyword in question_lower:
            return response

    # Réponse générique si aucun mot-clé trouvé
    return {
        "answer": "Je n'ai pas encore de réponse précise à cette question. "
                   "Je suis encore en apprentissage, mais je me développe chaque jour ! 🚀\n\n"
                   "Peux-tu reformuler ta question ou m'indiquer le sujet exact ?",
        "suggestions": ["Explique-moi les fractions", "Théorème de Pythagore", "Conjugaison", "Calcul de moyenne"],
        "confidence": 0.60
    }

from datetime import datetime