# backend/app/api/v1/routes/subjects.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from ....core.database import get_db
from ....core.dependencies import get_current_active_user
from ....models.user import User
from ....repositories.subject_repository import SubjectRepository
from .subject_schemas import (
    SubjectResponse,
    SubjectCreate,
    SubjectUpdate,
    UserSubjectCreate,
    UserSubjectUpdate,
    UserSubjectResponse,
    UserSubjectListResponse,
)

router = APIRouter(prefix="/subjects", tags=["Matières"])

# ============================================================
#  MATIÈRES PAR DÉFAUT
# ============================================================

@router.get("/default", response_model=List[SubjectResponse])
def get_default_subjects(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Récupère toutes les matières par défaut"""
    repo = SubjectRepository(db)
    return repo.get_default_subjects()


# ============================================================
#  MATIÈRES UTILISATEUR
# ============================================================

@router.get("/me", response_model=UserSubjectListResponse)
def get_my_subjects(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Récupère toutes les matières de l'utilisateur connecté"""
    repo = SubjectRepository(db)
    result = repo.get_all_user_subjects_with_defaults(current_user.id)
    return UserSubjectListResponse(
        default_subjects=result["default_subjects"],
        custom_subjects=result["custom_subjects"]
    )


@router.post("/me", response_model=UserSubjectResponse, status_code=status.HTTP_201_CREATED)
def add_subject_to_user(
    request: UserSubjectCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Ajoute une matière à l'utilisateur connecté"""
    repo = SubjectRepository(db)

    # Vérifier que la matière existe
    subject = repo.get_subject_by_id(request.subject_id)
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Matière non trouvée"
        )

    # Ajouter la matière à l'utilisateur
    user_subject = repo.add_subject_to_user(
        user_id=current_user.id,
        subject_id=request.subject_id,
        custom_name=request.custom_name,
        custom_icon=request.custom_icon,
        custom_color=request.custom_color,
    )

    return user_subject


@router.put("/me/{subject_id}", response_model=UserSubjectResponse)
def update_user_subject(
    subject_id: int,
    request: UserSubjectUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Met à jour une matière personnalisée de l'utilisateur"""
    repo = SubjectRepository(db)

    user_subject = repo.update_user_subject(
        user_id=current_user.id,
        subject_id=subject_id,
        **request.model_dump(exclude_unset=True)
    )

    if not user_subject:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Matière non trouvée pour cet utilisateur"
        )

    return user_subject


@router.delete("/me/{subject_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_subject_from_user(
    subject_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Supprime une matière de l'utilisateur connecté"""
    repo = SubjectRepository(db)

    # Vérifier que la matière existe
    subject = repo.get_subject_by_id(subject_id)
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Matière non trouvée"
        )

    # Si c'est une matière par défaut, on l'ajoute aux matières de l'utilisateur puis on la désactive
    if subject.is_default:
        # Ajouter la relation si elle n'existe pas
        repo.add_subject_to_user(current_user.id, subject_id)
        # La désactiver
        removed = repo.remove_subject_from_user(current_user.id, subject_id)
    else:
        # Sinon on la supprime directement
        removed = repo.remove_subject_from_user(current_user.id, subject_id)

    if not removed:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Matière non trouvée pour cet utilisateur"
        )

    return None