# backend/app/api/v1/schemas/chat_schemas.py

from pydantic import BaseModel, Field
from typing import Optional, List

# ============================================================
#  REQUÊTE /ask
# ============================================================
class AskRequest(BaseModel):
    """Requête pour poser une question à l'assistant IA."""
    
    question: str = Field(
        ...,
        min_length=1,
        max_length=2000,
        description="Question de l'élève"
    )
    level: str = Field(
        default="3ème",
        description="Niveau de l'élève (6ème, 5ème, 4ème, 3ème, Seconde, Première, Terminale)"
    )
    
    class Config:
        json_schema_extra = {
            "example": {
                "question": "Comment résoudre une équation du premier degré ?",
                "level": "4ème"
            }
        }


# ============================================================
#  RÉPONSE DE /ask
# ============================================================
class AskResponse(BaseModel):
    """Réponse de l'assistant IA."""
    
    answer: str = Field(..., description="Réponse générée par l'IA")
    level: str = Field(..., description="Niveau utilisé pour la réponse")
    model: str = Field(..., description="Nom du modèle utilisé")
    processing_time: Optional[float] = Field(
        None,
        description="Temps de traitement en secondes"
    )
    tokens_used: Optional[int] = Field(
        None,
        description="Nombre approximatif de tokens utilisés"
    )
    
    class Config:
        json_schema_extra = {
            "example": {
                "answer": "Pour résoudre une équation du premier degré...",
                "level": "4ème",
                "model": "Qwen/Qwen2.5-0.5B-Instruct",
                "processing_time": 2.34,
                "tokens_used": 87
            }
        }


# ============================================================
#  RÉPONSE D'ERREUR (optionnelle)
# ============================================================
class ErrorResponse(BaseModel):
    """Réponse en cas d'erreur."""
    
    detail: str = Field(..., description="Message d'erreur")
    error_code: Optional[str] = Field(None, description="Code d'erreur")