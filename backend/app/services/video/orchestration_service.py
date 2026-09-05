# ============================================================
# FICHIER: backend/app/services/video/orchestration_service.py
# DESCRIPTION: Service d'orchestration principal pour la generation video
# ============================================================

import asyncio
import logging
from typing import Optional, Dict, Any
from datetime import datetime

from sqlalchemy.orm import Session

from app.models.video_job import VideoJob, JobStatus
from app.models.video_quota import UserQuota
from app.services.generation.manim_generator import ManimGenerator
from app.services.llm.ollama_client import OllamaClient
from app.services.tts.edge_tts_client import EdgeTTSClient
from app.services.assembly.ffmpeg_assembler import FFmpegAssembler
from app.services.storage.local_storage import LocalStorage
from app.services.video.quota_service import QuotaService
from app.utils.file_utils import VideoFileUtils
from app.core.database import SessionLocal
from app.core.constants.video_constants import STEP_MESSAGES

logger = logging.getLogger(__name__)


class VideoOrchestrationService:
    """
    Orchestrateur principal du flux de generation video.
    Coordonne toutes les etapes: LLM -> Manim -> TTS -> FFmpeg -> Stockage
    """
    
    def __init__(self):
        self.llm_client = OllamaClient()
        self.generator = ManimGenerator()
        self.tts_client = EdgeTTSClient()
        self.assembler = FFmpegAssembler()
        self.storage = LocalStorage()
        self.quota_service = QuotaService()
    
    async def start_generation(
        self,
        user_id: int,
        prompt: str,
        concept: Optional[str] = None,
        level: Optional[str] = None,
        duration_seconds: int = 180,
        language: str = "fr"
    ) -> VideoJob:
        """
        Cree un nouveau job de generation video.
        
        Args:
            user_id: ID de l'utilisateur
            prompt: Prompt de l'utilisateur
            concept: Concept a illustrer (optionnel)
            level: Niveau scolaire (optionnel)
            duration_seconds: Duree souhaitee en secondes
            language: Langue de la narration
            
        Returns:
            VideoJob: Le job cree
        """
        db = SessionLocal()
        try:
            job = VideoJob(
                user_id=user_id,
                prompt_context=prompt,
                concept=concept,
                level=level,
                language=language,
                estimated_duration_seconds=duration_seconds,
                status=JobStatus.PENDING,
                progress=0
            )
            db.add(job)
            db.commit()
            db.refresh(job)
            
            # Creer l'espace de travail
            VideoFileUtils.create_workspace(job.id)
            
            logger.info(f"Job {job.id} cree pour l'utilisateur {user_id}")
            return job
            
        finally:
            db.close()
    
    async def process_job(self, job_id: str, quota_id: int):
        """
        Traite un job en arriere-plan.
        Toutes les etapes sont executees sequentiellement.
        
        Args:
            job_id: ID du job
            quota_id: ID du quota pour mise a jour
        """
        db = SessionLocal()
        try:
            job = db.query(VideoJob).filter_by(id=job_id).first()
            if not job:
                logger.error(f"Job {job_id} non trouve")
                return
            
            # Creer l'espace de travail
            workspace = VideoFileUtils.create_workspace(job.id)
            
            # ============================================================
            # ETAPE 1: Generation du code Manim
            # ============================================================
            logger.info(f"Job {job_id}: Generation du code Manim")
            job.status = JobStatus.GENERATING_CODE
            job.started_at = datetime.utcnow()
            job.progress = 10
            db.commit()
            
            code_result = await self.llm_client.generate_manim_code(
                prompt=job.prompt_context,
                concept=job.concept,
                level=job.level,
                duration=job.estimated_duration_seconds
            )
            
            if not code_result.success:
                raise Exception(f"Erreur LLM: {code_result.error}")
            
            # Sauvegarder le code
            VideoFileUtils.save_manim_code(workspace["root"], code_result.code, job.id)
            job.progress = 30
            db.commit()
            
            # ============================================================
            # ETAPE 2: Rendu Manim
            # ============================================================
            logger.info(f"Job {job_id}: Rendu Manim")
            job.status = JobStatus.RENDERING
            job.progress = 40
            db.commit()
            
            video_path = await self.generator.render(
                code=code_result.code,
                job_id=job.id,
                workspace=workspace
            )
            
            if not video_path:
                raise Exception("Echec du rendu Manim")
            
            job.progress = 60
            db.commit()
            
            # ============================================================
            # ETAPE 3: Generation du script de narration
            # ============================================================
            logger.info(f"Job {job_id}: Generation du script de narration")
            job.status = JobStatus.SYNTHESIZING
            job.progress = 65
            db.commit()
            
            script = await self.llm_client.generate_narration_script(
                code=code_result.code,
                concept=job.concept or "le concept",
                level=job.level or "college"
            )
            
            VideoFileUtils.save_narration_script(workspace["root"], script, job.id)
            job.progress = 75
            db.commit()
            
            # ============================================================
            # ETAPE 4: Synthese vocale
            # ============================================================
            logger.info(f"Job {job_id}: Synthese vocale")
            audio_paths = await self.tts_client.generate_segments(
                script=script,
                job_id=job.id,
                workspace=workspace
            )
            
            job.progress = 85
            db.commit()
            
            # ============================================================
            # ETAPE 5: Assemblage final
            # ============================================================
            logger.info(f"Job {job_id}: Assemblage FFmpeg")
            job.status = JobStatus.ASSEMBLING
            job.progress = 90
            db.commit()
            
            final_path = await self.assembler.assemble(
                video_path=video_path,
                audio_paths=audio_paths,
                script=script,
                job_id=job.id,
                workspace=workspace
            )
            
            # ============================================================
            # ETAPE 6: Stockage et finalisation
            # ============================================================
            logger.info(f"Job {job_id}: Stockage")
            video_url = await self.storage.save_video(
                file_path=final_path,
                job_id=job.id,
                user_id=job.user_id
            )
            
            # Mise a jour du quota
            duration = self.assembler.get_video_duration(final_path)
            await self.quota_service.add_usage(quota_id, duration)
            
            # Finalisation
            job.status = JobStatus.READY
            job.progress = 100
            job.video_url = video_url
            job.actual_duration_seconds = duration
            job.completed_at = datetime.utcnow()
            db.commit()
            
            logger.info(f"Job {job_id} termine avec succes ! Duree: {duration}s")
            
            # Envoyer la notification
            await NotificationService.notify_video_ready(
                user_id=job.user_id,
                job_id=job.id,
                video_url=video_url
            )
            
        except Exception as e:
            logger.error(f"Job {job_id} echoue: {str(e)}", exc_info=True)
            job.status = JobStatus.FAILED
            job.error_message = str(e)
            job.progress = 0
            db.commit()
        finally:
            db.close()
    
    async def get_job(self, job_id: str, user_id: int) -> Optional[dict]:
        """
        Recupere un job par son ID.
        
        Args:
            job_id: ID du job
            user_id: ID de l'utilisateur (pour securite)
            
        Returns:
            dict: Donnees du job ou None
        """
        db = SessionLocal()
        try:
            job = db.query(VideoJob).filter_by(
                id=job_id,
                user_id=user_id
            ).first()
            return job.to_dict() if job else None
        finally:
            db.close()
    
    async def get_progress(self, job_id: str, user_id: int) -> Optional[dict]:
        """
        Recupere la progression detaillee d'un job.
        
        Args:
            job_id: ID du job
            user_id: ID de l'utilisateur
            
        Returns:
            dict: Progression ou None
        """
        db = SessionLocal()
        try:
            job = db.query(VideoJob).filter_by(
                id=job_id,
                user_id=user_id
            ).first()
            
            if not job:
                return None
            
            elapsed = int((datetime.utcnow() - job.created_at).total_seconds())
            status_str = job.status.value if job.status else "pending"
            
            return {
                "job_id": job.id,
                "status": job.status,
                "progress": job.progress,
                "step": status_str,
                "elapsed_seconds": elapsed,
                "estimated_remaining_seconds": max(
                    0, 
                    job.estimated_duration_seconds - elapsed
                ),
                "message": STEP_MESSAGES.get(status_str, "Traitement en cours...")
            }
        finally:
            db.close()
    
    async def cancel_job(self, job_id: str, user_id: int) -> bool:
        """
        Annule un job en cours.
        
        Args:
            job_id: ID du job
            user_id: ID de l'utilisateur
            
        Returns:
            bool: True si annule, False sinon
        """
        db = SessionLocal()
        try:
            job = db.query(VideoJob).filter_by(
                id=job_id,
                user_id=user_id
            ).first()
            
            if not job:
                return False
            
            if job.status in [JobStatus.PENDING, JobStatus.GENERATING_CODE]:
                job.status = JobStatus.CANCELLED
                db.commit()
                logger.info(f"Job {job_id} annule par l'utilisateur {user_id}")
                return True
            
            return False
        finally:
            db.close()