# backend/app/api/v1/routes/chat.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional
from pydantic import BaseModel, Field
import httpx

# ✅ CORRECTION DES IMPORTS
from ....core.database import get_db
from ....core.dependencies import get_current_active_user
from ....models.user import User
from ....services.ai_service import IAClient
from ..schemas.auth_schemas import UserResponse  # ✅ Chemin corrigé

router = APIRouter(prefix="/chat", tags=["Chat"])

# Modèles Pydantic
class AskRequest(BaseModel):
    question: str = Field(..., min_length=1, max_length=2000)
    level: Optional[str] = "3ème"

class AskResponse(BaseModel):
    answer: str
    level: str
    model: str
    processing_time: Optional[float] = None

# Client IA
ia_client = IAClient()

@router.post("/ask", response_model=AskResponse)
async def ask_question(
    request: AskRequest,
    #current_user: User = Depends(get_current_active_user),
):
    """
    Endpoint pour poser une question à l'assistant IA.
    """
    try:
        # Appel au service IA
        result = await ia_client.ask(
            question=request.question,
            level=request.level,
        )
        
        return AskResponse(
            answer=result["answer"],
            level=result["level"],
            model=result["model"],
            processing_time=result.get("processing_time"),
        )
        
    except httpx.TimeoutException:
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail="Le service IA ne répond pas"
        )
    except httpx.HTTPStatusError as e:
        raise HTTPException(
            status_code=e.response.status_code,
            detail=e.response.text
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )