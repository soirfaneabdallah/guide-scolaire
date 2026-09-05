# ============================================================
# FICHIER: backend/app/services/storage/firebase_storage.py
# DESCRIPTION: Stockage Firebase (optionnel)
# ============================================================

from typing import Optional
import asyncio
from pathlib import Path

from .base_storage import BaseStorage

import logging

logger = logging.getLogger(__name__)


class FirebaseStorage(BaseStorage):
    """
    Stockage Firebase Storage.
    Necessite une configuration Firebase.
    """
    
    def __init__(
        self,
        bucket: Optional[str] = None,
        credentials_path: Optional[str] = None
    ):
        self.bucket = bucket
        self.credentials_path = credentials_path
        self._firebase = None
    
    async def _initialize(self):
        """
        Initialise le client Firebase.
        """
        if self._firebase:
            return
        
        try:
            # Tentative d'import de firebase_admin
            try:
                import firebase_admin
                from firebase_admin import credentials, storage
            except ImportError:
                logger.warning("Firebase Admin SDK non installe. Utilisation du stockage local.")
                self._firebase = "unavailable"
                return
            
            # Initialiser Firebase
            if not firebase_admin._apps:
                if self.credentials_path:
                    cred = credentials.Certificate(self.credentials_path)
                    firebase_admin.initialize_app(cred, {
                        'storageBucket': self.bucket
                    })
                else:
                    firebase_admin.initialize_app()
            
            self._firebase = storage.bucket()
            
        except Exception as e:
            logger.error(f"Erreur initialisation Firebase: {str(e)}")
            self._firebase = "unavailable"
    
    async def save_video(
        self,
        file_path: str,
        job_id: str,
        user_id: int,
        **kwargs
    ) -> Optional[str]:
        """
        Sauvegarde une video sur Firebase.
        """
        try:
            await self._initialize()
            
            if self._firebase == "unavailable":
                # Fallback vers le stockage local
                from .local_storage import LocalStorage
                local = LocalStorage()
                return await local.save_video(file_path, job_id, user_id, **kwargs)
            
            # Chemin dans Firebase
            remote_path = f"videos/{user_id}/{job_id}.mp4"
            
            # Upload
            blob = self._firebase.blob(remote_path)
            blob.upload_from_filename(file_path)
            
            # Rendre public
            blob.make_public()
            
            url = blob.public_url
            
            logger.info(f"Video sauvegardee sur Firebase: {url}")
            return url
            
        except Exception as e:
            logger.error(f"Erreur sauvegarde Firebase: {str(e)}")
            # Fallback vers local
            from .local_storage import LocalStorage
            local = LocalStorage()
            return await local.save_video(file_path, job_id, user_id, **kwargs)
    
    async def save_thumbnail(
        self,
        file_path: str,
        job_id: str,
        user_id: int,
        **kwargs
    ) -> Optional[str]:
        """
        Sauvegarde une miniature sur Firebase.
        """
        try:
            await self._initialize()
            
            if self._firebase == "unavailable":
                from .local_storage import LocalStorage
                local = LocalStorage()
                return await local.save_thumbnail(file_path, job_id, user_id, **kwargs)
            
            remote_path = f"thumbnails/{user_id}/{job_id}.jpg"
            
            blob = self._firebase.blob(remote_path)
            blob.upload_from_filename(file_path)
            blob.make_public()
            
            url = blob.public_url
            
            logger.info(f"Miniature sauvegardee sur Firebase: {url}")
            return url
            
        except Exception as e:
            logger.error(f"Erreur sauvegarde miniature Firebase: {str(e)}")
            return None
    
    async def delete_video(self, video_url: str) -> bool:
        """
        Supprime une video de Firebase.
        """
        try:
            await self._initialize()
            
            if self._firebase == "unavailable":
                return False
            
            # Extraire le chemin depuis l'URL
            # https://storage.googleapis.com/bucket/videos/1/abc.mp4
            import re
            match = re.search(r'/videos/(.*)$', video_url)
            if match:
                remote_path = f"videos/{match.group(1)}"
                blob = self._firebase.blob(remote_path)
                blob.delete()
                logger.info(f"Video supprimee de Firebase: {video_url}")
                return True
            
            return False
            
        except Exception as e:
            logger.error(f"Erreur suppression Firebase: {str(e)}")
            return False
    
    def get_file_size(self, file_path: str) -> int:
        """
        Recupere la taille d'un fichier.
        """
        try:
            from pathlib import Path
            path = Path(file_path)
            if path.exists():
                return path.stat().st_size
            return 0
        except Exception:
            return 0