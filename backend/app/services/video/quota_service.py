# ============================================================
# FICHIER: backend/app/services/video/quota_service.py
# DESCRIPTION: Service de gestion des quotas utilisateurs
# ============================================================

from typing import Optional
from sqlalchemy.orm import Session

from app.models.video_quota import UserQuota
from app.core.database import SessionLocal
from app.core.constants.video_constants import DAILY_QUOTA_SECONDS

import logging

logger = logging.getLogger(__name__)


class QuotaService:
    """
    Gere les quotas video des utilisateurs.
    Verifie, met a jour et reinitialise les quotas.
    """
    
    async def get_or_create_quota(self, user_id: int) -> UserQuota:
        """
        Recupere ou cree le quota d'un utilisateur.
        
        Args:
            user_id: ID de l'utilisateur
            
        Returns:
            UserQuota: Le quota de l'utilisateur
        """
        db = SessionLocal()
        try:
            quota = db.query(UserQuota).filter_by(user_id=user_id).first()
            if not quota:
                quota = UserQuota(
                    user_id=user_id,
                    daily_limit_seconds=DAILY_QUOTA_SECONDS
                )
                db.add(quota)
                db.commit()
                db.refresh(quota)
                logger.info(f"Quota cree pour l'utilisateur {user_id}")
            
            quota.reset_if_needed()
            db.commit()
            return quota
            
        finally:
            db.close()
    
    async def add_usage(self, quota_id: int, seconds: int):
        """
        Ajoute des secondes utilisees au quota.
        
        Args:
            quota_id: ID du quota
            seconds: Secondes a ajouter
        """
        db = SessionLocal()
        try:
            quota = db.query(UserQuota).filter_by(id=quota_id).first()
            if quota:
                quota.add_usage(seconds)
                db.commit()
                logger.debug(f"Quota {quota_id} mis a jour: +{seconds}s")
        finally:
            db.close()
    
    async def get_quota(self, user_id: int) -> Optional[dict]:
        """
        Recupere les informations du quota d'un utilisateur.
        
        Args:
            user_id: ID de l'utilisateur
            
        Returns:
            dict: Donnees du quota ou None
        """
        db = SessionLocal()
        try:
            quota = db.query(UserQuota).filter_by(user_id=user_id).first()
            if not quota:
                return None
            quota.reset_if_needed()
            db.commit()
            return quota.to_dict()
        finally:
            db.close()
    
    async def reset_all_quotas(self):
        """
        Reinitialise tous les quotas (appele par le worker de reset).
        """
        db = SessionLocal()
        try:
            quotas = db.query(UserQuota).all()
            for quota in quotas:
                if quota.reset_if_needed():
                    db.commit()
                    logger.info(f"Quota reinitialise pour l'utilisateur {quota.user_id}")
        finally:
            db.close()