# ============================================================
# FICHIER: backend/app/services/assembly/video_composer.py
# DESCRIPTION: Composition avancee de videos (overlays, effets, sous-titres)
# ============================================================

import asyncio
from pathlib import Path
from typing import List, Optional, Dict, Any

from .base_assembler import BaseAssembler
from app.schemas.video_schemas import NarrationScript
from app.core.constants.video_constants import VIDEO_FPS

import logging

logger = logging.getLogger(__name__)


class VideoComposer(BaseAssembler):
    """
    Compositeur avance de videos.
    Ajoute des overlays, des effets, des sous-titres, etc.
    """
    
    @property
    def supported_formats(self) -> List[str]:
        return ["mp4", "webm"]
    
    async def assemble(
        self,
        video_path: str,
        audio_paths: List[str],
        script: NarrationScript,
        job_id: str,
        workspace: dict,
        **kwargs
    ) -> Optional[str]:
        """
        Assemble la video avec effets avances.
        """
        try:
            output_dir = Path(workspace["output"])
            output_dir.mkdir(parents=True, exist_ok=True)
            
            # Etape 1: Ajouter les sous-titres
            subtitled_path = output_dir / f"{job_id}_subtitled.mp4"
            await self._add_subtitles(
                video_path=video_path,
                script=script,
                output_path=str(subtitled_path)
            )
            
            # Etape 2: Ajouter l'audio
            final_path = output_dir / f"{job_id}_final.mp4"
            
            # Utiliser le FFmpegAssembler pour l'audio
            from .ffmpeg_assembler import FFmpegAssembler
            assembler = FFmpegAssembler()
            
            await assembler._assemble_video_audio(
                video_path=str(subtitled_path),
                audio_path=audio_paths[0] if audio_paths else "",
                output_path=str(final_path)
            )
            
            # Nettoyer les fichiers temporaires
            if subtitled_path != final_path:
                subtitled_path.unlink(missing_ok=True)
            
            logger.info(f"Job {job_id}: Video composee avec succes")
            return str(final_path)
            
        except Exception as e:
            logger.error(f"Job {job_id}: Erreur composition - {str(e)}")
            return None
    
    async def _add_subtitles(
        self,
        video_path: str,
        script: NarrationScript,
        output_path: str
    ):
        """
        Ajoute des sous-titres a la video.
        """
        # Creer un fichier SRT temporaire
        srt_path = Path(video_path).parent / "subtitles.srt"
        self._generate_srt_file(script, str(srt_path))
        
        cmd = [
            "ffmpeg",
            "-i", video_path,
            "-vf", f"subtitles={srt_path}",
            output_path,
            "-y"
        ]
        
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        stdout, stderr = await process.communicate()
        
        if process.returncode != 0:
            logger.warning(f"Erreur ajout sous-titres: {stderr.decode()}")
            # Fallback: copier la video sans sous-titres
            import shutil
            shutil.copy(video_path, output_path)
    
    def _generate_srt_file(self, script: NarrationScript, output_path: str):
        """
        Genere un fichier SRT a partir du script de narration.
        """
        with open(output_path, 'w', encoding='utf-8') as f:
            for i, segment in enumerate(script.segments, 1):
                start_time = self._format_srt_time(segment.start)
                end_time = self._format_srt_time(segment.end)
                
                f.write(f"{i}\n")
                f.write(f"{start_time} --> {end_time}\n")
                f.write(f"{segment.text}\n\n")
    
    def _format_srt_time(self, seconds: float) -> str:
        """
        Formate le temps pour le format SRT.
        """
        hours = int(seconds // 3600)
        minutes = int((seconds % 3600) // 60)
        secs = int(seconds % 60)
        millis = int((seconds % 1) * 1000)
        return f"{hours:02d}:{minutes:02d}:{secs:02d},{millis:03d}"
    
    def get_video_duration(self, video_path: str) -> int:
        """
        Recupere la duree d'une video en secondes.
        """
        from .ffmpeg_assembler import FFmpegAssembler
        assembler = FFmpegAssembler()
        return assembler.get_video_duration(video_path)
    
    def get_audio_duration(self, audio_path: str) -> float:
        """
        Recupere la duree d'un fichier audio en secondes.
        """
        from .ffmpeg_assembler import FFmpegAssembler
        assembler = FFmpegAssembler()
        return assembler.get_audio_duration(audio_path)