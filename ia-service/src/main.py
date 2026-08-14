# ia-service/src/main.py

import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .api.routes import router  # ✅ Utiliser .api.routes

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

# Routes
app.include_router(router)

@app.get("/")
async def root():
    return {
        "service": "E-learningAI - Service IA",
        "status": "running",
        "docs": "/docs",
        "health": "/api/health",
    }

@app.get("/health")
async def health():
    return {"status": "ok", "service": "ia-service"}