# ============================================================
# FICHIER: ai-service/app/api/routes/generate_script.py
# DESCRIPTION: Route de generation de script de narration
# ============================================================

from fastapi import APIRouter
import logging

from src.models.schemas import ScriptRequest, ScriptResponse, NarrationSegment
from src.services.llm.ollama_client import OllamaClient

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/script", response_model=ScriptResponse)
async def generate_script(request: ScriptRequest):
    """
    Genere un script de narration a partir du code Manim.
    
    Args:
        request: Requete contenant le code et le concept
        
    Returns:
        ScriptResponse: Script avec segments
    """
    try:
        client = OllamaClient()
        
        result = await client.generate_narration_script(
            code=request.code,
            concept=request.concept,
            level=request.level
        )
        
        segments = [
            NarrationSegment(
                start=s.get("start", 0.0),
                end=s.get("end", 10.0),
                text=s.get("text", "")
            )
            for s in result.get("segments", [])
        ]
        
        return ScriptResponse(
            segments=segments,
            total_duration=result.get("total_duration", 0.0)
        )
        
    except Exception as e:
        logger.error(f"Erreur generation script: {str(e)}")
        return ScriptResponse(
            segments=[],
            total_duration=0.0
        )
