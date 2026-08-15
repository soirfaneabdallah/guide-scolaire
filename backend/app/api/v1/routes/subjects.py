# backend/app/api/v1/routes/subjects.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from ....core.database import get_db
from ....core.dependencies import get_current_active_user
from ....models.user import User
from ....repositories.subject_repository import SubjectRepository
from ....models.subject import Subject  # ✅ AJOUTER CET IMPORT
from ....models.subject import UserSubject  # ✅ AJOUTER AUSSI
# ✅ Import depuis le dossier schemas
from ....api.v1.schemas.subject_schemas import (
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


# backend/app/api/v1/routes/subjects.py

# backend/app/api/v1/routes/subjects.py

@router.post("/me", response_model=UserSubjectResponse, status_code=status.HTTP_201_CREATED)
def add_subject_to_user(
    request: UserSubjectCreate,  # Le schéma modifié
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Crée une nouvelle matière personnalisée pour l'utilisateur
    """
    repo = SubjectRepository(db)
    
    # ✅ 1. Vérifier si une matière avec ce nom existe déjà
    existing_subject = repo.get_subject_by_name(request.name)
    
    if existing_subject:
        # Si la matière existe déjà, l'utiliser
        subject = existing_subject
        print(f"📚 Matière existante trouvée: {subject.name} (ID: {subject.id})")
    else:
        # ✅ 2. Créer une NOUVELLE matière (l'ID est auto-généré)
        # Générer un slug à partir du nom
        slug = request.name.lower().replace(' ', '-').replace('é', 'e').replace('è', 'e')
        slug = ''.join(c for c in slug if c.isalnum() or c == '-')
        
        subject = Subject(
            name=request.name,
            slug=slug,
            icon=request.icon or "default",
            color=request.color or "#000000",
            is_default=False  # Matière personnalisée
        )
        db.add(subject)
        db.commit()
        db.refresh(subject)
        print(f"✅ Nouvelle matière créée: {subject.name} (ID: {subject.id})")
    
    # ✅ 3. Vérifier si l'utilisateur a déjà cette matière
    existing = db.query(UserSubject).filter(
        UserSubject.user_id == current_user.id,
        UserSubject.subject_id == subject.id
    ).first()
    
    if existing:
        # Si déjà associé, réactiver si nécessaire
        if not existing.is_active:
            existing.is_active = True
            db.commit()
            db.refresh(existing)
        return existing
    
    # ✅ 4. Associer la matière à l'utilisateur
    user_subject = UserSubject(
        user_id=current_user.id,
        subject_id=subject.id,
        custom_name=request.custom_name or request.name,
        custom_icon=request.custom_icon or request.icon,
        custom_color=request.custom_color or request.color,
        is_active=True
    )
    db.add(user_subject)
    db.commit()
    db.refresh(user_subject)
    
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