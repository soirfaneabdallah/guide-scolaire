# backend/app/repositories/book_repository.py

from typing import Optional, List, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import desc, or_
import os
import shutil
from fastapi import UploadFile
from ..models.book import Book
from ..models.book_comment import BookComment
from ..models.book_like import BookLike
from ..models.user import User
from ..models.subject import Subject
from ..core.config import settings
from ..models.comment_like import CommentLike


class BookRepository:
    def __init__(self, db: Session):
        self.db = db

    def _get_full_url(self, path: str) -> Optional[str]:
        """Retourne l'URL complète si c'est un chemin local"""
        if not path:
            return None
        
        # ✅ Si c'est déjà une URL complète (http:// ou https://), la retourner directement
        if path.startswith('http://') or path.startswith('https://'):
            return path
        
        # ✅ Si c'est un chemin local, ajouter le préfixe
        if path.startswith('/uploads/'):
            return f"{settings.BASE_URL}{path}"
        
        # ✅ Si c'est un chemin relatif
        if path.startswith('uploads/'):
            return f"{settings.BASE_URL}/{path}"
        
        return path

    def save_file(self, file: UploadFile, folder: str) -> str:
        """Sauvegarde un fichier et retourne son URL"""
        os.makedirs(f"uploads/{folder}", exist_ok=True)
        
        from datetime import datetime
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{timestamp}_{file.filename}"
        filepath = f"uploads/{folder}/{filename}"
        
        with open(filepath, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # ✅ Retourner le chemin relatif (pas l'URL complète)
        return f"/{filepath}"

    def get_books(
        self,
        skip: int = 0,
        limit: int = 20,
        level: Optional[str] = None,
        subject_id: Optional[int] = None,
        search: Optional[str] = None,
        user_id: Optional[int] = None,
    ) -> Dict[str, Any]:
        """Récupère les livres avec filtres"""
        query = self.db.query(Book).filter(Book.is_public == True)
        
        if user_id:
            query = query.filter(Book.user_id == user_id)
        
        if level:
            query = query.filter(Book.level == level)
        
        if subject_id:
            query = query.filter(Book.subject_id == subject_id)
        
        if search:
            query = query.filter(
                or_(
                    Book.title.ilike(f"%{search}%"),
                    Book.description.ilike(f"%{search}%"),
                    Book.author.ilike(f"%{search}%"),
                )
            )
        
        total = query.count()
        total_pages = (total + limit - 1) // limit
        
        books = query.order_by(desc(Book.created_at)).offset(skip).limit(limit).all()
        
        books_data = []
        for book in books:
            user = self.db.query(User).filter(User.id == book.user_id).first()
            user_name = user.full_name if user else "Anonyme"
            
            subject = self.db.query(Subject).filter(Subject.id == book.subject_id).first()
            subject_name = subject.name if subject else None
            
            # ✅ Utiliser la fonction pour les URLs
            cover_url = self._get_full_url(book.cover_image)
            file_url = self._get_full_url(book.file_url)
            
            books_data.append({
                "id": book.id,
                "title": book.title,
                "description": book.description,
                "author": book.author,
                "cover_image": cover_url,
                "file_url": file_url,
                "level": book.level,
                "subject_id": book.subject_id,
                "subject": subject_name,
                "user_id": book.user_id,
                "user_name": user_name,
                "is_public": book.is_public,
                "views_count": book.views_count,
                "likes_count": book.likes_count,
                "comments_count": book.comments_count,
                "average_rating": book.average_rating,
                "created_at": book.created_at.isoformat() if book.created_at else None,
                "updated_at": book.updated_at.isoformat() if book.updated_at else None,
            })
        
        return {
            "books": books_data,
            "total": total,
            "page": skip // limit + 1,
            "page_size": limit,
            "total_pages": total_pages,
        }

    def get_book_by_id(self, book_id: int) -> Optional[dict]:
        """Récupère un livre par son ID"""
        book = self.db.query(Book).filter(Book.id == book_id).first()
        if not book:
            return None
        
        book.views_count += 1
        self.db.commit()
        self.db.refresh(book)
        
        user = self.db.query(User).filter(User.id == book.user_id).first()
        user_name = user.full_name if user else "Anonyme"
        
        subject = self.db.query(Subject).filter(Subject.id == book.subject_id).first()
        subject_name = subject.name if subject else None
        
        # ✅ Utiliser la fonction pour les URLs
        cover_url = self._get_full_url(book.cover_image)
        file_url = self._get_full_url(book.file_url)
        
        return {
            "id": book.id,
            "title": book.title,
            "description": book.description,
            "author": book.author,
            "cover_image": cover_url,
            "file_url": file_url,
            "level": book.level,
            "subject_id": book.subject_id,
            "subject": subject_name,
            "user_id": book.user_id,
            "user_name": user_name,
            "is_public": book.is_public,
            "views_count": book.views_count,
            "likes_count": book.likes_count,
            "comments_count": book.comments_count,
            "average_rating": book.average_rating,
            "created_at": book.created_at.isoformat() if book.created_at else None,
            "updated_at": book.updated_at.isoformat() if book.updated_at else None,
        }

    def create_book(self, user_id: int, book_data: dict) -> dict:
        """Crée un nouveau livre"""
        # ✅ Nettoyer les URLs avant de stocker
        cover_image = book_data.get('cover_image')
        file_url = book_data.get('file_url')
        
        # ✅ Si c'est une URL complète, la convertir en chemin relatif
        if cover_image and cover_image.startswith('http'):
            cover_image = cover_image.replace(settings.BASE_URL, '')
        if file_url and file_url.startswith('http'):
            file_url = file_url.replace(settings.BASE_URL, '')
        
        book = Book(
            user_id=user_id,
            title=book_data.get('title'),
            description=book_data.get('description'),
            author=book_data.get('author'),
            cover_image=cover_image,
            file_url=file_url,
            level=book_data.get('level'),
            subject_id=book_data.get('subject_id'),
            is_public=book_data.get('is_public', True),
        )
        
        self.db.add(book)
        self.db.commit()
        self.db.refresh(book)
        
        user = self.db.query(User).filter(User.id == user_id).first()
        user_name = user.full_name if user else "Anonyme"
        
        subject = self.db.query(Subject).filter(Subject.id == book.subject_id).first()
        subject_name = subject.name if subject else None
        
        # ✅ Utiliser la fonction pour les URLs
        cover_url = self._get_full_url(book.cover_image)
        file_url_full = self._get_full_url(book.file_url)
        
        return {
            "id": book.id,
            "title": book.title,
            "description": book.description,
            "author": book.author,
            "cover_image": cover_url,
            "file_url": file_url_full,
            "level": book.level,
            "subject_id": book.subject_id,
            "subject": subject_name,
            "user_id": book.user_id,
            "user_name": user_name,
            "is_public": book.is_public,
            "views_count": book.views_count,
            "likes_count": book.likes_count,
            "comments_count": book.comments_count,
            "average_rating": book.average_rating,
            "created_at": book.created_at.isoformat() if book.created_at else None,
            "updated_at": book.updated_at.isoformat() if book.updated_at else None,
        }

    def update_book(self, book_id: int, user_id: int, book_data: dict) -> Optional[dict]:
        """Met à jour un livre"""
        book = self.db.query(Book).filter(
            Book.id == book_id,
            Book.user_id == user_id
        ).first()
        
        if not book:
            return None
        
        # ✅ Nettoyer les URLs avant de stocker
        if 'cover_image' in book_data and book_data['cover_image']:
            cover = book_data['cover_image']
            if cover.startswith(settings.BASE_URL):
                book_data['cover_image'] = cover.replace(settings.BASE_URL, '')
        
        if 'file_url' in book_data and book_data['file_url']:
            file_url = book_data['file_url']
            if file_url.startswith(settings.BASE_URL):
                book_data['file_url'] = file_url.replace(settings.BASE_URL, '')
        
        for key, value in book_data.items():
            if value is not None and hasattr(book, key):
                setattr(book, key, value)
        
        self.db.commit()
        self.db.refresh(book)
        
        user = self.db.query(User).filter(User.id == user_id).first()
        user_name = user.full_name if user else "Anonyme"
        
        subject = self.db.query(Subject).filter(Subject.id == book.subject_id).first()
        subject_name = subject.name if subject else None
        
        # ✅ Utiliser la fonction pour les URLs
        cover_url = self._get_full_url(book.cover_image)
        file_url_full = self._get_full_url(book.file_url)
        
        return {
            "id": book.id,
            "title": book.title,
            "description": book.description,
            "author": book.author,
            "cover_image": cover_url,
            "file_url": file_url_full,
            "level": book.level,
            "subject_id": book.subject_id,
            "subject": subject_name,
            "user_id": book.user_id,
            "user_name": user_name,
            "is_public": book.is_public,
            "views_count": book.views_count,
            "likes_count": book.likes_count,
            "comments_count": book.comments_count,
            "average_rating": book.average_rating,
            "created_at": book.created_at.isoformat() if book.created_at else None,
            "updated_at": book.updated_at.isoformat() if book.updated_at else None,
        }

    def delete_book(self, book_id: int, user_id: int) -> bool:
        """Supprime un livre"""
        book = self.db.query(Book).filter(
            Book.id == book_id,
            Book.user_id == user_id
        ).first()
        
        if not book:
            return False
        
        self.db.delete(book)
        self.db.commit()
        return True

    def toggle_like(self, book_id: int, user_id: int) -> bool:
        """Ajoute ou retire un like"""
        existing = self.db.query(BookLike).filter(
            BookLike.book_id == book_id,
            BookLike.user_id == user_id
        ).first()
        
        book = self.db.query(Book).filter(Book.id == book_id).first()
        if not book:
            return False
        
        if existing:
            self.db.delete(existing)
            book.likes_count -= 1
            self.db.commit()
            return False
        else:
            like = BookLike(book_id=book_id, user_id=user_id)
            self.db.add(like)
            book.likes_count += 1
            self.db.commit()
            return True

    def get_user_like(self, book_id: int, user_id: int) -> bool:
        """Vérifie si l'utilisateur a liké un livre"""
        like = self.db.query(BookLike).filter(
            BookLike.book_id == book_id,
            BookLike.user_id == user_id
        ).first()
        return like is not None

    # backend/app/repositories/book_repository.py

    def get_comments_for_book(self, book_id: int) -> List[dict]:
        """Récupère les commentaires d'un livre (uniquement les parents)"""
        
        # ✅ Récupérer uniquement les commentaires parents (parent_id IS NULL)
        comments = self.db.query(BookComment).filter(
            BookComment.book_id == book_id,
            BookComment.parent_id == None  # ✅ Seulement les commentaires racines
        ).order_by(desc(BookComment.created_at)).all()
        
        # ✅ Convertir en dictionnaire avec les réponses
        result = []
        for comment in comments:
            result.append(comment.to_dict(include_replies=True))
        
        return result


    def create_comment(self, book_id: int, user_id: int, content: str, parent_id: Optional[int] = None) -> dict:
        """Crée un commentaire ou une réponse"""
        
        # ✅ Vérifier si le parent existe (si parent_id est fourni)
        if parent_id is not None:
            parent = self.db.query(BookComment).filter(BookComment.id == parent_id).first()
            if not parent:
                raise ValueError("Le commentaire parent n'existe pas")
            
            # ✅ Vérifier que le parent appartient au même livre
            if parent.book_id != book_id:
                raise ValueError("Le commentaire parent n'appartient pas à ce livre")
        
        comment = BookComment(
            book_id=book_id,
            user_id=user_id,
            content=content,
            parent_id=parent_id,  # ✅ Stocker parent_id
        )
        
        book = self.db.query(Book).filter(Book.id == book_id).first()
        if book:
            book.comments_count += 1
        
        self.db.add(comment)
        self.db.commit()
        self.db.refresh(comment)
        
        # ✅ Retourner le commentaire avec ses réponses
        return comment.to_dict()

    def update_comment(self, comment_id: int, user_id: int, content: str) -> Optional[dict]:
        """Met à jour un commentaire"""
        comment = self.db.query(BookComment).filter(
            BookComment.id == comment_id,
            BookComment.user_id == user_id
        ).first()
        
        if not comment:
            return None
        
        comment.content = content
        comment.is_edited = True
        self.db.commit()
        self.db.refresh(comment)
        
        user = self.db.query(User).filter(User.id == user_id).first()
        user_name = user.full_name if user else "Anonyme"
        
        return {
            "id": comment.id,
            "content": comment.content,
            "book_id": comment.book_id,
            "user_id": comment.user_id,
            "user_name": user_name,
            "user_avatar": user.avatar_url if user else None,
            "parent_id": comment.parent_id,
            "is_edited": comment.is_edited,
            "likes_count": comment.likes_count,
            "created_at": comment.created_at.isoformat() if comment.created_at else None,
            "updated_at": comment.updated_at.isoformat() if comment.updated_at else None,
            "replies": [],
        }

    def delete_comment(self, comment_id: int, user_id: int) -> bool:
        """Supprime un commentaire"""
        comment = self.db.query(BookComment).filter(
            BookComment.id == comment_id,
            BookComment.user_id == user_id
        ).first()
        
        if not comment:
            return False
        
        book = self.db.query(Book).filter(Book.id == comment.book_id).first()
        if book:
            book.comments_count -= 1
        
        self.db.delete(comment)
        self.db.commit()
        return True
    def toggle_comment_like(self, comment_id: int, user_id: int) -> bool:
        """Ajoute ou retire un like sur un commentaire"""
        # Vérifier si le commentaire existe
        comment = self.db.query(BookComment).filter(BookComment.id == comment_id).first()
        if not comment:
            return False
        
        # Vérifier si l'utilisateur a déjà liké
        existing = self.db.query(CommentLike).filter(
            CommentLike.comment_id == comment_id,
            CommentLike.user_id == user_id
        ).first()
        
        if existing:
            # Retirer le like
            self.db.delete(existing)
            comment.likes_count -= 1
            self.db.commit()
            return False  # Like retiré
        else:
            # Ajouter le like
            like = CommentLike(comment_id=comment_id, user_id=user_id)
            self.db.add(like)
            comment.likes_count += 1
            self.db.commit()
            return True  # Like ajouté

    def get_comments_for_book(self, book_id: int, user_id: Optional[int] = None) -> List[dict]:
        """Récupère les commentaires d'un livre (uniquement les parents)"""
        comments = self.db.query(BookComment).filter(
            BookComment.book_id == book_id,
            BookComment.parent_id == None
        ).order_by(desc(BookComment.created_at)).all()
        
        result = []
        for comment in comments:
            result.append(comment.to_dict(include_replies=True, user_id=user_id))
        
        return result