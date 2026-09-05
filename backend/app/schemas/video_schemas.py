# ============================================================
# FICHIER: backend/app/schemas/video_schemas.py
# DESCRIPTION: Schemas Pydantic pour la fonctionnalite video
# ============================================================

from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List, Dict, Any
from enum import Enum


class JobStatus(str, Enum):
    """Statuts possibles d'un job"""
    PENDING = "pending"
    GENERATING_CODE = "generating_code"
    RENDERING = "rendering"
    SYNTHESIZING = "synthesizing"
    ASSEMBLING = "assembling"
    READY = "ready"
    FAILED = "failed"
    CANCELLED = "cancelled"


# ============================================================
# REQUESTS
# ============================================================

class VideoGenerationRequest(BaseModel):
    """Requete de generation video"""
    prompt: str = Field(..., min_length=3, max_length=1000)
    concept: Optional[str] = Field(None, min_length=2, max_length=100)
    level: Optional[str] = Field(None, min_length=2, max_length=50)
    duration_seconds: Optional[int] = Field(180, ge=30, le=600)
    language: str = Field("fr", min_length=2, max_length=5)
    
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "prompt": "Explique-moi le theoreme de Pythagore avec une animation",
                "concept": "Theoreme de Pythagore",
                "level": "3eme",
                "duration_seconds": 180,
                "language": "fr"
            }
        }
    )


class VideoCacheRequest(BaseModel):
    """Requete de verification cache"""
    concept: str = Field(..., min_length=2, max_length=100)
    level: Optional[str] = Field(None, min_length=2, max_length=50)
    language: str = Field("fr", min_length=2, max_length=5)


# ============================================================
# RESPONSES
# ============================================================

class VideoJobResponse(BaseModel):
    """Reponse avec les details d'un job"""
    id: str
    user_id: int
    prompt_context: str
    concept: Optional[str]
    status: JobStatus
    progress: int
    estimated_duration_seconds: int
    actual_duration_seconds: Optional[int]
    elapsed_seconds: int
    video_url: Optional[str]
    thumbnail_url: Optional[str]
    error_message: Optional[str]
    fallback_used: bool
    is_cached: bool
    created_at: Optional[str]
    completed_at: Optional[str]
    
    model_config = ConfigDict(from_attributes=True)


class VideoQuotaResponse(BaseModel):
    """Reponse avec les details du quota"""
    id: int
    user_id: int
    tier: str
    daily_limit_seconds: int
    daily_limit_minutes: float
    used_seconds_today: int
    used_minutes_today: float
    remaining_seconds: int
    remaining_minutes: float
    used_percentage: float
    can_generate: bool


class VideoGenerationResponse(BaseModel):
    """Reponse apres lancement d'une generation"""
    job_id: str
    status: JobStatus
    quota_remaining_seconds: int
    quota_remaining_minutes: float
    estimated_time_seconds: int
    message: str
    video_url: Optional[str] = None


class GenerationProgressResponse(BaseModel):
    """Reponse de progression detaillee"""
    job_id: str
    status: JobStatus
    progress: int
    step: str
    elapsed_seconds: int
    estimated_remaining_seconds: int
    message: str


# ============================================================
# INTERNAL (pour les workers)
# ============================================================

class ManimGenerationResult(BaseModel):
    """Resultat de generation Manim"""
    code: str
    success: bool
    error: Optional[str] = None
    duration_seconds: Optional[int] = None


class NarrationSegment(BaseModel):
    """Segment de narration"""
    start: float
    end: float
    text: str


class NarrationScript(BaseModel):
    """Script de narration complet"""
    segments: List[NarrationSegment]
    total_duration: float