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

class UserSubjectBase(BaseModel):
    subject_id: int
    custom_name: Optional[str] = None
    custom_icon: Optional[str] = None
    custom_color: Optional[str] = None

class UserSubjectCreate(UserSubjectBase):
    pass

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
    subject: SubjectResponse  # Matière de base
    created_at: datetime

    class Config:
        from_attributes = True

class UserSubjectListResponse(BaseModel):
    """Réponse pour la liste des matières de l'utilisateur"""
    default_subjects: list[SubjectResponse]  # Matières par défaut
    custom_subjects: list[UserSubjectResponse]  # Matières personnalisées