# backend/app/api/v1/routes/books.py

from fastapi import APIRouter, Depends, HTTPException, status, Query, File, UploadFile, Form
from sqlalchemy.orm import Session
from typing import Optional, List
import os
import shutil
from datetime import datetime
from ....core.database import get_db
from ....core.dependencies import get_current_active_user, get_current_active_user_optional
from ....models.user import User
from ....repositories.book_repository import BookRepository
from ..schemas.book_schemas import (
    BookCreate,
    BookUpdate,
    BookResponse,
    BookListResponse,
    BookCommentCreate,
    BookCommentUpdate,
    BookCommentResponse,
    CommentLikeResponse
)


router = APIRouter(prefix="/books", tags=["Bibliothèque"])

# ============================================================
#  UPLOAD DE FICHIERS
# ============================================================

@router.post("/upload")
async def upload_file(
    file: UploadFile = File(...),
    type: str = Form(...),
    current_user: User = Depends(get_current_active_user),
):
    """Upload un fichier (PDF ou image)"""
    # Créer le dossier
    folder = "pdfs" if type == "pdf" else "covers"
    os.makedirs(f"uploads/{folder}", exist_ok=True)
    
    # Générer un nom unique
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{timestamp}_{file.filename}"
    filepath = f"uploads/{folder}/{filename}"
    
    # Sauvegarder
    with open(filepath, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # Retourner l'URL
    return {"url": f"/uploads/{folder}/{filename}"}

# ============================================================
#  LIVRES - ROUTES PUBLIQUES
# ============================================================

@router.get("", response_model=BookListResponse)
def get_books(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    level: Optional[str] = None,
    subject_id: Optional[int] = None,
    search: Optional[str] = None,
    user_id: Optional[int] = None,
    db: Session = Depends(get_db),
):
    """Récupère la liste des livres avec filtres"""
    repo = BookRepository(db)
    result = repo.get_books(
        skip=skip,
        limit=limit,
        level=level,
        subject_id=subject_id,
        search=search,
        user_id=user_id,
    )
    return result

@router.get("/{book_id}", response_model=BookResponse)
def get_book(
    book_id: int,
    db: Session = Depends(get_db),
):
    """Récupère un livre par son ID"""
    repo = BookRepository(db)
    book = repo.get_book_by_id(book_id)
    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Livre non trouvé"
        )
    return book

# ============================================================
#  LIVRES - ROUTES PROTÉGÉES (nécessitent authentification)
# ============================================================

@router.post("", response_model=BookResponse, status_code=status.HTTP_201_CREATED)
def create_book(
    book: BookCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),  # ✅ Requis
):
    """Crée un nouveau livre (nécessite authentification)"""
    repo = BookRepository(db)
    return repo.create_book(current_user.id, book.model_dump())

@router.put("/{book_id}", response_model=BookResponse)
def update_book(
    book_id: int,
    book: BookUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),  # ✅ Requis
):
    """Met à jour un livre (nécessite authentification)"""
    repo = BookRepository(db)
    updated_book = repo.update_book(book_id, current_user.id, book.model_dump(exclude_unset=True))
    if not updated_book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Livre non trouvé ou vous n'êtes pas l'auteur"
        )
    return updated_book

@router.delete("/{book_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_book(
    book_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),  # ✅ Requis
):
    """Supprime un livre (nécessite authentification)"""
    repo = BookRepository(db)
    if not repo.delete_book(book_id, current_user.id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Livre non trouvé ou vous n'êtes pas l'auteur"
        )

@router.post("/{book_id}/like", response_model=bool)
def toggle_like(
    book_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),  # ✅ Requis
):
    """Ajoute ou retire un like (nécessite authentification)"""
    repo = BookRepository(db)
    return repo.toggle_like(book_id, current_user.id)

@router.get("/{book_id}/like", response_model=bool)
def get_user_like(
    book_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),  # ✅ Requis
):
    """Vérifie si l'utilisateur a liké le livre (nécessite authentification)"""
    repo = BookRepository(db)
    return repo.get_user_like(book_id, current_user.id)

# ============================================================
#  COMMENTAIRES
# ============================================================

@router.get("/{book_id}/comments", response_model=List[BookCommentResponse])
def get_comments(
    book_id: int,
    db: Session = Depends(get_db),
    # ✅ Retirer la dépendance optionnelle (public)
):
    """Récupère les commentaires d'un livre (public)"""
    repo = BookRepository(db)
    comments = repo.get_comments_for_book(book_id)
    return comments

# backend/app/api/v1/routes/books.py

@router.post("/{book_id}/comments", response_model=BookCommentResponse, status_code=status.HTTP_201_CREATED)
def create_comment(
    book_id: int,
    comment: BookCommentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Ajoute un commentaire à un livre"""
    repo = BookRepository(db)
    
    try:
        result = repo.create_comment(
            book_id=book_id,
            user_id=current_user.id,
            content=comment.content,
            parent_id=comment.parent_id,  
        )
        return result
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
@router.put("/comments/{comment_id}", response_model=BookCommentResponse)
def update_comment(
    comment_id: int,
    comment: BookCommentUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),  # ✅ Requis
):
    """Met à jour un commentaire (nécessite authentification)"""
    repo = BookRepository(db)
    updated = repo.update_comment(comment_id, current_user.id, comment.content)
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Commentaire non trouvé ou vous n'êtes pas l'auteur"
        )
    return updated

@router.delete("/comments/{comment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_comment(
    comment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),  # ✅ Requis
):
    """Supprime un commentaire (nécessite authentification)"""
    repo = BookRepository(db)
    if not repo.delete_comment(comment_id, current_user.id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Commentaire non trouvé ou vous n'êtes pas l'auteur"
        )
        
        
@router.post("/comments/{comment_id}/like", response_model=bool)
def toggle_comment_like(
    comment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Ajoute ou retire un like sur un commentaire"""
    repo = BookRepository(db)
    return repo.toggle_comment_like(comment_id, current_user.id)


