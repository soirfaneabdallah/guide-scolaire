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
from src.prompts import build_prompt, build_video_prompt

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
    model_used: str = "qwen"


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
    """
    Point d'entrée principal pour les questions.
    Maintient le contexte grâce à l'historique.
    """
    try:
        logger.info(f"📝 Question: {request.question[:50]}...")
        logger.info(f"📚 Niveau: {request.level}")
        logger.info(f"📖 Matière: {request.subject or 'général'}")
        logger.info(f"📋 Historique: {len(request.history or [])} messages")
        
        # ✅ Initialiser Qwen avec le niveau
        llm = QwenLLM()
        llm.set_user_level(request.level)
        
        # ✅ RECHARGER L'HISTORIQUE DANS QWEN
        if request.history:
            logger.info(f"🔄 Rechargement de {len(request.history)} messages d'historique")
            for msg in request.history:
                role = msg.get("role", "user")
                content = msg.get("content", "")
                if content:
                    llm.add_to_history(role, content)
        
        # ✅ Construire les prompts avec le contexte
        history_summary = ""
        if request.history:
            # Résumé des derniers messages pour le prompt
            recent = request.history[-6:]
            history_lines = []
            for msg in recent:
                role = "Élève" if msg.get("role") == "user" else "Professeur"
                content = msg.get("content", "")[:200]
                history_lines.append(f"{role}: {content}")
            history_summary = "\n".join(history_lines)
        
        system_prompt, user_prompt = build_prompt(
            question=request.question,
            level=request.level,
            subject=request.subject or "général",
            history_summary=history_summary,
            turn_number=request.turn_number
        )
        
        # ✅ Générer la réponse avec le contexte
        response = llm.generate(
            prompt=user_prompt,
            system_message=system_prompt,
            max_new_tokens=512
        )
        
        # ✅ Détecter l'intention vidéo
        intent = llm.detect_video_intent(request.question)
        
        logger.info(f"✅ Réponse générée: {response[:50]}...")
        
        return {
            "response": response,
            "intent": request.question,
            "subject": request.subject or "général",
            "wants_video": intent.get("wants_video", False),
            "concept": intent.get("concept"),
            "needs_video_generation": intent.get("wants_video", False) and intent.get("confidence", 0.0) >= 0.6,
            "video_prompt": llm._generate_video_prompt(request.question, intent.get("concept", "le concept")) if intent.get("wants_video", False) else None,
            "model_used": "qwen"
        }
        
    except Exception as e:
        logger.error(f"❌ Erreur: {str(e)}")
        logger.error(traceback.format_exc())
        return {
            "response": f"Je n'ai pas pu générer une réponse. Erreur: {str(e)}",
            "error": str(e),
            "model_used": "error"
        }


@router.post("/video_prompt")
async def generate_video_prompt(request: VideoRequest):
    """
    Génère un prompt spécialisé pour la vidéo.
    """
    try:
        logger.info(f"🎬 Demande vidéo: {request.concept}")
        logger.info(f"📚 Niveau: {request.level}")
        
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
    """Route de test pour vérifier que l'API fonctionne."""
    return {"message": "API fonctionne correctement !"}


@router.get("/status")
async def status():
    """
    Vérifie le statut du service IA et du modèle.
    """
    try:
        llm = QwenLLM()
        return {
            "status": "ok",
            "model": "Qwen/Qwen2.5-0.5B-Instruct",
            "device": llm.device,
            "model_loaded": llm._model_loaded if hasattr(llm, '_model_loaded') else True
        }
    except Exception as e:
        return {
            "status": "error",
            "error": str(e)
        }


@router.get("/health")
async def health():
    """
    Health check du service IA.
    """
    return {"status": "healthy", "service": "ia-service"}


@router.post("/clear")
async def clear_session(request: dict):
    """
    Efface le contexte d'une session.
    """
    session_id = request.get("session_id")
    if session_id:
        logger.info(f"🧹 Session effacée: {session_id}")
        return {"message": f"Session {session_id} effacée"}
    return {"message": "Aucune session spécifiée"}


# ============================================================
# ROUTE POUR LE RAG (à développer)
# ============================================================

@router.post("/rag/search")
async def rag_search(request: dict):
    """
    Recherche des documents dans la base de connaissances.
    """
    query = request.get("query", "")
    filters = request.get("filters", {})
    top_k = request.get("top_k", 5)
    
    logger.info(f"📚 Recherche RAG: {query}")
    logger.info(f"   Filtres: {filters}")
    
    # TODO: Implémenter la recherche réelle
    # Pour l'instant, simulation
    results = [
        {
            "content": f"Information sur '{query}' trouvée dans la base de connaissances.",
            "source": "base_connaissances",
            "score": 0.95
        }
    ]
    
    return {
        "query": query,
        "results": results,
        "total": len(results)
    }