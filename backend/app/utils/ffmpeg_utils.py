# ============================================================
# FICHIER: backend/app/utils/ffmpeg_utils.py
# DESCRIPTION: Utilitaires pour FFmpeg
# ============================================================

import subprocess
import asyncio
import json
from pathlib import Path
from typing import List, Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)


class FFMpegUtils:
    """
    Utilitaires pour l'utilisation de FFmpeg.
    """
    
    @staticmethod
    def is_available() -> bool:
        """
        Verifie si FFmpeg est installe.
        
        Returns:
            bool: True si FFmpeg est disponible
        """
        try:
            result = subprocess.run(
                ["ffmpeg", "-version"],
                capture_output=True,
                text=True
            )
            return result.returncode == 0
        except Exception:
            return False
    
    @staticmethod
    async def get_video_info(video_path: str) -> Dict[str, Any]:
        """
        Recupere les informations d'une video.
        
        Args:
            video_path: Chemin de la video
            
        Returns:
            dict: Informations video
        """
        cmd = [
            "ffprobe",
            "-v", "error",
            "-show_entries", "stream=codec_name,width,height,r_frame_rate,duration",
            "-show_entries", "format=duration,size,bit_rate",
            "-of", "json",
            video_path
        ]
        
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        stdout, stderr = await process.communicate()
        
        if process.returncode != 0:
            return {"error": stderr.decode()}
        
        return json.loads(stdout.decode())
    
    @staticmethod
    async def extract_thumbnail(
        video_path: str,
        output_path: str,
        time: float = 5.0,
        width: int = 320
    ) -> bool:
        """
        Extrait une miniature d'une video.
        
        Args:
            video_path: Chemin de la video
            output_path: Chemin de sortie
            time: Temps en secondes
            width: Largeur de la miniature
            
        Returns:
            bool: True si reussi
        """
        cmd = [
            "ffmpeg",
            "-i", video_path,
            "-ss", str(time),
            "-vframes", "1",
            "-vf", f"scale={width}:-1",
            output_path,
            "-y"
        ]
        
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        await process.communicate()
        return process.returncode == 0
    
    @staticmethod
    async def concat_audio(
        audio_paths: List[str],
        output_path: str,
        silence_duration: float = 0.5
    ) -> bool:
        """
        Concatene plusieurs fichiers audio.
        
        Args:
            audio_paths: Liste des chemins audio
            output_path: Chemin de sortie
            silence_duration: Duree du silence entre les segments
            
        Returns:
            bool: True si reussi
        """
        if not audio_paths:
            return False
        
        # Construire le filtre de concatenation
        filter_parts = []
        inputs = []
        
        for i, audio_path in enumerate(audio_paths):
            inputs.extend(["-i", audio_path])
            filter_parts.append(f"[{i}:a]")
        
        # Ajouter un silence apres chaque segment
        if silence_duration > 0:
            # Creer un fichier de silence
            silence_file = Path(output_path).parent / "silence.wav"
            await FFMpegUtils.generate_silence(silence_duration, str(silence_file))
            
            # Ajouter le silence apres chaque segment
            filter_parts_with_silence = []
            for i, audio_path in enumerate(audio_paths):
                filter_parts_with_silence.append(f"[{i}:a]")
                if i < len(audio_paths) - 1:
                    filter_parts_with_silence.append(f"['silence':a]")
            
            filter_cmd = f"concat=n={len(filter_parts_with_silence)}:v=0:a=1"
        else:
            filter_cmd = f"concat=n={len(audio_paths)}:v=0:a=1"
        
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
        
        await process.communicate()
        return process.returncode == 0
    
    @staticmethod
    async def generate_silence(duration: float, output_path: str) -> bool:
        """
        Genere un fichier audio silencieux.
        
        Args:
            duration: Duree en secondes
            output_path: Chemin de sortie
            
        Returns:
            bool: True si reussi
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
        return process.returncode == 0
    
    @staticmethod
    async def get_duration(file_path: str) -> float:
        """
        Recupere la duree d'un fichier audio/video.
        
        Args:
            file_path: Chemin du fichier
            
        Returns:
            float: Duree en secondes
        """
        cmd = [
            "ffprobe",
            "-v", "error",
            "-show_entries", "format=duration",
            "-of", "default=noprint_wrappers=1:nokey=1",
            file_path
        ]
        
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        stdout, stderr = await process.communicate()
        
        if process.returncode != 0:
            return 0.0
        
        try:
            return float(stdout.decode().strip())
        except ValueError:
            return 0.0