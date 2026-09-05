# ============================================================
# FICHIER: ia-service/src/main.py
# DESCRIPTION: Serveur FastAPI pour le service IA
# ============================================================

import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .api.routes import router

# Configuration des logs
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Création de l'application
app = FastAPI(
    title="E-learningAI - Service IA",
    description="Service d'IA pour l'assistant pédagogique",
    version="1.0.0",
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ INCLURE LE ROUTER AVEC LE PREFIXE /api
app.include_router(router, prefix="/api")


@app.get("/")
async def root():
    return {
        "service": "E-learningAI - Service IA",
        "status": "running",
        "endpoints": {
            "ask": "/api/ask",
            "video_prompt": "/api/video_prompt",
            "health": "/health",
            "docs": "/docs"
        }
    }


@app.get("/health")
async def health():
    return {"status": "ok", "service": "ia-service"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "src.main:app",
        host="0.0.0.0",
        port=8002,
        reload=True
    )