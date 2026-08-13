# ia-service/src/api/schemas.py

from pydantic import BaseModel, Field
from typing import Optional, List

class AskRequest(BaseModel):
    """Requête pour /ask"""
    question: str = Field(..., min_length=1, max_length=2000, description="Question de l'élève")
    level: str = Field(default="3ème", description="Niveau de l'élève (6ème, 5ème, 4ème, 3ème, Seconde, Première, Terminale)")
    temperature: Optional[float] = Field(default=0.7, ge=0.0, le=1.0)
    max_tokens: Optional[int] = Field(default=512, ge=1, le=2048)

class AskResponse(BaseModel):
    """Réponse de /ask"""
    answer: str
    level: str
    model: str
    tokens_used: Optional[int] = None
    processing_time: Optional[float] = None