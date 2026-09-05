# ============================================================
# FICHIER: backend/app/services/storage/local_storage.py
# DESCRIPTION: Stockage local des videos
# ============================================================

import shutil
from pathlib import Path
from typing import Optional
from datetime import datetime

from .base_storage import BaseStorage
from app.core.config import settings
from app.utils.file_utils import FileUtils

import logging

logger = logging.getLogger(__name__)


class LocalStorage(BaseStorage):
    """
    Stockage local des videos.
    Les fichiers sont stockes dans le dossier 'output/videos/'.
    """
    
    def __init__(self, base_dir: str = "output/videos"):
        self.base_dir = Path(base_dir)
        self.base_dir.mkdir(parents=True, exist_ok=True)
    
    async def save_video(
        self,
        file_path: str,
        job_id: str,
        user_id: int,
        **kwargs
    ) -> Optional[str]:
        """
        Sauvegarde une video localement.
        """
        try:
            # Generer le chemin de destination
            date_str = datetime.utcnow().strftime("%Y/%m/%d")
            dest_dir = self.base_dir / date_str / str(user_id)
            dest_dir.mkdir(parents=True, exist_ok=True)
            
            dest_file = dest_dir / f"{job_id}.mp4"
            
            # Copier le fichier
            shutil.copy(file_path, dest_file)
            
            # Generer l'URL
            url = f"/videos/{date_str}/{user_id}/{job_id}.mp4"
            
            logger.info(f"Video sauvegardee: {url}")
            return url
            
        except Exception as e:
            logger.error(f"Erreur sauvegarde video: {str(e)}")
            return None
    
    async def save_thumbnail(
        self,
        file_path: str,
        job_id: str,
        user_id: int,
        **kwargs
    ) -> Optional[str]:
        """
        Sauvegarde une miniature localement.
        """
        try:
            # Generer le chemin de destination
            date_str = datetime.utcnow().strftime("%Y/%m/%d")
            dest_dir = self.base_dir / "thumbnails" / date_str / str(user_id)
            dest_dir.mkdir(parents=True, exist_ok=True)
            
            dest_file = dest_dir / f"{job_id}.jpg"
            
            # Copier le fichier
            shutil.copy(file_path, dest_file)
            
            # Generer l'URL
            url = f"/thumbnails/{date_str}/{user_id}/{job_id}.jpg"
            
            logger.info(f"Miniature sauvegardee: {url}")
            return url
            
        except Exception as e:
            logger.error(f"Erreur sauvegarde miniature: {str(e)}")
            return None
    
    async def delete_video(self, video_url: str) -> bool:
        """
        Supprime une video locale.
        """
        try:
            # Convertir l'URL en chemin local
            # /videos/2024/01/15/1/abc123.mp4
            relative_path = video_url.lstrip("/")
            file_path = self.base_dir.parent / relative_path
            
            if file_path.exists():
                file_path.unlink()
                logger.info(f"Video supprimee: {video_url}")
                return True
            
            return False
            
        except Exception as e:
            logger.error(f"Erreur suppression video: {str(e)}")
            return False
    
    def get_file_size(self, file_path: str) -> int:
        """
        Recupere la taille d'un fichier.
        """
        try:
            path = Path(file_path)
            if path.exists():
                return path.stat().st_size
            return 0
        except Exception:
            return 0