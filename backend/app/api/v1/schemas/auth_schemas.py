# backend/app/api/v1/schemas/auth_schemas.py

from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional, Dict, Any
from datetime import datetime, date
from enum import Enum

class UserRole(str, Enum):
    STUDENT = "student"  # ✅ en minuscules
    TEACHER = "teacher"  # ✅ en minuscules
    ADMIN = "admin"      # ✅ en minuscules

# === Inscription ===
class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=72)
    first_name: str = Field(..., min_length=2, max_length=100)
    last_name: str = Field(..., min_length=2, max_length=100)
    level: Optional[str] = None
    school: Optional[str] = None
    phone_number: Optional[str] = None
    role: UserRole = UserRole.STUDENT

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

# === Connexion ===
class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., max_length=72)

# ✅ TokenResponse avec utilisateur
class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: Optional['UserResponse'] = None

class RefreshTokenRequest(BaseModel):
    refresh_token: str

# === Utilisateur (profil complet) ===
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
    preferences: Optional[Dict[str, Any]] = {}  # ✅ Dictionnaire
    role: str  # ✅ String simple (student, teacher, admin)
    is_active: bool
    is_verified: bool
    created_at: datetime
    last_login: Optional[datetime]

    class Config:
        from_attributes = True

# === Mise à jour du profil ===
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

# ✅ Forward reference
TokenResponse.model_rebuild()