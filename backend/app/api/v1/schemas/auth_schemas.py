# backend/app/api/v1/schemas/auth_schemas.py

from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional, Dict, Any
from datetime import datetime, date
from enum import Enum

class UserRole(str, Enum):
    STUDENT = "student"
    TEACHER = "teacher"
    ADMIN = "admin"

# ============================================================
#  INSCRIPTION
# ============================================================

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=72)
    first_name: str = Field(..., min_length=2, max_length=100)
    last_name: str = Field(..., min_length=2, max_length=100)
    level: Optional[str] = None
    school: Optional[str] = None
    phone_number: Optional[str] = None
    role: UserRole = UserRole.STUDENT

    @field_validator('password')
    def validate_password(cls, v):
        if len(v) > 72:
            raise ValueError('Le mot de passe ne peut pas dépasser 72 caractères')
        return v

class RegisterResponse(BaseModel):
    id: int
    email: str
    first_name: str
    last_name: str
    level: Optional[str]
    school: Optional[str]
    role: UserRole
    created_at: datetime

    class Config:
        from_attributes = True

# ============================================================
#  CONNEXION
# ============================================================

class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., max_length=72)

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: Optional['UserResponse'] = None

class RefreshTokenRequest(BaseModel):
    refresh_token: str

# ============================================================
#  UTILISATEUR (PROFIL COMPLET)
# ============================================================

class UserResponse(BaseModel):
    id: int
    email: str
    first_name: str
    last_name: str
    full_name: Optional[str] = None
    level: Optional[str]
    avatar_url: Optional[str]
    bio: Optional[str]
    school: Optional[str]
    phone_number: Optional[str]
    birth_date: Optional[date]
    preferences: Optional[Dict[str, Any]] = {}
    role: str
    is_active: bool
    is_verified: bool
    created_at: datetime
    last_login: Optional[datetime]

    class Config:
        from_attributes = True

# ============================================================
#  MISE À JOUR DU PROFIL
# ============================================================

class UserUpdateRequest(BaseModel):
    first_name: Optional[str] = Field(None, min_length=2, max_length=100)
    last_name: Optional[str] = Field(None, min_length=2, max_length=100)
    level: Optional[str] = None
    avatar_url: Optional[str] = None
    bio: Optional[str] = Field(None, max_length=500)
    school: Optional[str] = None
    phone_number: Optional[str] = None
    birth_date: Optional[date] = None
    preferences: Optional[Dict[str, Any]] = None

# ============================================================
#  CHANGEMENT DE MOT DE PASSE
# ============================================================

class PasswordChangeRequest(BaseModel):
    current_password: str = Field(..., min_length=8, max_length=72)
    new_password: str = Field(..., min_length=8, max_length=72)

    @field_validator('new_password')
    def validate_new_password(cls, v):
        if len(v) < 8:
            raise ValueError('Le mot de passe doit contenir au moins 8 caractères')
        if len(v) > 72:
            raise ValueError('Le mot de passe ne peut pas dépasser 72 caractères')
        return v

# ============================================================
#  SUPPRESSION DU COMPTE
# ============================================================

class AccountDeleteRequest(BaseModel):
    password: str = Field(..., max_length=72)
    confirm: bool = Field(..., description="Confirmation de suppression")

# ============================================================
#  FORWARD REFERENCES
# ============================================================

TokenResponse.model_rebuild()