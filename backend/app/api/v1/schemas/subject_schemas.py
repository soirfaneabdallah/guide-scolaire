# backend/app/api/v1/schemas/subject_schemas.py

from pydantic import BaseModel
from typing import Optional
from datetime import datetime

# ============================================================
#  SCHÉMAS MATIÈRES
# ============================================================

class SubjectBase(BaseModel):
    name: str
    icon: Optional[str] = None
    color: Optional[str] = None

class SubjectCreate(SubjectBase):
    pass

class SubjectUpdate(BaseModel):
    name: Optional[str] = None
    icon: Optional[str] = None
    color: Optional[str] = None

class SubjectResponse(SubjectBase):
    id: int
    is_default: bool
    created_at: datetime

    class Config:
        from_attributes = True


# ============================================================
#  SCHÉMAS MATIÈRES UTILISATEUR
# ============================================================

class UserSubjectCreate(BaseModel):
    # ✅ Plus de subject_id ! Le backend va le générer
    name: str  # Le nom de la nouvelle matière
    icon: Optional[str] = None
    color: Optional[str] = None
    custom_name: Optional[str] = None  # Nom personnalisé pour l'utilisateur
    custom_icon: Optional[str] = None
    custom_color: Optional[str] = None

class UserSubjectUpdate(BaseModel):
    custom_name: Optional[str] = None
    custom_icon: Optional[str] = None
    custom_color: Optional[str] = None
    is_active: Optional[bool] = None

class UserSubjectResponse(BaseModel):
    id: int
    user_id: int
    subject_id: int
    custom_name: Optional[str] = None
    custom_icon: Optional[str] = None
    custom_color: Optional[str] = None
    is_active: bool
    subject: SubjectResponse
    created_at: datetime

    class Config:
        from_attributes = True

class UserSubjectListResponse(BaseModel):
    """Réponse pour la liste des matières de l'utilisateur"""
    default_subjects: list[SubjectResponse]
    custom_subjects: list[UserSubjectResponse]