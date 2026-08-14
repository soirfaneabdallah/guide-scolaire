# backend/app/models/user.py

from sqlalchemy import Column, Integer, String, DateTime, Boolean, Enum, Text, Date, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from ..core.database import Base
import enum

class UserRole(str, enum.Enum):
    STUDENT = "student"
    TEACHER = "teacher"
    ADMIN = "admin"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    
    # Identité
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    level = Column(String(50), nullable=True)
    
    # Profil
    avatar_url = Column(String(500), nullable=True)
    bio = Column(Text, nullable=True)
    school = Column(String(255), nullable=True)
    phone_number = Column(String(50), nullable=True)
    birth_date = Column(Date, nullable=True)
    preferences = Column(JSON, nullable=True, default={})
    
    # Rôle et statut
    role = Column(Enum(UserRole), default=UserRole.STUDENT)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    
    # Suivi temporel
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_login = Column(DateTime(timezone=True), nullable=True)

    # Relations
    user_subjects = relationship("UserSubject", back_populates="user", cascade="all, delete-orphan")
    chat_history = relationship("ChatHistory", back_populates="user", cascade="all, delete-orphan")