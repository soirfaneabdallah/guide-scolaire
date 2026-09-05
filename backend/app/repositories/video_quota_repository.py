# ============================================================
# FICHIER: backend/app/repositories/video_quota_repository.py
# DESCRIPTION: Repository pour les UserQuota
# ============================================================

from typing import Optional, List, Dict, Any
from datetime import datetime
from sqlalchemy.orm import Session

from app.models.video_quota import UserQuota


class VideoQuotaRepository:
    """
    Repository pour les operations CRUD sur UserQuota.
    """
    
    def __init__(self, db: Session):
        self.db = db
    
    def get_or_create(self, user_id: int) -> UserQuota:
        """
        Recupere ou cree un quota.
        """
        quota = self.db.query(UserQuota).filter_by(user_id=user_id).first()
        if not quota:
            quota = UserQuota(user_id=user_id)
            self.db.add(quota)
            self.db.commit()
            self.db.refresh(quota)
        return quota
    
    def get_by_user(self, user_id: int) -> Optional[UserQuota]:
        """
        Recupere un quota par utilisateur.
        """
        return self.db.query(UserQuota).filter_by(user_id=user_id).first()
    
    def update_usage(self, user_id: int, seconds: int) -> Optional[UserQuota]:
        """
        Ajoute des secondes utilisees.
        """
        quota = self.get_by_user(user_id)
        if not quota:
            return None
        
        quota.add_usage(seconds)
        quota.reset_if_needed()
        self.db.commit()
        self.db.refresh(quota)
        return quota
    
    def reset_daily(self, user_id: int) -> Optional[UserQuota]:
        """
        Reinitialise le quota quotidien.
        """
        quota = self.get_by_user(user_id)
        if not quota:
            return None
        
        quota.used_seconds_today = 0
        quota.quota_date = datetime.utcnow()
        self.db.commit()
        self.db.refresh(quota)
        return quota
    
    def reset_all_daily(self) -> List[int]:
        """
        Reinitialise tous les quotas quotidiens.
        """
        quotas = self.db.query(UserQuota).all()
        user_ids = []
        
        for quota in quotas:
            if quota.reset_if_needed():
                user_ids.append(quota.user_id)
        
        self.db.commit()
        return user_ids
    
    def get_all_usage(self, limit: int = 100) -> List[Dict[str, Any]]:
        """
        Recupere l'utilisation de tous les utilisateurs.
        """
        quotas = self.db.query(UserQuota).limit(limit).all()
        return [
            {
                "user_id": q.user_id,
                "tier": q.tier,
                "used_today": q.used_seconds_today,
                "limit": q.daily_limit_seconds,
                "percentage": q.used_percentage,
                "remaining": q.remaining_seconds
            }
            for q in quotas
        ]