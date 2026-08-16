# backend/app/api/v1/schemas/book_schemas.py

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

# ============================================================
#  SCHÉMAS LIVRE
# ============================================================

class BookBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    description: str = Field(..., min_length=1)
    author: str = Field(..., min_length=1, max_length=255)
    cover_image: Optional[str] = None
    file_url: Optional[str] = None
    level: Optional[str] = None
    subject_id: Optional[int] = None
    is_public: bool = True

class BookCreate(BookBase):
    pass

class BookUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    author: Optional[str] = None
    cover_image: Optional[str] = None
    file_url: Optional[str] = None
    level: Optional[str] = None
    subject_id: Optional[int] = None
    is_public: Optional[bool] = None

class BookResponse(BookBase):
    id: int
    user_id: int
    user_name: str
    subject: Optional[str] = None
    views_count: int
    likes_count: int
    comments_count: int
    average_rating: float
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class BookListResponse(BaseModel):
    books: List[BookResponse]
    total: int
    page: int
    page_size: int
    total_pages: int

# ============================================================
#  SCHÉMAS COMMENTAIRE
# ============================================================

class BookCommentBase(BaseModel):
    content: str = Field(..., min_length=1)
    parent_id: Optional[int] = None

class BookCommentCreate(BookCommentBase):
    pass

class BookCommentUpdate(BaseModel):
    content: str = Field(..., min_length=1)

class BookCommentResponse(BookCommentBase):
    id: int
    user_id: int
    user_name: str
    user_avatar: Optional[str] = None
    is_edited: bool
    likes_count: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    replies: List['BookCommentResponse'] = []

    class Config:
        from_attributes = True

# ============================================================
#  SCHÉMAS LIKE
# ============================================================

class BookLikeResponse(BaseModel):
    id: int
    book_id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True
        
        
# backend/app/api/v1/schemas/book_schemas.py

class BookCommentResponse(BookCommentBase):
    id: int
    user_id: int
    user_name: str
    user_avatar: Optional[str] = None
    is_edited: bool
    likes_count: int
    is_liked: bool = False  # ✅ Ajouter pour savoir si l'utilisateur a liké
    created_at: datetime
    updated_at: Optional[datetime] = None
    replies: List['BookCommentResponse'] = []

    class Config:
        from_attributes = True

class CommentLikeResponse(BaseModel):
    id: int
    comment_id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True