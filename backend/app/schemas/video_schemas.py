# ============================================================
# FICHIER: backend/app/schemas/video_schemas.py
# DESCRIPTION: Schémas Pydantic pour les vidéos
# ============================================================

from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum


# ============================================================
# ENUMS
# ============================================================

class JobStatus(str, Enum):
    """Statuts possibles d'un job de génération vidéo"""
    PENDING = "pending"
    GENERATING_CODE = "generating_code"
    RENDERING = "rendering"
    SYNTHESIZING = "synthesizing"
    ASSEMBLING = "assembling"
    READY = "ready"
    FAILED = "failed"
    CANCELLED = "cancelled"


# ============================================================
# VIDEO JOB
# ============================================================

class VideoJobResponse(BaseModel):
    """Réponse complète d'un job de génération"""
    id: str
    user_id: int
    prompt_context: str
    concept: Optional[str] = None
    
    # Statut
    status: JobStatus
    progress: int = 0
    
    # Durées
    estimated_duration_seconds: int = 360
    actual_duration_seconds: Optional[int] = None
    elapsed_seconds: int = 0
    
    # Résultats
    video_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    error_message: Optional[str] = None
    error_code: Optional[str] = None
    
    # Métadonnées
    generator_version: str = "1.0.0"
    engine_used: str = "manim"
    llm_model_used: str = "mistral"
    tts_engine_used: str = "edge"
    metadata: Dict[str, Any] = {}
    
    # Fallback
    fallback_used: bool = False
    error_retries: int = 0
    max_retries: int = 2
    
    # Cache
    is_cached: bool = False
    cache_key: Optional[str] = None
    
    # Timestamps
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    started_at: Optional[str] = None
    completed_at: Optional[str] = None
    
    model_config = ConfigDict(from_attributes=True)


# ============================================================
# VIDEO SCRIPT
# ============================================================

class VideoScriptResponse(BaseModel):
    """Réponse pour un script vidéo"""
    id: str
    title: str
    description: Optional[str] = None
    subject_id: int
    level: str
    chapter: Optional[str] = None
    tags: List[str] = []
    thumbnail_url: Optional[str] = None
    scene_count: int = 0
    estimated_duration_seconds: int = 0
    views_count: int = 0
    rating_average: float = 0.0
    rating_count: int = 0
    is_validated: bool = False
    is_generated: bool = True
    version: int = 1
    created_at: Optional[str] = None
    user_progress: Optional[Dict[str, Any]] = None

    model_config = ConfigDict(from_attributes=True)


class VideoScriptDetailResponse(VideoScriptResponse):
    """Réponse détaillée avec les scènes"""
    scenes: List[Dict[str, Any]] = []


class VideoScriptCreateRequest(BaseModel):
    """Requête de création d'un script vidéo"""
    prompt: str = Field(..., min_length=3, max_length=500)
    subject_id: int
    level: Optional[str] = None
    duration_seconds: int = Field(180, ge=30, le=600)


# ============================================================
# LISTE DE VIDÉOS
# ============================================================

class VideoListResponse(BaseModel):
    """Réponse pour une liste de vidéos"""
    videos: List[VideoScriptResponse]
    total: int
    page: int
    page_size: int
    has_next: bool


# ============================================================
# CHAPITRES
# ============================================================

class ChapterResponse(BaseModel):
    """Réponse pour un chapitre"""
    id: int
    name: str
    slug: str
    subject_id: int
    level: Optional[str] = None
    icon: Optional[str] = None
    color: Optional[str] = None
    description: Optional[str] = None
    video_count: int = 0
    completed_count: int = 0

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# PROGRESSION
# ============================================================

class UserProgressResponse(BaseModel):
    """Réponse pour la progression"""
    script_id: str
    last_position_seconds: float = 0.0
    watched_seconds: float = 0.0
    completed: bool = False
    liked: Optional[bool] = None
    rating: Optional[int] = None
    progress_percentage: float = 0.0

    model_config = ConfigDict(from_attributes=True)


class UpdateProgressRequest(BaseModel):
    """Requête de mise à jour de la progression"""
    last_position_seconds: float
    watched_seconds: float
    completed: Optional[bool] = None


# ============================================================
# SIGNALEMENT
# ============================================================

class VideoReportRequest(BaseModel):
    """Requête de signalement"""
    scene_id: Optional[str] = None
    reason: str = Field(..., min_length=3, max_length=100)
    comment: Optional[str] = None


class VideoReportResponse(BaseModel):
    """Réponse de signalement"""
    id: str
    script_id: str
    scene_id: Optional[str] = None
    reason: str
    status: str
    created_at: str

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# GÉNÉRATION DE VIDÉO
# ============================================================

class VideoGenerationRequest(BaseModel):
    """Requête de génération d'une vidéo"""
    prompt: str = Field(..., min_length=3, max_length=500)
    subject_id: Optional[int] = None
    level: Optional[str] = None
    duration_seconds: int = Field(180, ge=30, le=600)
    language: str = "fr"


class VideoGenerationResponse(BaseModel):
    """Réponse après lancement d'une génération"""
    job_id: str
    status: JobStatus
    quota_remaining_seconds: int
    quota_remaining_minutes: float
    estimated_time_seconds: int
    message: str
    video_url: Optional[str] = None


# ============================================================
# CACHE
# ============================================================

class VideoCacheRequest(BaseModel):
    """Requête de vérification de cache"""
    concept: str = Field(..., min_length=2, max_length=100)
    level: Optional[str] = None
    language: str = "fr"


class VideoCacheResponse(BaseModel):
    """Réponse de cache"""
    cache_key: str
    concept: str
    level: Optional[str] = None
    video_url: str
    thumbnail_url: Optional[str] = None
    duration_seconds: Optional[int] = None
    views_count: int = 0
    created_at: Optional[str] = None
    is_expired: bool = False


# ============================================================
# QUOTA
# ============================================================

class VideoQuotaResponse(BaseModel):
    """Réponse pour le quota"""
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


# ============================================================
# PROGRESSION DE GÉNÉRATION
# ============================================================

class GenerationProgressResponse(BaseModel):
    """Réponse de progression détaillée"""
    job_id: str
    status: JobStatus
    progress: int
    step: str
    elapsed_seconds: int
    estimated_remaining_seconds: int
    message: str


# ============================================================
# MANIM (INTERNE)
# ============================================================

class ManimGenerationResult(BaseModel):
    """Résultat de génération Manim"""
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
    segments: List[NarrationSegment] = []
    total_duration: float = 0.0