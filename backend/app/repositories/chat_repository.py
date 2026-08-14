# backend/app/repositories/chat_repository.py

from sqlalchemy.orm import Session
from sqlalchemy import and_, desc
from typing import List, Optional
from ..models.chat_history import ChatHistory
from ..models.subject import Subject
from ..models.user import User

class ChatRepository:
    def __init__(self, db: Session):
        self.db = db

    def save_message(
        self,
        user_id: int,
        subject_id: int,
        content: str,
        is_user: bool,
        level: str = "3ème",
        model_used: Optional[str] = None,
        processing_time: Optional[int] = None,
        is_error: bool = False,
    ) -> ChatHistory:
        """Sauvegarde un message dans l'historique"""
        message = ChatHistory(
            user_id=user_id,
            subject_id=subject_id,
            content=content,
            is_user=is_user,
            is_error=is_error,
            level=level,
            model_used=model_used,
            processing_time=processing_time,
        )
        self.db.add(message)
        self.db.commit()
        self.db.refresh(message)
        return message

    def get_messages_for_subject(
        self,
        user_id: int,
        subject_id: int,
        limit: int = 100,
        offset: int = 0,
    ) -> List[ChatHistory]:
        """Récupère l'historique des messages pour une matière"""
        return (
            self.db.query(ChatHistory)
            .filter(
                ChatHistory.user_id == user_id,
                ChatHistory.subject_id == subject_id,
            )
            .order_by(ChatHistory.created_at.asc())
            .offset(offset)
            .limit(limit)
            .all()
        )

    def get_all_subjects_with_messages(self, user_id: int) -> dict:
        """Récupère toutes les matières avec leurs messages"""
        # Récupérer toutes les matières de l'utilisateur
        subjects = self.db.query(Subject).join(
            ChatHistory, ChatHistory.subject_id == Subject.id
        ).filter(
            ChatHistory.user_id == user_id
        ).distinct().all()

        result = {}
        for subject in subjects:
            messages = self.get_messages_for_subject(user_id, subject.id)
            result[subject.slug] = {
                "subject_id": subject.id,
                "subject_name": subject.name,
                "subject_slug": subject.slug,
                "messages": messages,
            }
        return result

    def get_or_create_subject_by_slug(self, slug: str) -> Optional[Subject]:
        """Récupère une matière par son slug"""
        return self.db.query(Subject).filter(Subject.slug == slug).first()

    def clear_subject_history(self, user_id: int, subject_id: int) -> int:
        """Supprime l'historique d'une matière pour un utilisateur"""
        deleted = (
            self.db.query(ChatHistory)
            .filter(
                ChatHistory.user_id == user_id,
                ChatHistory.subject_id == subject_id,
            )
            .delete()
        )
        self.db.commit()
        return deleted