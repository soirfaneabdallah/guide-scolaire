# backend/app/main.py

import asyncio
import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .core.config import settings
from .core.database import SessionLocal, engine, Base
from .api.v1.routes.auth import router as auth_router
from .api.v1.routes.chat import router as chat_router
from .api.v1.routes.subjects import router as subjects_router
from .api.v1.routes.books import router as books_router
from .api.v1.routes.agent import router as agent_router
from .api.v1.routes.videos import router as videos_router
from .repositories.subject_repository import SubjectRepository
from .models import *  # noqa: F401,F403

logger = logging.getLogger(__name__)


# ============================================================
# CRÉATION DES DOSSIERS
# ============================================================

os.makedirs("uploads/covers", exist_ok=True)
os.makedirs("uploads/pdfs", exist_ok=True)

# Création des tables en base de données
Base.metadata.create_all(bind=engine)


# ============================================================
# JOB DE FOND : CLEANUP DU CACHE VIDÉO
# ============================================================

async def _cleanup_video_cache_periodically():
    """
    Supprime les MP4 du cache vidéo plus vieux que le TTL (1h).

    ⚠️ Les vidéos sont générées à la volée et mises en cache temporaire
    dans /tmp pour permettre une lecture fluide (barre de progression,
    seek, Range requests). Ce job garantit qu'aucun fichier ne reste
    indéfiniment.
    """
    # Import local pour éviter les imports circulaires au démarrage
    from .services.video.stream_renderer import StreamRenderer

    while True:
        try:
            removed = StreamRenderer.cleanup_cache()
            if removed > 0:
                logger.info(f"🧹 [Cache] {removed} fichier(s) supprimé(s)")
        except Exception as e:
            logger.error(f"❌ [Cache] Erreur cleanup: {e}", exc_info=True)

        # Toutes les 30 minutes
        await asyncio.sleep(1800)


# ============================================================
# LIFESPAN (démarrage + arrêt propres)
# ============================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Gère le cycle de vie de l'application :
    - Démarrage : init des matières + lancement du cleanup
    - Arrêt : annulation propre du cleanup
    """
    # ---------- DÉMARRAGE ----------
    logger.info("🚀 Démarrage du backend")

    # 1. Initialiser les matières par défaut
    db = SessionLocal()
    try:
        repo = SubjectRepository(db)
        repo.init_default_subjects()
        logger.info("✅ Matières par défaut initialisées")
    except Exception as e:
        logger.error(f"❌ Erreur init matières: {e}", exc_info=True)
    finally:
        db.close()

    # 2. Lancer le job de cleanup du cache vidéo
    cleanup_task = asyncio.create_task(_cleanup_video_cache_periodically())
    logger.info("🧹 Job de cleanup du cache vidéo démarré (toutes les 30 min)")

    yield

    # ---------- ARRÊT ----------
    logger.info("🛑 Arrêt du backend")

    cleanup_task.cancel()
    try:
        await cleanup_task
    except asyncio.CancelledError:
        pass

    logger.info("✅ Arrêt propre terminé")


# ============================================================
# APPLICATION FASTAPI
# ============================================================

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    debug=settings.DEBUG,
    lifespan=lifespan,
)


# ============================================================
# CORS
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["Content-Range", "Accept-Ranges", "Content-Length"],
)


# ============================================================
# FICHIERS STATIQUES
# ============================================================

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")


# ============================================================
# ROUTES
# ============================================================

app.include_router(auth_router, prefix="/api/v1")
app.include_router(chat_router, prefix="/api/v1")
app.include_router(subjects_router, prefix="/api/v1")
app.include_router(books_router, prefix="/api/v1")
app.include_router(agent_router, prefix="/api/v1", tags=["Agent"])
app.include_router(videos_router, prefix="/api/v1", tags=["Videos"])


# ============================================================
# ENDPOINTS DE BASE
# ============================================================

@app.get("/")
def root():
    return {
        "message": f"Bienvenue sur {settings.APP_NAME}",
        "version": settings.APP_VERSION,
        "docs": "/docs",
    }


@app.get("/health")
def health():
    return {"status": "ok"}