# ============================================================
# FICHIER: backend/app/core/constants/video_constants.py
# DESCRIPTION: Constantes pour la fonctionnalite video
# ============================================================

# ============================================================
# QUOTAS
# ============================================================

DAILY_QUOTA_SECONDS = 1800  # 30 minutes
WARNING_THRESHOLD_SECONDS = 300  # 5 minutes


# ============================================================
# DUREES
# ============================================================

MAX_VIDEO_DURATION_SECONDS = 600  # 10 minutes
MIN_VIDEO_DURATION_SECONDS = 30  # 30 secondes
DEFAULT_VIDEO_DURATION_SECONDS = 180  # 3 minutes


# ============================================================
# GENERATION
# ============================================================

MAX_RETRIES = 2
MANIM_TIMEOUT_SECONDS = 300  # 5 minutes
TTS_TIMEOUT_SECONDS = 60


# ============================================================
# QUALITE
# ============================================================

VIDEO_QUALITY = "medium"  # low, medium, high
VIDEO_FPS = 30
VIDEO_RESOLUTION = "720p"


# ============================================================
# CACHE
# ============================================================

CACHE_TTL_DAYS = 30
PRE_GENERATE_POPULAR = True


# ============================================================
# MOTEURS
# ============================================================

PREFERRED_GENERATORS = ["manim", "matplotlib"]
PREFERRED_TTS_ENGINES = ["edge", "coqui"]


# ============================================================
# MESSAGES
# ============================================================

STEP_MESSAGES = {
    "pending": "Preparation de la generation...",
    "generating_code": "Generation du code d'animation...",
    "rendering": "Rendu de l'animation (peut prendre plusieurs minutes)...",
    "synthesizing": "Synthese vocale en cours...",
    "assembling": "Montage final...",
    "ready": "Video prete !",
    "failed": "Une erreur est survenue",
    "cancelled": "Job annule"
}