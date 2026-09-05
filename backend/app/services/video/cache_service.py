# ============================================================
# FICHIER: backend/app/services/video/cache_service.py
# DESCRIPTION: Service de cache pour les videos generees
# ============================================================

import hashlib
import json
from typing import Optional
from datetime import datetime, timedelta
from sqlalchemy.orm import Session

from app.models.video_cache import VideoCache
from app.core.database import SessionLocal
from app.core.constants.video_constants import CACHE_TTL_DAYS

import logging

logger = logging.getLogger(__name__)


class CacheService:
    """
    Gere le cache des videos generees.
    Permet d'eviter de regenerer la meme video plusieurs fois.
    """
    
    @staticmethod
    def generate_cache_key(concept: str, level: Optional[str] = None, language: str = "fr") -> str:
        """
        Genere une cle de cache unique pour un concept.
        
        Args:
            concept: Nom du concept
            level: Niveau scolaire (optionnel)
            language: Langue
            
        Returns:
            str: Cle de cache
        """
        data = {
            "concept": concept.lower().strip(),
            "level": level.lower().strip() if level else None,
            "language": language.lower().strip()
        }
        json_str = json.dumps(data, sort_keys=True)
        return hashlib.sha256(json_str.encode()).hexdigest()
    
    async def get_cached_video(
        self, 
        concept: str, 
        level: Optional[str] = None,
        language: str = "fr"
    ) -> Optional[dict]:
        """
        Recupere une video en cache si elle existe et n'est pas expiree.
        
        Args:
            concept: Nom du concept
            level: Niveau scolaire (optionnel)
            language: Langue
            
        Returns:
            dict: Donnees de la video cachee ou None
        """
        cache_key = self.generate_cache_key(concept, level, language)
        
        db = SessionLocal()
        try:
            cached = db.query(VideoCache).filter_by(cache_key=cache_key).first()
            
            if cached and not cached.is_expired():
                # Incrementer le compteur de vues
                cached.views_count += 1
                db.commit()
                logger.info(f"Cache hit: {concept}")
                return cached.to_dict()
            
            return None
            
        finally:
            db.close()
    
    async def save_cached_video(
        self,
        concept: str,
        video_url: str,
        thumbnail_url: Optional[str] = None,
        duration_seconds: Optional[int] = None,
        level: Optional[str] = None,
        language: str = "fr",
        engine_used: str = "manim"
    ) -> VideoCache:
        """
        Sauvegarde une video dans le cache.
        
        Args:
            concept: Nom du concept
            video_url: URL de la video
            thumbnail_url: URL de la miniature
            duration_seconds: Duree en secondes
            level: Niveau scolaire
            language: Langue
            engine_used: Moteur utilise
            
        Returns:
            VideoCache: L'objet cache cree
        """
        cache_key = self.generate_cache_key(concept, level, language)
        
        db = SessionLocal()
        try:
            # Verifier si existe deja
            existing = db.query(VideoCache).filter_by(cache_key=cache_key).first()
            if existing:
                existing.video_url = video_url
                existing.thumbnail_url = thumbnail_url
                existing.duration_seconds = duration_seconds
                existing.engine_used = engine_used
                existing.expires_at = datetime.utcnow() + timedelta(days=CACHE_TTL_DAYS)
                db.commit()
                db.refresh(existing)
                logger.info(f"Cache mis a jour: {concept}")
                return existing
            
            # Creer nouveau
            cached = VideoCache(
                cache_key=cache_key,
                concept=concept,
                level=level,
                language=language,
                video_url=video_url,
                thumbnail_url=thumbnail_url,
                duration_seconds=duration_seconds,
                engine_used=engine_used,
                expires_at=datetime.utcnow() + timedelta(days=CACHE_TTL_DAYS)
            )
            db.add(cached)
            db.commit()
            db.refresh(cached)
            logger.info(f"Cache sauvegarde: {concept}")
            return cached
            
        finally:
            db.close()
    
    async def increment_views(self, cache_key: str) -> bool:
        """
        Incremente le compteur de vues d'une video en cache.
        
        Args:
            cache_key: Cle de cache
            
        Returns:
            bool: True si reussi
        """
        db = SessionLocal()
        try:
            cached = db.query(VideoCache).filter_by(cache_key=cache_key).first()
            if cached:
                cached.views_count += 1
                db.commit()
                return True
            return False
        finally:
            db.close()