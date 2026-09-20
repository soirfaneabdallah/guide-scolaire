# ============================================================
# FICHIER: backend/app/models/chapter.py
# DESCRIPTION: Modèle pour les chapitres
# ============================================================

from sqlalchemy import Column, Integer, String, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.core.database import Base


class Chapter(Base):
    """
    Chapitre pour organiser les vidéos.
    Ex: "Géométrie", "Algèbre", "Statistiques"
    """
    __tablename__ = "chapters"
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    slug = Column(String(100), nullable=False, index=True)
    
    # Classification
    subject_id = Column(Integer, ForeignKey("subjects.id"), nullable=False, index=True)
    level = Column(String(50), nullable=True, index=True)
    order_index = Column(Integer, default=0)
    
    # Métadonnées
    icon = Column(String(50), nullable=True)
    color = Column(String(20), nullable=True)
    description = Column(Text, nullable=True)
    
    # Relations
    subject = relationship("Subject", back_populates="chapters")
    
    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "slug": self.slug,
            "subject_id": self.subject_id,
            "level": self.level,
            "icon": self.icon,
            "color": self.color,
            "description": self.description,
        }