# ============================================================
# FICHIER: backend/app/services/assembly/__init__.py
# DESCRIPTION: Export des services d'assemblage
# ============================================================

from .base_assembler import BaseAssembler
from .ffmpeg_assembler import FFmpegAssembler
from .video_composer import VideoComposer

__all__ = [
    "BaseAssembler",
    "FFmpegAssembler",
    "VideoComposer",
]