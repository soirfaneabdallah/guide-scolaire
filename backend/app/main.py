# backend/app/main.py

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .core.config import settings
from .core.database import SessionLocal, engine, Base
from .api.v1.routes.auth import router as auth_router
from .api.v1.routes.chat import router as chat_router
from .repositories.subject_repository import SubjectRepository
from .api.v1.routes.subjects import router as subjects_router

# Création des tables en base de données
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    debug=settings.DEBUG,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)



# Routes
app.include_router(auth_router, prefix="/api/v1")
app.include_router(chat_router, prefix="/api/v1")
app.include_router(subjects_router, prefix="/api/v1")

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

@app.on_event("startup")
async def startup_event():
    """Initialisation des données au démarrage"""
    db = SessionLocal()
    try:
        repo = SubjectRepository(db)
        repo.init_default_subjects()
        print("✅ Matières par défaut initialisées")
    finally:
        db.close()