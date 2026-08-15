# backend/app/repositories/subject_repository.py

from sqlalchemy.orm import Session
from sqlalchemy import and_
from typing import List, Optional
from ..models.subject import Subject, UserSubject
from ..models.user import User

class SubjectRepository:
    def __init__(self, db: Session):
        self.db = db

    # ============================================================
    #  MATIÈRES PAR DÉFAUT
    # ============================================================

    def get_default_subjects(self) -> List[Subject]:
        """Récupère toutes les matières par défaut"""
        return self.db.query(Subject).filter(Subject.is_default == True).all()

    def get_subject_by_id(self, subject_id: int) -> Optional[Subject]:
        return self.db.query(Subject).filter(Subject.id == subject_id).first()

    def get_subject_by_slug(self, slug: str) -> Optional[Subject]:
        return self.db.query(Subject).filter(Subject.slug == slug).first()
    # backend/app/repositories/subject_repository.py

    def get_subject_by_name(self, name: str) -> Optional[Subject]:
        """Récupère une matière par son nom"""
        return self.db.query(Subject).filter(Subject.name == name).first()
    # ============================================================
    #  INITIALISATION DES MATIÈRES PAR DÉFAUT (CORRIGÉE)
    # ============================================================

    def init_default_subjects(self):
        """Initialise les matières par défaut avec slug correct"""
        default_subjects = [
            {"name": "Mathématiques", "slug": "mathematiques", "icon": "📐", "color": "#4CAF50"},
            {"name": "Français", "slug": "francais", "icon": "📖", "color": "#2196F3"},
            {"name": "Physique-Chimie", "slug": "physique", "icon": "⚡", "color": "#FF9800"},
            {"name": "SVT", "slug": "svt", "icon": "🧬", "color": "#9C27B0"},
            {"name": "Histoire-Géographie", "slug": "histoire", "icon": "🏛️", "color": "#795548"},
            {"name": "Anglais", "slug": "anglais", "icon": "🗣️", "color": "#F44336"},
        ]

        for subject_data in default_subjects:
            existing = self.db.query(Subject).filter(
                Subject.name == subject_data["name"],
                Subject.is_default == True
            ).first()
            if not existing:
                subject = Subject(
                    name=subject_data["name"],
                    slug=subject_data["slug"],  # 👈 Utiliser le slug défini
                    icon=subject_data["icon"],
                    color=subject_data["color"],
                    is_default=True
                )
                self.db.add(subject)

        self.db.commit()

    # ============================================================
    #  MATIÈRES UTILISATEUR
    # ============================================================

    def get_user_subjects(self, user_id: int) -> List[UserSubject]:
        """Récupère toutes les matières personnalisées d'un utilisateur"""
        return self.db.query(UserSubject).filter(
            UserSubject.user_id == user_id,
            UserSubject.is_active == True
        ).all()

    def get_all_user_subjects_with_defaults(self, user_id: int) -> dict:
        """Récupère les matières par défaut + les matières personnalisées de l'utilisateur"""
        default_subjects = self.get_default_subjects()
        custom_subjects = self.get_user_subjects(user_id)

        return {
            "default_subjects": default_subjects,
            "custom_subjects": custom_subjects
        }

    def add_subject_to_user(self, user_id: int, subject_id: int, **kwargs) -> UserSubject:
        """Ajoute une matière à un utilisateur"""
        existing = self.db.query(UserSubject).filter(
            UserSubject.user_id == user_id,
            UserSubject.subject_id == subject_id
        ).first()

        if existing:
            existing.is_active = True
            existing.custom_name = kwargs.get('custom_name', existing.custom_name)
            existing.custom_icon = kwargs.get('custom_icon', existing.custom_icon)
            existing.custom_color = kwargs.get('custom_color', existing.custom_color)
            self.db.commit()
            self.db.refresh(existing)
            return existing

        user_subject = UserSubject(
            user_id=user_id,
            subject_id=subject_id,
            custom_name=kwargs.get('custom_name'),
            custom_icon=kwargs.get('custom_icon'),
            custom_color=kwargs.get('custom_color'),
            is_active=True
        )
        self.db.add(user_subject)
        self.db.commit()
        self.db.refresh(user_subject)
        return user_subject

    def remove_subject_from_user(self, user_id: int, subject_id: int) -> bool:
        """Supprime une matière d'un utilisateur (désactive)"""
        user_subject = self.db.query(UserSubject).filter(
            UserSubject.user_id == user_id,
            UserSubject.subject_id == subject_id
        ).first()

        if user_subject:
            user_subject.is_active = False
            self.db.commit()
            return True
        return False

    def update_user_subject(self, user_id: int, subject_id: int, **kwargs) -> Optional[UserSubject]:
        """Met à jour une matière personnalisée"""
        user_subject = self.db.query(UserSubject).filter(
            UserSubject.user_id == user_id,
            UserSubject.subject_id == subject_id
        ).first()

        if not user_subject:
            return None

        for key, value in kwargs.items():
            if hasattr(user_subject, key) and value is not None:
                setattr(user_subject, key, value)

        self.db.commit()
        self.db.refresh(user_subject)
        return user_subject