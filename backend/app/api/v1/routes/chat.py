# backend/app/api/v1/routes/chat.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional, List, Dict, Any
import httpx
import logging
import time
import traceback

from ....core.database import get_db
from ....core.dependencies import get_current_active_user
from ....models.user import User
from ....models.subject import Subject
from ....services.ia_client import IAClient
from ....repositories.chat_repository import ChatRepository
from ....repositories.subject_repository import SubjectRepository
from ....api.v1.schemas.chat_schemas import (
    AskRequest,
    AskResponse,
    ChatHistoryResponse,
    ChatMessageResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/chat", tags=["Chat"])


# ============================================================
#  POSER UNE QUESTION
# ============================================================

@router.post("/ask", response_model=AskResponse)
async def ask_question(
    request: AskRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Endpoint pour poser une question à l'assistant IA.
    Sauvegarde automatiquement la conversation.
    """
    chat_repo = ChatRepository(db)
    subject_repo = SubjectRepository(db)

    try:
        # ✅ 1. Récupérer la matière
        subject = None
        
        # ✅ Vérifier si subject_id est fourni (SI LE CHAMP EXISTE DANS AskRequest)
        if hasattr(request, 'subject_id') and request.subject_id:
            subject = subject_repo.get_subject_by_id(request.subject_id)
        
        # ✅ Vérifier si subject_slug est fourni
        if not subject and hasattr(request, 'subject_slug') and request.subject_slug:
            subject = subject_repo.get_subject_by_slug(request.subject_slug)
        
        # ✅ Si matière non trouvée, utiliser la matière par défaut
        if not subject:
            default_subjects = subject_repo.get_default_subjects()
            if default_subjects:
                subject = default_subjects[0]
            else:
                # ✅ Créer une matière par défaut si aucune n'existe
                from ....models.subject import Subject
                subject = Subject(
                    name="Général",
                    slug="general",
                    is_default=True,
                    icon="📚",
                    color="#4F46E5"
                )
                db.add(subject)
                db.commit()
                db.refresh(subject)

        # ✅ 2. Sauvegarder la question de l'utilisateur
        chat_repo.save_message(
            user_id=current_user.id,
            subject_id=subject.id,
            content=request.question,
            is_user=True,
            level=request.level,
        )

        # ✅ 3. Appeler le service IA
        start_time = time.time()
        
        try:
            # ✅ Créer une nouvelle instance du client IA
            ia_client = IAClient()
            
            result = await ia_client.ask(
                question=request.question,
                level=request.level,
            )
            
            processing_time = (time.time() - start_time) * 1000  # en ms
            
            # ✅ Récupérer la réponse (le service IA retourne "response", pas "answer")
            answer = result.get("response") or result.get("answer") or "Je n'ai pas pu générer une réponse."
            
            # ✅ Récupérer le modèle utilisé
            model_used = result.get("model_used") or result.get("model") or "unknown"
            
        except httpx.TimeoutException:
            logger.error("⏰ Timeout du service IA")
            answer = "Le service IA met trop de temps à répondre. Veuillez réessayer."
            model_used = "timeout"
            processing_time = 0
            
        except httpx.ConnectError:
            logger.error("🔌 Connexion au service IA impossible")
            answer = "Le service IA n'est pas disponible. Veuillez réessayer plus tard."
            model_used = "unavailable"
            processing_time = 0
            
        except Exception as e:
            logger.error(f"❌ Erreur IA: {str(e)}")
            answer = "Je n'ai pas pu générer une réponse. Veuillez réessayer."
            model_used = "error"
            processing_time = 0

        # ✅ 4. Sauvegarder la réponse de l'IA
        chat_repo.save_message(
            user_id=current_user.id,
            subject_id=subject.id,
            content=answer,
            is_user=False,
            level=request.level,
            model_used=model_used,
            processing_time=int(processing_time),
        )

        # ✅ 5. Retourner la réponse
        return AskResponse(
            answer=answer,
            level=request.level,
            model=model_used,
            processing_time=processing_time / 1000,
            subject_slug=subject.slug,
        )

    except Exception as e:
        logger.error(f"❌ ERREUR: {type(e).__name__}: {e}")
        logger.error(traceback.format_exc())
        
        # ✅ Fallback: sauvegarder un message d'erreur
        try:
            chat_repo.save_message(
                user_id=current_user.id,
                subject_id=subject.id if subject else 1,
                content="Je n'ai pas pu générer une réponse.",
                is_user=False,
                level=request.level,
                model_used="error",
                is_error=True,
            )
        except:
            pass
        
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors du traitement de la question: {str(e)}"
        )


# ============================================================
#  RÉCUPÉRER L'HISTORIQUE
# ============================================================

@router.get("/history/{subject_id}", response_model=ChatHistoryResponse)
async def get_chat_history(
    subject_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
    limit: int = 100,
    offset: int = 0,
):
    """
    Récupère l'historique des messages pour une matière donnée.
    """
    chat_repo = ChatRepository(db)
    subject_repo = SubjectRepository(db)

    # ✅ Récupérer la matière par ID
    subject = subject_repo.get_subject_by_id(subject_id)
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Matière avec l'ID {subject_id} non trouvée"
        )

    # ✅ Récupérer les messages
    messages = chat_repo.get_messages_for_subject(
        user_id=current_user.id,
        subject_id=subject.id,
        limit=limit,
        offset=offset,
    )

    # ✅ Construire la réponse
    return ChatHistoryResponse(
        subject_id=subject.id,
        subject_name=subject.name,
        subject_slug=subject.slug,
        messages=[
            ChatMessageResponse(
                id=m.id,
                content=m.content,
                is_user=m.is_user,
                is_error=getattr(m, 'is_error', False),
                level=m.level,
                model_used=m.model_used,
                created_at=m.created_at,
            )
            for m in messages
        ],
        total_messages=len(messages),
    )


# ============================================================
#  RÉCUPÉRER L'HISTORIQUE PAR SLUG (POUR COMPATIBILITÉ)
# ============================================================

@router.get("/history/slug/{subject_slug}", response_model=ChatHistoryResponse)
async def get_chat_history_by_slug(
    subject_slug: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
    limit: int = 100,
    offset: int = 0,
):
    """
    Récupère l'historique des messages pour une matière donnée (par slug).
    """
    chat_repo = ChatRepository(db)
    subject_repo = SubjectRepository(db)

    subject = subject_repo.get_subject_by_slug(subject_slug)
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Matière avec le slug '{subject_slug}' non trouvée"
        )

    messages = chat_repo.get_messages_for_subject(
        user_id=current_user.id,
        subject_id=subject.id,
        limit=limit,
        offset=offset,
    )

    return ChatHistoryResponse(
        subject_id=subject.id,
        subject_name=subject.name,
        subject_slug=subject.slug,
        messages=[
            ChatMessageResponse(
                id=m.id,
                content=m.content,
                is_user=m.is_user,
                is_error=getattr(m, 'is_error', False),
                level=m.level,
                model_used=m.model_used,
                created_at=m.created_at,
            )
            for m in messages
        ],
        total_messages=len(messages),
    )


# ============================================================
#  SUPPRIMER L'HISTORIQUE
# ============================================================

@router.delete("/history/{subject_id}", status_code=status.HTTP_204_NO_CONTENT)
async def clear_chat_history(
    subject_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Supprime tout l'historique des messages pour une matière donnée.
    """
    chat_repo = ChatRepository(db)
    subject_repo = SubjectRepository(db)

    # ✅ Vérifier que la matière existe
    subject = subject_repo.get_subject_by_id(subject_id)
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Matière avec l'ID {subject_id} non trouvée"
        )

    # ✅ Supprimer l'historique
    deleted = chat_repo.clear_subject_history(current_user.id, subject.id)
    
    return None


# ============================================================
#  SUPPRIMER UN MESSAGE SPÉCIFIQUE
# ============================================================

@router.delete("/message/{message_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_message(
    message_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Supprime un message spécifique.
    """
    chat_repo = ChatRepository(db)
    
    # ✅ Vérifier que le message appartient à l'utilisateur
    message = chat_repo.get_message(message_id)
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Message avec l'ID {message_id} non trouvé"
        )
    
    if message.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous n'avez pas le droit de supprimer ce message"
        )
    
    chat_repo.delete_message(message_id)
    return None


# ============================================================
#  STATUS DU SERVICE IA
# ============================================================

@router.get("/ia/status")
async def get_ia_status():
    """
    Vérifie le statut du service IA.
    """
    try:
        ia_client = IAClient()
        status = await ia_client.get_status()
        return {
            "status": "ok",
            "ia_service": status
        }
    except Exception as e:
        return {
            "status": "error",
            "error": str(e)
        }


# ============================================================
#  HEALTH CHECK
# ============================================================

@router.get("/health")
async def health_check():
    """
    Vérifie la santé du service chat.
    """
    try:
        ia_client = IAClient()
        health = await ia_client.check_health()
        return {
            "status": "ok",
            "service": "chat",
            "ia_service": health
        }
    except Exception as e:
        return {
            "status": "error",
            "service": "chat",
            "error": str(e)
        }