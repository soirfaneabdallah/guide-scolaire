# ia-service/src/api/routes.py

import time
import logging
from fastapi import APIRouter, HTTPException, status
from .schemas import AskRequest, AskResponse
from ..llm.qwen import QwenLLM
from ..llm.prompt import build_prompt
import os

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["IA"])

MODEL_NAME = os.getenv("MODEL_NAME", "Qwen/Qwen2.5-0.5B-Instruct")
MAX_LENGTH = int(os.getenv("MAX_LENGTH", "2048"))
TEMPERATURE = float(os.getenv("TEMPERATURE", "0.3"))  # 👈 Réduit
TOP_P = float(os.getenv("TOP_P", "0.9"))

try:
    llm = QwenLLM(
        model_name=MODEL_NAME,
        max_length=MAX_LENGTH,
        temperature=TEMPERATURE,
        top_p=TOP_P,
    )
    logger.info("✅ Modèle chargé avec succès")
except Exception as e:
    logger.error(f"❌ Erreur lors du chargement du modèle: {e}")
    llm = None

@router.post("/ask", response_model=AskResponse)
async def ask_question(request: AskRequest):
    if llm is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Le modèle n'est pas disponible"
        )
    
    try:
        start_time = time.time()
        
        # 👇 Détection des questions simples
        question = request.question.strip()
        if len(question.split()) < 4:
            simple_responses = [
                "Bonjour ! 👋 Je suis ton assistant pédagogique. Comment puis-je t'aider aujourd'hui ? N'hésite pas à me poser une question sur une matière spécifique (maths, français, physique, etc.) ou sur un sujet qui te pose problème.",
                "Salut ! 😊 Je suis là pour t'aider à comprendre tes cours. Pose-moi une question sur n'importe quelle matière, je ferai de mon mieux pour t'expliquer clairement.",
                "Bonjour ! 🌟 Je suis ton professeur particulier numérique. Si tu as besoin d'aide sur une notion, un exercice ou une explication, je suis là pour toi !"
            ]
            import random
            return AskResponse(
                answer=random.choice(simple_responses),
                level=request.level,
                model=MODEL_NAME,
                processing_time=0.1,
            )
        
        prompt = build_prompt(
            question=request.question,
            level=request.level,
        )
        
        # 👇 Réduire max_new_tokens pour accélérer
        response = llm.generate(
            prompt,
            max_new_tokens=256,  # 👈 Réduit
            temperature=request.temperature if hasattr(request, 'temperature') else TEMPERATURE,
        )
        
        processing_time = time.time() - start_time
        
        # 👇 Nettoyer la réponse si elle contient des balises
        response = response.replace("<|im_start|>", "").replace("<|im_end|>", "").strip()
        
        logger.info(f"📝 Question: {request.question[:50]}...")
        logger.info(f"📚 Niveau: {request.level}")
        logger.info(f"⏱️ Temps: {processing_time:.2f}s")
        
        return AskResponse(
            answer=response,
            level=request.level,
            model=MODEL_NAME,
            processing_time=processing_time,
        )
        
    except Exception as e:
        logger.error(f"❌ Erreur: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la génération: {str(e)}"
        )