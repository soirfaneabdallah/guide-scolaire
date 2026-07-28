# backend/app/services/auth_service.py

from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from ..repositories.user_repository import UserRepository
from ..core.security import create_access_token, create_refresh_token
from ..core.config import settings
from ..models.user import User
from datetime import datetime

class AuthService:
    def __init__(self, db: Session):
        self.db = db
        self.user_repo = UserRepository(db)

    def register(
        self,
        email: str,
        password: str,
        first_name: str,
        last_name: str,
        level: str = None,
        school: str = None,
        phone_number: str = None,
    ) -> User:
        # Vérifier si l'utilisateur existe déjà
        if self.user_repo.get_by_email(email):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cet email est déjà utilisé.",
            )

        # Créer l'utilisateur
        user = self.user_repo.create(
            email=email,
            password=password,
            first_name=first_name,
            last_name=last_name,
            level=level,
            school=school,
            phone_number=phone_number,
        )
        return user

    def login(self, email: str, password: str) -> dict:
        # Récupérer l'utilisateur
        user = self.user_repo.get_by_email(email)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Email ou mot de passe incorrect.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        # Vérifier le mot de passe
        if not self.user_repo.verify_password(user, password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Email ou mot de passe incorrect.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        # Vérifier que le compte est actif
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Ce compte est désactivé.",
            )

        # Mise à jour de la dernière connexion
        self.user_repo.update_last_login(user)

        # Générer les tokens
        access_token = create_access_token(
            data={"sub": str(user.id), "email": user.email, "role": user.role.value}
        )
        refresh_token = create_refresh_token(
            data={"sub": str(user.id)}
        )

        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
        }

    def update_profile(self, user: User, **kwargs) -> User:
        return self.user_repo.update(user, **kwargs)