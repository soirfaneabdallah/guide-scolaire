# backend/app/services/auth_service.py

from typing import Optional
from datetime import datetime, timedelta
import json
from sqlalchemy.orm import Session
from ..models.user import User
from ..core.security import verify_password, get_password_hash, create_access_token, create_refresh_token
from ..core.config import settings
from ..api.v1.schemas.auth_schemas import UserRole

class AuthService:
    def __init__(self, db: Session):
        self.db = db

    def login(self, email: str, password: str) -> dict:
        """Authentifie un utilisateur"""
        user = self.db.query(User).filter(User.email == email).first()
        
        if not user or not verify_password(password, user.password_hash):
            raise ValueError("Email ou mot de passe incorrect")
        
        if not user.is_active:
            raise ValueError("Compte désactivé")
        
        # Mettre à jour last_login
        user.last_login = datetime.now()
        self.db.commit()
        self.db.refresh(user)
        
        # Créer les tokens
        access_token = create_access_token(
            data={
                "sub": str(user.id),
                "email": user.email,
                "role": user.role
            },
            expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        )
        
        refresh_token = create_refresh_token(
            data={"sub": str(user.id)}
        )
        
        # ✅ CORRECTION : Gérer les types correctement
        preferences = user.preferences
        if isinstance(preferences, str):
            try:
                preferences = json.loads(preferences) if preferences else {}
            except:
                preferences = {}
        elif preferences is None:
            preferences = {}
        
        # ✅ CORRECTION : role en minuscules
        role = user.role.lower() if user.role else "student"
        
        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "user": {
                "id": user.id,
                "email": user.email,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "full_name": user.full_name,
                "level": user.level,
                "avatar_url": user.avatar_url,
                "bio": user.bio,
                "school": user.school,
                "phone_number": user.phone_number,
                "birth_date": user.birth_date.isoformat() if user.birth_date else None,
                "preferences": preferences,  # ✅ dictionnaire
                "role": role,  # ✅ en minuscules
                "is_active": user.is_active,
                "is_verified": user.is_verified,
                "created_at": user.created_at.isoformat() if user.created_at else None,
                "last_login": user.last_login.isoformat() if user.last_login else None,
            }
        }

    def register(self, email: str, password: str, first_name: str, last_name: str, **kwargs) -> User:
        """Crée un nouvel utilisateur"""
        # Tronquer le mot de passe si trop long
        if len(password) > 72:
            password = password[:72]
        
        # Vérifier si l'email existe déjà
        existing = self.db.query(User).filter(User.email == email).first()
        if existing:
            raise ValueError("Cet email est déjà utilisé")
        
        # Récupérer le rôle (en minuscules)
        role = kwargs.get('role', UserRole.STUDENT)
        if isinstance(role, UserRole):
            role = role.value.lower()  # ✅ en minuscules
        elif isinstance(role, str):
            role = role.lower()
        
        # Préférences en JSON
        preferences = kwargs.get('preferences', {})
        if isinstance(preferences, dict):
            preferences = json.dumps(preferences) if preferences else None
        
        # Créer l'utilisateur
        user = User(
            email=email,
            password_hash=get_password_hash(password),
            first_name=first_name,
            last_name=last_name,
            role=role,  # ✅ en minuscules
            level=kwargs.get('level'),
            school=kwargs.get('school'),
            phone_number=kwargs.get('phone_number'),
            bio=kwargs.get('bio'),
            preferences=preferences,  # ✅ stocké en JSON
            is_active=True,
            is_verified=False,
        )
        
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        
        return user

    def get_user_by_id(self, user_id: int) -> Optional[User]:
        """Récupère un utilisateur par son ID"""
        return self.db.query(User).filter(User.id == user_id).first()

    def get_user_by_email(self, email: str) -> Optional[User]:
        """Récupère un utilisateur par son email"""
        return self.db.query(User).filter(User.email == email).first()

    def update_user(self, user_id: int, **kwargs) -> Optional[User]:
        """Met à jour un utilisateur"""
        user = self.get_user_by_id(user_id)
        if not user:
            return None
        
        # Gérer les champs spéciaux
        if 'role' in kwargs:
            if isinstance(kwargs['role'], UserRole):
                kwargs['role'] = kwargs['role'].value.lower()
            elif isinstance(kwargs['role'], str):
                kwargs['role'] = kwargs['role'].lower()
        
        if 'preferences' in kwargs and isinstance(kwargs['preferences'], dict):
            kwargs['preferences'] = json.dumps(kwargs['preferences'])
        
        for key, value in kwargs.items():
            if hasattr(user, key) and value is not None:
                setattr(user, key, value)
        
        self.db.commit()
        self.db.refresh(user)
        return user