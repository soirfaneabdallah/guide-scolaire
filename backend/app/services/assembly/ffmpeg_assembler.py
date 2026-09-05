# ============================================================
# FICHIER: backend/app/services/assembly/ffmpeg_assembler.py
# DESCRIPTION: Assembleur utilisant FFmpeg pour le montage
# ============================================================

import subprocess
import asyncio
import os
import json
from pathlib import Path
from typing import List, Optional

from .base_assembler import BaseAssembler
from app.schemas.video_schemas import NarrationScript
from app.core.constants.video_constants import VIDEO_FPS, VIDEO_RESOLUTION

import logging

logger = logging.getLogger(__name__)


class FFmpegAssembler(BaseAssembler):
    """
    Assembleur utilisant FFmpeg pour l'encodage video.
    Supporte la concaténation audio, le mixage et l'encodage final.
    """
    
    def __init__(self, bitrate: str = "2000k", codec: str = "libx264"):
        self.bitrate = bitrate
        self.codec = codec
    
    @property
    def supported_formats(self) -> List[str]:
        return ["mp4", "webm", "mkv"]
    
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
        Assemble la video avec les pistes audio.
        """
        try:
            # Valider l'environnement
            if not await self._validate_ffmpeg():
                logger.error("FFmpeg non disponible")
                return None
            
            # Creer les dossiers
            output_dir = Path(workspace["output"])
            output_dir.mkdir(parents=True, exist_ok=True)
            
            # Etape 1: Concaténer les segments audio
            merged_audio_path = output_dir / f"{job_id}_audio_merged.mp3"
            
            if len(audio_paths) == 1:
                # Un seul fichier audio
                merged_audio_path = Path(audio_paths[0])
            else:
                # Concaténer plusieurs fichiers
                await self._concat_audio(
                    audio_paths=audio_paths,
                    output_path=str(merged_audio_path),
                    script=script
                )
            
            # Etape 2: Assemble video + audio
            final_path = output_dir / f"{job_id}.mp4"
            
            await self._assemble_video_audio(
                video_path=video_path,
                audio_path=str(merged_audio_path),
                output_path=str(final_path)
            )
            
            logger.info(f"Job {job_id}: Video assemblee avec succes")
            return str(final_path)
            
        except Exception as e:
            logger.error(f"Job {job_id}: Erreur assemblage - {str(e)}")
            return None
    
    async def _concat_audio(
        self,
        audio_paths: List[str],
        output_path: str,
        script: NarrationScript
    ):
        """
        Concatene plusieurs fichiers audio en un seul.
        Ajoute des silences entre les segments.
        """
        # Construire la commande de concatenation avec silences
        filter_parts = []
        inputs = []
        
        for i, audio_path in enumerate(audio_paths):
            inputs.extend(["-i", audio_path])
            
            # Ajouter un silence apres chaque segment (sauf le dernier)
            if i < len(audio_paths) - 1:
                segment = script.segments[i]
                next_start = script.segments[i + 1].start
                silence_duration = max(0, next_start - segment.end)
                
                # Generer un silence si necessaire
                if silence_duration > 0.1:
                    silence_file = Path(audio_path).parent / f"silence_{i:03d}.wav"
                    await self._generate_silence(
                        duration=silence_duration,
                        output_path=str(silence_file)
                    )
                    inputs.extend(["-i", str(silence_file)])
                    filter_parts.append(f"[{len(inputs)-1}:a]")
        
        # Construire le filter complex
        if len(inputs) > 2:
            filter_cmd = "concat=n={}:v=0:a=1".format(len(inputs) // 2)
        else:
            filter_cmd = "concat=n={}:v=0:a=1".format(len(audio_paths))
        
        cmd = [
            "ffmpeg",
            *inputs,
            "-filter_complex", filter_cmd,
            "-acodec", "libmp3lame",
            "-ab", "192k",
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
            raise Exception(f"Erreur concatenation: {stderr.decode()}")
    
    async def _generate_silence(self, duration: float, output_path: str):
        """
        Genere un fichier audio silencieux.
        """
        cmd = [
            "ffmpeg",
            "-f", "lavfi",
            "-i", f"anullsrc=r=44100:cl=mono",
            "-t", str(duration),
            "-acodec", "pcm_s16le",
            output_path,
            "-y"
        ]
        
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        await process.communicate()
    
    async def _assemble_video_audio(
        self,
        video_path: str,
        audio_path: str,
        output_path: str
    ):
        """
        Assemble la video et l'audio en un seul fichier.
        """
        cmd = [
            "ffmpeg",
            "-i", video_path,
            "-i", audio_path,
            "-c:v", self.codec,
            "-c:a", "aac",
            "-b:v", self.bitrate,
            "-b:a", "192k",
            "-map", "0:v",
            "-map", "1:a",
            "-shortest",
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
            raise Exception(f"Erreur assemblage: {stderr.decode()}")
    
    def get_video_duration(self, video_path: str) -> int:
        """
        Recupere la duree d'une video en secondes.
        """
        try:
            cmd = [
                "ffprobe",
                "-v", "error",
                "-show_entries", "format=duration",
                "-of", "default=noprint_wrappers=1:nokey=1",
                video_path
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            duration = float(result.stdout.strip())
            return int(duration)
            
        except Exception:
            return 0
    
    def get_audio_duration(self, audio_path: str) -> float:
        """
        Recupere la duree d'un fichier audio en secondes.
        """
        try:
            cmd = [
                "ffprobe",
                "-v", "error",
                "-show_entries", "format=duration",
                "-of", "default=noprint_wrappers=1:nokey=1",
                audio_path
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            return float(result.stdout.strip())
            
        except Exception:
            return 0.0
    
    async def _validate_ffmpeg(self) -> bool:
        """
        Verifie que FFmpeg est installe.
        """
        try:
            process = await asyncio.create_subprocess_exec(
                "ffmpeg", "-version",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            stdout, stderr = await process.communicate()
            return process.returncode == 0
        except Exception:
            return False