# backend/app/api/v1/schemas/chat_schemas.py

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

# ============================================================
#  REQUÊTE /ask
# ============================================================
class AskRequest(BaseModel):
    question: str = Field(..., min_length=1, max_length=2000)
    level: str = "3ème"
    subject_id: Optional[int] = None  # 👈 Utiliser l'ID au lieu du slug


# ============================================================
#  RÉPONSE DE /ask
# ============================================================
class AskResponse(BaseModel):
    answer: str
    level: str
    model: str
    processing_time: Optional[float] = None
    subject_id: Optional[int] = None  # 👈 Utiliser l'ID au lieu du slug


# ============================================================
#  HISTORIQUE DES MESSAGES
# ============================================================
class ChatMessageResponse(BaseModel):
    id: int
    content: str
    is_user: bool
    is_error: bool
    level: Optional[str]
    model_used: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

class ChatHistoryResponse(BaseModel):
    subject_id: int
    subject_name: str
    subject_slug: str
    messages: List[ChatMessageResponse]
    total_messages: int