# backend/app/core/config.py

from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # Base de données
    DATABASE_URL: str = "sqlite:///./guide_scolaire.db"  # Par défaut SQLite pour dev
    IA_SERVICE_URL: str = "http://localhost:8002"
    SECRET_KEY: str = "changez_ceci_en_production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    BASE_URL: str = "http://localhost:8000"  # URL de base de l'API
    
    # Application
    APP_NAME: str = "Guide Scolaire Comores"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    ALLOWED_ORIGINS: list = ["*"]  # À restreindre en prod
    
    # Email (pour plus tard)
    SMTP_HOST: Optional[str] = None
    SMTP_PORT: Optional[int] = None
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()