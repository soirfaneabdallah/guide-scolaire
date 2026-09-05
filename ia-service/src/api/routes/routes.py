# ============================================================
# FICHIER: ia-service/src/api/routes.py
# DESCRIPTION: Routes API pour le service IA
# ============================================================

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import logging
import traceback

from src.services.llm.qwen import QwenLLM
from src.prompts import build_prompt, build_video_prompt  # ✅ Import depuis prompts

logger = logging.getLogger(__name__)

router = APIRouter()


# ============================================================
# MODÈLES
# ============================================================

class AskRequest(BaseModel):
    question: str
    level: str = "3ème"
    subject: Optional[str] = None
    history: Optional[List[Dict[str, str]]] = []
    session_id: Optional[str] = None
    turn_number: int = 1


class AskResponse(BaseModel):
    response: str
    intent: str
    subject: str
    wants_video: bool = False
    concept: Optional[str] = None
    needs_video_generation: bool = False
    video_prompt: Optional[str] = None


class VideoRequest(BaseModel):
    concept: str
    level: str = "3ème"
    subject: Optional[str] = None
    duration_sec: int = 90
    history: Optional[List[Dict[str, str]]] = []


# ============================================================
# ROUTES
# ============================================================

@router.post("/ask")
async def ask(request: AskRequest):
    """Point d'entrée principal pour les questions."""
    try:
        logger.info(f"📝 Question: {request.question[:50]}...")
        logger.info(f"📚 Niveau: {request.level}")
        
        # Construire les prompts
        system_prompt, user_prompt = build_prompt(
            question=request.question,
            level=request.level,
            subject=request.subject or "général",
            history_summary="\n".join([f"{m.get('role', 'user')}: {m.get('content', '')}" for m in (request.history or [])[-6:]]),
            turn_number=request.turn_number
        )
        
        # Initialiser Qwen
        llm = QwenLLM()
        llm.set_user_level(request.level)
        
        # Générer la réponse
        response = llm.generate(
            prompt=user_prompt,
            system_message=system_prompt,
            max_new_tokens=512
        )
        
        # Détecter l'intention vidéo
        intent = llm.detect_video_intent(request.question)
        
        return {
            "response": response,
            "intent": request.question,
            "subject": request.subject or "général",
            "wants_video": intent.get("wants_video", False),
            "concept": intent.get("concept"),
            "needs_video_generation": intent.get("wants_video", False) and intent.get("confidence", 0.0) >= 0.6,
            "video_prompt": llm._generate_video_prompt(request.question, intent.get("concept", "le concept")) if intent.get("wants_video", False) else None
        }
        
    except Exception as e:
        logger.error(f"❌ Erreur: {str(e)}")
        logger.error(traceback.format_exc())
        return {
            "response": f"Je n'ai pas pu générer une réponse. Erreur: {str(e)}",
            "error": str(e)
        }


@router.post("/video_prompt")
async def generate_video_prompt(request: VideoRequest):
    """Génère un prompt spécialisé pour la vidéo."""
    try:
        system_prompt, user_prompt = build_video_prompt(
            conversation_history=request.history or [],
            concept=request.concept,
            level=request.level,
            subject=request.subject or "général",
            duration_sec=request.duration_sec
        )
        
        return {
            "system_prompt": system_prompt,
            "user_prompt": user_prompt,
            "concept": request.concept,
            "level": request.level
        }
        
    except Exception as e:
        logger.error(f"❌ Erreur video: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/test")
async def test():
    return {"message": "API fonctionne correctement !"}


@router.get("/status")
async def status():
    try:
        llm = QwenLLM()
        return {
            "status": "ok",
            "model": "Qwen/Qwen2.5-0.5B-Instruct",
            "device": llm.device
        }
    except Exception as e:
        return {
            "status": "error",
            "error": str(e)
        }