# ============================================================
# FICHIER: backend/app/utils/video_utils.py
# DESCRIPTION: Utilitaires pour la manipulation video
# ============================================================

import subprocess
import re
from pathlib import Path
from typing import Optional, Tuple, List
from datetime import datetime
import json


class VideoUtils:
    """
    Utilitaires pour la manipulation de fichiers video.
    """
    
    @staticmethod
    def get_video_info(video_path: str) -> dict:
        """
        Recupere les informations d'une video.
        
        Args:
            video_path: Chemin du fichier video
            
        Returns:
            dict: Informations video (duree, resolution, etc.)
        """
        try:
            cmd = [
                "ffprobe",
                "-v", "error",
                "-show_entries", "stream=width,height,r_frame_rate,duration",
                "-show_entries", "format=duration",
                "-of", "json",
                video_path
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            data = json.loads(result.stdout)
            
            info = {
                "duration": 0,
                "width": 0,
                "height": 0,
                "fps": 0
            }
            
            # Recuperer la duree
            if "format" in data and "duration" in data["format"]:
                info["duration"] = float(data["format"]["duration"])
            
            # Recuperer les informations des streams
            if "streams" in data:
                for stream in data["streams"]:
                    if stream.get("codec_type") == "video":
                        info["width"] = int(stream.get("width", 0))
                        info["height"] = int(stream.get("height", 0))
                        
                        fps = stream.get("r_frame_rate", "0/0")
                        if "/" in fps:
                            num, den = fps.split("/")
                            if float(den) > 0:
                                info["fps"] = float(num) / float(den)
            
            return info
            
        except Exception as e:
            return {"error": str(e), "duration": 0, "width": 0, "height": 0, "fps": 0}
    
    @staticmethod
    def extract_thumbnail(video_path: str, output_path: str, time: float = 5.0) -> bool:
        """
        Extrait une miniature d'une video.
        
        Args:
            video_path: Chemin de la video
            output_path: Chemin de sortie de la miniature
            time: Temps de capture en secondes
            
        Returns:
            bool: True si reussi
        """
        try:
            cmd = [
                "ffmpeg",
                "-i", video_path,
                "-ss", str(time),
                "-vframes", "1",
                "-vf", "scale=320:-1",
                output_path,
                "-y"
            ]
            
            result = subprocess.run(cmd, capture_output=True)
            return result.returncode == 0
            
        except Exception:
            return False
    
    @staticmethod
    def get_video_duration(video_path: str) -> float:
        """
        Recupere la duree d'une video.
        
        Args:
            video_path: Chemin de la video
            
        Returns:
            float: Duree en secondes
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
            return float(result.stdout.strip())
            
        except Exception:
            return 0.0
    
    @staticmethod
    def get_audio_duration(audio_path: str) -> float:
        """
        Recupere la duree d'un fichier audio.
        
        Args:
            audio_path: Chemin du fichier audio
            
        Returns:
            float: Duree en secondes
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
    
    @staticmethod
    def generate_thumbnail_filename(video_path: str) -> str:
        """
        Genere le nom du fichier miniature.
        
        Args:
            video_path: Chemin de la video
            
        Returns:
            str: Nom du fichier miniature
        """
        video_path = Path(video_path)
        return video_path.stem + "_thumb.jpg"
    
    @staticmethod
    def is_valid_video(file_path: str) -> bool:
        """
        Verifie si le fichier est une video valide.
        
        Args:
            file_path: Chemin du fichier
            
        Returns:
            bool: True si valide
        """
        try:
            info = VideoUtils.get_video_info(file_path)
            return info.get("duration", 0) > 0
        except Exception:
            return False
    
    @staticmethod
    def get_file_size(file_path: str) -> int:
        """
        Recupere la taille d'un fichier.
        
        Args:
            file_path: Chemin du fichier
            
        Returns:
            int: Taille en bytes
        """
        try:
            return Path(file_path).stat().st_size
        except Exception:
            return 0
    
    @staticmethod
    def format_duration(seconds: float) -> str:
        """
        Formate une duree en format HH:MM:SS.
        
        Args:
            seconds: Duree en secondes
            
        Returns:
            str: Duree formatee
        """
        hours = int(seconds // 3600)
        minutes = int((seconds % 3600) // 60)
        secs = int(seconds % 60)
        
        if hours > 0:
            return f"{hours:02d}:{minutes:02d}:{secs:02d}"
        else:
            return f"{minutes:02d}:{secs:02d}"


class VideoValidator:
    """
    Validateur de fichiers video.
    """
    
    SUPPORTED_FORMATS = [".mp4", ".webm", ".mkv", ".avi", ".mov"]
    MAX_SIZE_BYTES = 500 * 1024 * 1024  # 500 MB
    MIN_DURATION_SECONDS = 5
    MAX_DURATION_SECONDS = 600  # 10 minutes
    
    @classmethod
    def validate(cls, file_path: str) -> Tuple[bool, Optional[str]]:
        """
        Valide un fichier video.
        
        Args:
            file_path: Chemin du fichier
            
        Returns:
            Tuple[bool, Optional[str]]: (valide, message_erreur)
        """
        path = Path(file_path)
        
        # Verifier l'existence
        if not path.exists():
            return False, "Le fichier n'existe pas"
        
        # Verifier le format
        if path.suffix.lower() not in cls.SUPPORTED_FORMATS:
            return False, f"Format non supporte. Formats acceptes: {', '.join(cls.SUPPORTED_FORMATS)}"
        
        # Verifier la taille
        size = path.stat().st_size
        if size > cls.MAX_SIZE_BYTES:
            return False, f"Fichier trop volumineux. Taille max: {cls.MAX_SIZE_BYTES / (1024*1024):.0f} MB"
        
        # Verifier la duree
        duration = VideoUtils.get_video_duration(file_path)
        if duration < cls.MIN_DURATION_SECONDS:
            return False, f"Video trop courte. Duree min: {cls.MIN_DURATION_SECONDS}s"
        if duration > cls.MAX_DURATION_SECONDS:
            return False, f"Video trop longue. Duree max: {cls.MAX_DURATION_SECONDS}s"
        
        return True, None