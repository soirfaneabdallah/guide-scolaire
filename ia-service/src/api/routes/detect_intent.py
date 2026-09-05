# ============================================================
# FICHIER: ai-service/app/api/routes/detect_intent.py
# DESCRIPTION: Route de detection d'intention
# ============================================================

from fastapi import APIRouter
import logging

from src.models.schemas import IntentRequest, IntentResponse
from src.services.llm.ollama_client import OllamaClient

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/intent", response_model=IntentResponse)
async def detect_intent(request: IntentRequest):
    """
    Detecte si l'utilisateur demande une video.
    
    Args:
        request: Requete contenant le message utilisateur
        
    Returns:
        IntentResponse: Resultat de la detection
    """
    try:
        client = OllamaClient()
        
        result = await client.detect_intent(request.text)
        
        return IntentResponse(
            wants_video=result.get("wants_video", False),
            concept=result.get("concept"),
            confidence=result.get("confidence", 0.0)
        )
        
    except Exception as e:
        logger.error(f"Erreur detection intention: {str(e)}")
        return IntentResponse(
            wants_video=False,
            concept=None,
            confidence=0.0
        )
