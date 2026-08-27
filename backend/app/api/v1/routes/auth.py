# backend/app/api/v1/routes/auth.py

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
import os
import shutil
from datetime import datetime
from typing import Optional
from ....core.database import get_db
from ....core.dependencies import get_current_active_user
from ....services.auth_service import AuthService
from ....models.user import User
from ..schemas.auth_schemas import (
    LoginRequest,
    RegisterRequest,
    RegisterResponse,
    TokenResponse,
    RefreshTokenRequest,
    UserResponse,
    UserUpdateRequest,
)

router = APIRouter(prefix="/auth", tags=["Authentification"])

# ============================================================
#  AUTHENTIFICATION
# ============================================================

@router.post("/login", response_model=TokenResponse)
def login(
    request: LoginRequest,
    db: Session = Depends(get_db),
):
    """Authentification utilisateur"""
    auth_service = AuthService(db)
    
    try:
        result = auth_service.login(request.email, request.password)
        return result
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )

@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
def register(
    request: RegisterRequest,
    db: Session = Depends(get_db),
):
    """Inscription d'un nouvel utilisateur"""
    auth_service = AuthService(db)
    
    try:
        user = auth_service.register(
            email=request.email,
            password=request.password,
            first_name=request.first_name,
            last_name=request.last_name,
            level=request.level,
            school=request.school,
            phone_number=request.phone_number,
            role=request.role,
        )
        return user
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.post("/refresh", response_model=TokenResponse)
def refresh_token(
    request: RefreshTokenRequest,
    db: Session = Depends(get_db),
):
    """Rafraîchit le token d'accès"""
    auth_service = AuthService(db)
    
    try:
        result = auth_service.refresh_token(request.refresh_token)
        return result
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )

# ============================================================
#  PROFIL UTILISATEUR
# ============================================================

@router.get("/me", response_model=UserResponse)
def get_current_user_info(
    current_user: User = Depends(get_current_active_user),
):
    """Récupère les informations de l'utilisateur connecté"""
    return current_user

@router.put("/me", response_model=UserResponse)
def update_current_user(
    request: UserUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Met à jour le profil de l'utilisateur connecté"""
    auth_service = AuthService(db)
    
    user = auth_service.update_user(
        current_user.id,
        **request.model_dump(exclude_unset=True)
    )
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utilisateur non trouvé"
        )
    
    return user

# ============================================================
#  AVATAR (PHOTO DE PROFIL)
# ============================================================

@router.post("/me/avatar")
async def update_avatar(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Met à jour la photo de profil de l'utilisateur
    
    - Accepte les formats: jpg, jpeg, png, gif, webp
    - Taille max: 5MB
    - L'image est redimensionnée automatiquement
    """
    # ✅ Vérifier le type de fichier
    allowed_extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp']
    file_extension = file.filename.split('.')[-1].lower()
    
    if file_extension not in allowed_extensions:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Format non supporté. Utilisez: {', '.join(allowed_extensions)}"
        )
    
    # ✅ Vérifier la taille du fichier (max 5MB)
    file.file.seek(0, 2)
    file_size = file.file.tell()
    file.file.seek(0)
    
    if file_size > 5 * 1024 * 1024:  # 5MB
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="L'image ne doit pas dépasser 5MB"
        )
    
    # ✅ Créer le dossier d'avatars
    avatar_dir = "uploads/avatars"
    os.makedirs(avatar_dir, exist_ok=True)
    
    # ✅ Générer un nom unique
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"avatar_{current_user.id}_{timestamp}.{file_extension}"
    filepath = os.path.join(avatar_dir, filename)
    
    # ✅ Sauvegarder le fichier
    try:
        with open(filepath, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la sauvegarde: {str(e)}"
        )
    
    # ✅ Supprimer l'ancien avatar s'il existe
    if current_user.avatar_url:
        old_avatar_path = current_user.avatar_url.lstrip('/')
        if os.path.exists(old_avatar_path):
            try:
                os.remove(old_avatar_path)
            except Exception:
                pass  # Ignorer les erreurs de suppression
    
    # ✅ Mettre à jour l'utilisateur
    avatar_url = f"/uploads/avatars/{filename}"
    current_user.avatar_url = avatar_url
    db.commit()
    db.refresh(current_user)
    
    return {
        "avatar_url": avatar_url,
        "message": "Photo de profil mise à jour avec succès"
    }

@router.delete("/me/avatar", status_code=status.HTTP_204_NO_CONTENT)
def delete_avatar(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Supprime la photo de profil de l'utilisateur"""
    if current_user.avatar_url:
        # ✅ Supprimer le fichier
        avatar_path = current_user.avatar_url.lstrip('/')
        if os.path.exists(avatar_path):
            try:
                os.remove(avatar_path)
            except Exception:
                pass  # Ignorer les erreurs de suppression
        
        # ✅ Supprimer l'URL de la base de données
        current_user.avatar_url = None
        db.commit()
        db.refresh(current_user)
    
    return None

# ============================================================
#  CHANGEMENT DE MOT DE PASSE
# ============================================================

@router.put("/me/password", status_code=status.HTTP_204_NO_CONTENT)
def change_password(
    current_password: str,
    new_password: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Change le mot de passe de l'utilisateur"""
    from ....core.security import verify_password, get_password_hash
    
    # ✅ Vérifier l'ancien mot de passe
    if not verify_password(current_password, current_user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Mot de passe actuel incorrect"
        )
    
    # ✅ Vérifier la complexité du nouveau mot de passe
    if len(new_password) < 8:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le mot de passe doit contenir au moins 8 caractères"
        )
    
    # ✅ Mettre à jour le mot de passe
    current_user.password_hash = get_password_hash(new_password)
    db.commit()
    
    return None