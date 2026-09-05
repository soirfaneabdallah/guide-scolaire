# ============================================================
# FICHIER: backend/app/models/video_quota.py
# DESCRIPTION: Modele UserQuota pour la gestion des quotas
# ============================================================

from sqlalchemy import Column, Integer, DateTime, ForeignKey, JSON, String
from datetime import datetime, timedelta
from app.core.database import Base


class UserQuota(Base):
    """Modele representant le quota video d'un utilisateur"""
    
    __tablename__ = "user_quotas"
    
    # Identifiants
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    
    # Configuration du quota
    tier = Column(String(20), default="free")  # free, premium, enterprise
    daily_limit_seconds = Column(Integer, default=1800)  # 30 min
    weekly_limit_seconds = Column(Integer, nullable=True)
    monthly_limit_seconds = Column(Integer, nullable=True)
    
    # Utilisation
    used_seconds_today = Column(Integer, default=0)
    used_seconds_week = Column(Integer, default=0)
    used_seconds_month = Column(Integer, default=0)
    
    # Reinitialisation
    quota_date = Column(DateTime, default=datetime.utcnow)
    week_start = Column(DateTime, default=datetime.utcnow)
    month_start = Column(DateTime, default=datetime.utcnow)
    
    # Extensions
    extra_allowed = Column(JSON, default={})
    
    def reset_if_needed(self) -> bool:
        """Reinitialise les quotas si necessaire"""
        now = datetime.utcnow()
        reset_needed = False
        
        # Quota journalier
        if self.quota_date.date() < now.date():
            self.used_seconds_today = 0
            self.quota_date = now
            reset_needed = True
        
        # Quota hebdomadaire
        week_start = now - timedelta(days=now.weekday())
        if self.week_start < week_start:
            self.used_seconds_week = 0
            self.week_start = week_start
            reset_needed = True
        
        # Quota mensuel
        if self.month_start.month < now.month or self.month_start.year < now.year:
            self.used_seconds_month = 0
            self.month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            reset_needed = True
        
        return reset_needed
    
    @property
    def remaining_seconds(self) -> int:
        """Temps restant aujourd'hui"""
        self.reset_if_needed()
        return max(0, self.daily_limit_seconds - self.used_seconds_today)
    
    @property
    def can_generate(self) -> bool:
        """Peut-on generer une video ?"""
        return self.remaining_seconds > 0
    
    @property
    def used_percentage(self) -> float:
        """Pourcentage utilise aujourd'hui"""
        if self.daily_limit_seconds == 0:
            return 0
        return min(100, (self.used_seconds_today / self.daily_limit_seconds) * 100)
    
    def add_usage(self, seconds: int):
        """Ajoute des secondes utilisees"""
        self.used_seconds_today += seconds
        self.used_seconds_week += seconds
        self.used_seconds_month += seconds
    
    def to_dict(self) -> dict:
        """Convertit le modele en dictionnaire"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "tier": self.tier,
            "daily_limit_seconds": self.daily_limit_seconds,
            "daily_limit_minutes": round(self.daily_limit_seconds / 60, 1),
            "used_seconds_today": self.used_seconds_today,
            "used_minutes_today": round(self.used_seconds_today / 60, 1),
            "remaining_seconds": self.remaining_seconds,
            "remaining_minutes": round(self.remaining_seconds / 60, 1),
            "used_percentage": self.used_percentage,
            "can_generate": self.can_generate,
            "quota_date": self.quota_date.isoformat() if self.quota_date else None,
            "extra_allowed": self.extra_allowed,
        }