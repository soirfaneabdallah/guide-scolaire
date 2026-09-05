# ============================================================
# FICHIER: ia-service/src/models/schemas.py
# DESCRIPTION: Schemas Pydantic pour le service IA
# ============================================================

from pydantic import BaseModel, Field
from typing import Optional, List


# ============================================================
# MANIM GENERATION
# ============================================================

class ManimGenerationResult(BaseModel):
    """Resultat de generation Manim"""
    success: bool
    code: str = ""
    error: Optional[str] = None
    duration_seconds: Optional[int] = None


class NarrationSegment(BaseModel):
    """Segment de narration"""
    start: float
    end: float
    text: str


class NarrationScript(BaseModel):
    """Script de narration complet"""
    segments: List[NarrationSegment] = []
    total_duration: float = 0.0


# ============================================================
# MANIM REQUEST/RESPONSE
# ============================================================

class ManimRequest(BaseModel):
    """Requete pour la generation de code Manim"""
    prompt: str = Field(..., min_length=3, max_length=1000)
    concept: Optional[str] = Field(None, min_length=2, max_length=100)
    level: Optional[str] = Field(None, min_length=2, max_length=50)
    duration: int = Field(180, ge=30, le=600)


class ManimResponse(BaseModel):
    """Reponse de generation Manim"""
    success: bool
    code: str = ""
    error: Optional[str] = None
    duration_seconds: Optional[int] = None


# ============================================================
# SCRIPT REQUEST/RESPONSE
# ============================================================

class ScriptRequest(BaseModel):
    """Requete pour la generation de script"""
    code: str = Field(..., min_length=10)
    concept: str = Field(..., min_length=2)
    level: str = Field("college", min_length=2)


class ScriptResponse(BaseModel):
    """Reponse de generation de script"""
    segments: List[NarrationSegment] = []
    total_duration: float = 0.0


# ============================================================
# INTENT DETECTION
# ============================================================

class IntentRequest(BaseModel):
    """Requete pour la detection d'intention"""
    text: str = Field(..., min_length=1)


class IntentResponse(BaseModel):
    """Reponse de detection d'intention"""
    wants_video: bool = False
    concept: Optional[str] = None
    confidence: float = Field(0.0, ge=0.0, le=1.0)