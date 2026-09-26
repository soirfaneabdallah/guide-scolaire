# ============================================================
# FICHIER: ia-service/src/schemas/video_schemas.py
# DESCRIPTION: Schémas pour la génération de vidéos
# ============================================================

from pydantic import BaseModel, Field
from typing import Optional, List


# ============================================================
# SCÈNE
# ============================================================

class Scene(BaseModel):
    """Une scène d'une vidéo pédagogique"""
    id: str
    order: int
    title: str
    concept: str
    manim_code: str
    narration: str
    estimated_duration: int = 15


# ============================================================
# SCRIPT
# ============================================================

class ScriptRequest(BaseModel):
    """Requête de génération de script"""
    prompt: str = Field(..., min_length=3, max_length=500)
    subject: Optional[str] = Field(None, description="Matière")
    level: str = Field("4ème", description="Niveau scolaire")
    language: str = Field("fr", description="Langue")
    target_duration: int = Field(120, description="Durée cible (secondes)")

    class Config:
        json_schema_extra = {
            "example": {
                "prompt": "Explique le théorème de Pythagore",
                "subject": "Mathématiques",
                "level": "4ème",
                "language": "fr",
                "target_duration": 120,
            }
        }


class ScriptResponse(BaseModel):
    """Réponse de génération de script"""
    success: bool
    title: str
    description: Optional[str] = None
    scenes: List[Scene] = []
    total_duration: int = 0
    error: Optional[str] = None


# ============================================================
# TTS
# ============================================================

class TTSRequest(BaseModel):
    """Requête de synthèse vocale"""
    text: str = Field(..., min_length=1)
    voice: str = Field("fr-FR-DeniseNeural")
    speed: float = Field(1.0, ge=0.5, le=2.0)


class TTSResponse(BaseModel):
    """Réponse de synthèse vocale"""
    success: bool
    audio_url: Optional[str] = None
    duration: float = 0.0
    error: Optional[str] = None


# ============================================================
# MANIM
# ============================================================

class ManimRenderRequest(BaseModel):
    """Requête de rendu Manim"""
    code: str = Field(..., min_length=10)
    scene_name: str = Field("MainScene")


class ManimRenderResponse(BaseModel):
    """Réponse de rendu Manim"""
    success: bool
    video_url: Optional[str] = None
    duration: float = 0.0
    error: Optional[str] = None