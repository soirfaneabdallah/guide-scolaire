# backend/app/api/v1/routes/chat.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional
import httpx
import logging
import time

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

ia_client = IAClient()


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
        # 1. Récupérer la matière (par ID ou slug)
        subject = None
        if request.subject_id:
            subject = subject_repo.get_subject_by_id(request.subject_id)
        
        if not subject and request.subject_slug:
            subject = subject_repo.get_subject_by_slug(request.subject_slug)

        # Si la matière n'existe pas, utiliser la matière par défaut
        if not subject:
            default_subjects = subject_repo.get_default_subjects()
            if default_subjects:
                subject = default_subjects[0]
            else:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Aucune matière trouvée"
                )

        # 2. Sauvegarder la question de l'utilisateur
        chat_repo.save_message(
            user_id=current_user.id,
            subject_id=subject.id,
            content=request.question,
            is_user=True,
            level=request.level,
        )

        # 3. Appeler le service IA
        start_time = time.time()
        result = await ia_client.ask(
            question=request.question,
            level=request.level,
        )
        processing_time = (time.time() - start_time) * 1000  # en ms

        answer = result.get("answer", "Je n'ai pas pu générer une réponse.")

        # 4. Sauvegarder la réponse de l'IA
        chat_repo.save_message(
            user_id=current_user.id,
            subject_id=subject.id,
            content=answer,
            is_user=False,
            level=request.level,
            model_used=result.get("model", "unknown"),
            processing_time=int(processing_time),
        )

        return AskResponse(
            answer=answer,
            level=request.level,
            model=result.get("model", "unknown"),
            processing_time=processing_time / 1000,
            subject_slug=subject.slug,
        )

    except httpx.TimeoutException:
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail="Le service IA ne répond pas. Veuillez réessayer."
        )
    except httpx.HTTPStatusError as e:
        raise HTTPException(
            status_code=e.response.status_code,
            detail=e.response.text
        )
    except Exception as e:
        logger.error(f"❌ ERREUR: {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


# ============================================================
#  RÉCUPÉRER L'HISTORIQUE PAR ID
# ============================================================
@router.get("/history/{subject_id}", response_model=ChatHistoryResponse)  # 👈 CHANGÉ : subject_id
async def get_chat_history(
    subject_id: int,  # 👈 CHANGÉ : int au lieu de str
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
    limit: int = 100,
    offset: int = 0,
):
    """
    Récupère l'historique des messages pour une matière donnée (par ID).
    """
    chat_repo = ChatRepository(db)
    subject_repo = SubjectRepository(db)

    # Récupérer la matière par ID
    subject = subject_repo.get_subject_by_id(subject_id)
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Matière avec l'ID {subject_id} non trouvée"
        )

    # Récupérer les messages
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
                is_error=m.is_error,
                level=m.level,
                model_used=m.model_used,
                created_at=m.created_at,
            )
            for m in messages
        ],
        total_messages=len(messages),
    )


# ============================================================
#  SUPPRIMER L'HISTORIQUE PAR ID
# ============================================================
@router.delete("/history/{subject_id}", status_code=status.HTTP_204_NO_CONTENT)  # 👈 CHANGÉ : subject_id
async def clear_chat_history(
    subject_id: int,  # 👈 CHANGÉ : int au lieu de str
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Supprime tout l'historique des messages pour une matière donnée (par ID).
    """
    chat_repo = ChatRepository(db)
    subject_repo = SubjectRepository(db)

    subject = subject_repo.get_subject_by_id(subject_id)
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Matière avec l'ID {subject_id} non trouvée"
        )

    deleted = chat_repo.clear_subject_history(current_user.id, subject.id)
    return None