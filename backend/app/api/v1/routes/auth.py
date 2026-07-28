# backend/app/api/v1/routes/auth.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ..schemas.auth_schemas import (
    RegisterRequest,
    RegisterResponse,
    LoginRequest,
    TokenResponse,
    UserResponse,
    UserUpdateRequest,
)
from ....core.database import get_db
from ....core.dependencies import get_current_active_user
from ....services.auth_service import AuthService
from ....models.user import User

router = APIRouter(prefix="/auth", tags=["Authentification"])

@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
def register(request: RegisterRequest, db: Session = Depends(get_db)):
    """
    Inscription d'un nouvel utilisateur.
    """
    auth_service = AuthService(db)
    user = auth_service.register(
        email=request.email,
        password=request.password,
        first_name=request.first_name,
        last_name=request.last_name,
        level=request.level,
        school=request.school,
        phone_number=request.phone_number,
    )
    return user

@router.post("/login", response_model=TokenResponse)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    """
    Connexion d'un utilisateur existant.
    Retourne un access token et un refresh token.
    """
    auth_service = AuthService(db)
    return auth_service.login(request.email, request.password)

@router.get("/me", response_model=UserResponse)
def get_current_user(
    current_user: User = Depends(get_current_active_user)
):
    """
    Récupère le profil complet de l'utilisateur connecté.
    """
    return current_user

@router.put("/me", response_model=UserResponse)
def update_current_user(
    request: UserUpdateRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Met à jour le profil de l'utilisateur connecté.
    """
    auth_service = AuthService(db)
    update_data = request.model_dump(exclude_unset=True)
    updated_user = auth_service.update_profile(current_user, **update_data)
    return updated_user