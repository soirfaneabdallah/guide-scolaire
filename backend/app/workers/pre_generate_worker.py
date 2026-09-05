# ============================================================
# FICHIER: backend/app/workers/pre_generate_worker.py
# DESCRIPTION: Worker de pre-generation des concepts populaires
# ============================================================

import asyncio
import logging
from typing import List, Dict, Any

from celery import Celery
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.models.video_cache import VideoCache
from app.services.video.orchestration_service import VideoOrchestrationService
from app.services.video.cache_service import CacheService
from app.core.config import settings

logger = logging.getLogger(__name__)

from .video_worker import celery_app


# Liste des concepts populaires a pre-generer
POPULAR_CONCEPTS = [
    {"concept": "Theoreme de Pythagore", "level": "3eme"},
    {"concept": "Fonction derivee", "level": "Terminale"},
    {"concept": "Theoreme de Thales", "level": "4eme"},
    {"concept": "Equation du second degre", "level": "Seconde"},
    {"concept": "Gravitation universelle", "level": "Premiere"},
    {"concept": "Reaction chimique", "level": "Seconde"},
    {"concept": "Sinus et cosinus", "level": "3eme"},
    {"concept": "Theoreme de l'energie cinetique", "level": "Premiere"},
    {"concept": "Tableau de variations", "level": "Premiere"},
    {"concept": "Nombres complexes", "level": "Terminale"},
]


@celery_app.task(name="pre_generate_worker.generate_popular")
def generate_popular_concepts():
    """
    Pre-genere les videos pour les concepts populaires.
    """
    logger.info("Starting pre-generation of popular concepts")
    
    db = SessionLocal()
    try:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        results = loop.run_until_complete(
            _pre_generate_concepts(db)
        )
        
        logger.info(f"Pre-generation completed: {results}")
        return results
        
    except Exception as e:
        logger.error(f"Pre-generation failed: {str(e)}")
        return {"error": str(e)}
    finally:
        db.close()
        loop.close()


async def _pre_generate_concepts(db: Session) -> Dict[str, Any]:
    """
    Pre-genere les concepts populaires.
    """
    orchestration = VideoOrchestrationService()
    cache_service = CacheService()
    
    results = {
        "total": len(POPULAR_CONCEPTS),
        "generated": 0,
        "cached": 0,
        "failed": 0,
        "details": []
    }
    
    for concept_data in POPULAR_CONCEPTS:
        concept = concept_data["concept"]
        level = concept_data["level"]
        
        # Verifier si deja en cache
        cache_key = cache_service.generate_cache_key(concept, level)
        cached = db.query(VideoCache).filter_by(cache_key=cache_key).first()
        
        if cached and not cached.is_expired():
            results["cached"] += 1
            results["details"].append({
                "concept": concept,
                "status": "cached",
                "cache_key": cache_key
            })
            continue
        
        try:
            # Creer un job de pre-generation
            # Note: on utilise un utilisateur systeme (id=0)
            job = await orchestration.start_generation(
                user_id=0,  # Utilisateur systeme
                prompt=f"Explique le concept de {concept}",
                concept=concept,
                level=level,
                duration_seconds=180,
                language="fr"
            )
            
            # Traiter le job (sans quota)
            await orchestration.process_job(job.id, quota_id=None)
            
            results["generated"] += 1
            results["details"].append({
                "concept": concept,
                "status": "generated",
                "job_id": job.id
            })
            
        except Exception as e:
            logger.error(f"Failed to pre-generate {concept}: {str(e)}")
            results["failed"] += 1
            results["details"].append({
                "concept": concept,
                "status": "failed",
                "error": str(e)
            })
    
    return results


@celery_app.task(name="pre_generate_worker.generate_missing")
def generate_missing_concepts():
    """
    Genere les concepts qui ne sont pas en cache.
    """
    logger.info("Checking for missing concepts in cache")
    
    db = SessionLocal()
    try:
        # Recuperer tous les concepts en cache
        cached_concepts = db.query(VideoCache.concept, VideoCache.level).all()
        cached_set = {(c[0], c[1]) for c in cached_concepts}
        
        # Identifier les concepts manquants
        missing = []
        for concept in POPULAR_CONCEPTS:
            key = (concept["concept"], concept["level"])
            if key not in cached_set:
                missing.append(concept)
        
        if missing:
            logger.info(f"Found {len(missing)} missing concepts")
            # Lancer la generation
            return generate_popular_concepts()
        
        return {"message": "All concepts are cached"}
        
    except Exception as e:
        logger.error(f"Missing concepts check failed: {str(e)}")
        return {"error": str(e)}
    finally:
        db.close()