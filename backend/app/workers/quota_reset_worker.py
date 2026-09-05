# ============================================================
# FICHIER: backend/app/workers/quota_reset_worker.py
# DESCRIPTION: Worker de reinitialisation des quotas
# ============================================================

import logging
from datetime import datetime

from celery import Celery
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.models.video_quota import UserQuota
from app.core.constants.video_constants import DAILY_QUOTA_SECONDS

logger = logging.getLogger(__name__)

from .video_worker import celery_app


@celery_app.task(name="quota_reset_worker.reset_daily_quotas")
def reset_daily_quotas():
    """
    Reinitialise les quotas quotidiens.
    """
    logger.info("Resetting daily quotas")
    
    db = SessionLocal()
    try:
        quotas = db.query(UserQuota).all()
        reset_count = 0
        
        for quota in quotas:
            if quota.reset_if_needed():
                reset_count += 1
        
        db.commit()
        logger.info(f"Reset {reset_count} quotas")
        return {"reset": reset_count}
        
    except Exception as e:
        logger.error(f"Quota reset failed: {str(e)}")
        db.rollback()
        return {"error": str(e)}
    finally:
        db.close()


@celery_app.task(name="quota_reset_worker.reset_weekly_quotas")
def reset_weekly_quotas():
    """
    Reinitialise les quotas hebdomadaires (le lundi).
    """
    logger.info("Resetting weekly quotas")
    
    db = SessionLocal()
    try:
        now = datetime.utcnow()
        # Verifier si c'est lundi
        if now.weekday() != 0:  # 0 = lundi
            return {"message": "Not monday, skipping weekly reset"}
        
        quotas = db.query(UserQuota).all()
        reset_count = 0
        
        for quota in quotas:
            # Reinitialiser les quotas hebdomadaires
            quota.used_seconds_week = 0
            quota.week_start = now
            reset_count += 1
        
        db.commit()
        logger.info(f"Reset {reset_count} weekly quotas")
        return {"reset": reset_count}
        
    except Exception as e:
        logger.error(f"Weekly quota reset failed: {str(e)}")
        db.rollback()
        return {"error": str(e)}
    finally:
        db.close()