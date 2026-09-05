# ============================================================
# FICHIER: ai-service/app/api/routes/generate_manim.py
# DESCRIPTION: Route de generation de code Manim
# ============================================================

from fastapi import APIRouter, HTTPException
import logging

from src.models.schemas import ManimRequest, ManimResponse
from src.services.llm.ollama_client import OllamaClient

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/manim", response_model=ManimResponse)
async def generate_manim(request: ManimRequest):
    """
    Genere du code Manim a partir du prompt.
    
    Args:
        request: Requete contenant le prompt et les options
        
    Returns:
        ManimResponse: Code genere ou erreur
    """
    try:
        client = OllamaClient()
        
        result = await client.generate_manim_code(
            prompt=request.prompt,
            concept=request.concept,
            level=request.level,
            duration=request.duration
        )
        
        return ManimResponse(
            success=result["success"],
            code=result["code"],
            error=result.get("error"),
            duration_seconds=result.get("duration_seconds")
        )
        
    except Exception as e:
        logger.error(f"Erreur generation Manim: {str(e)}")
        return ManimResponse(
            success=False,
            code="",
            error=str(e)
        )
