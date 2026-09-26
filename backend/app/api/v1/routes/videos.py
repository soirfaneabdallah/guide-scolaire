# ============================================================
# FICHIER: backend/app/api/v1/routes/videos.py
# DESCRIPTION: Endpoints pour les vidéos
# ============================================================

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
    Query,
    BackgroundTasks,
    Request,
)
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import Optional, List
from datetime import datetime
import logging

from ....core.database import get_db
from ....core.dependencies import (
    get_current_active_user,
    get_current_user_from_query_or_header,
)
from ....models.user import User
from ....models.subject import Subject
from ....models.video_script import VideoScript
from ....models.video_job import VideoJob, JobStatus as JobStatusModel
from ....models.video_quota import UserQuota
from ....models.chapter import Chapter
from ....models.user_progress import UserProgress
from ....services.video.stream_renderer import StreamRenderer
from ....services.video.ia_service_client import IAServiceClient
from ....schemas.video_schemas import (
    VideoScriptResponse,
    VideoScriptDetailResponse,
    VideoListResponse,
    ChapterResponse,
    UserProgressResponse,
    UpdateProgressRequest,
    VideoReportRequest,
    VideoReportResponse,
    VideoQuotaResponse,
    VideoGenerationRequest,
    VideoGenerationResponse,
    VideoJobResponse,
)
from ....repositories.video_repository import VideoRepository

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/videos", tags=["Videos"])


# ============================================================
# ⚠️ ORDRE IMPORTANT : Routes statiques AVANT la route dynamique /{script_id}
# ============================================================


# ============================================================
# VIDÉOS EN COURS
# ============================================================

@router.get("/in-progress", response_model=VideoListResponse)
async def get_in_progress_videos(
    limit: int = Query(5, ge=1, le=20),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Récupère les vidéos en cours de visionnage."""
    logger.info(f"📹 Vidéos en cours pour utilisateur {current_user.id}")

    progressions = db.query(UserProgress).filter(
        UserProgress.user_id == current_user.id,
        UserProgress.watched_seconds > 0,
        UserProgress.completed == False,
    ).order_by(
        UserProgress.last_watched_at.desc()
    ).limit(limit).all()

    videos = []
    for prog in progressions:
        video = db.query(VideoScript).filter(
            VideoScript.id == prog.script_id
        ).first()
        if video:
            video_dict = video.to_dict()
            video_dict["user_progress"] = prog.to_dict()
            videos.append(VideoScriptResponse(**video_dict))

    return VideoListResponse(
        videos=videos,
        total=len(videos),
        page=1,
        page_size=limit,
        has_next=False,
    )


# ============================================================
# VIDÉOS RECOMMANDÉES
# ============================================================

@router.get("/recommended", response_model=VideoListResponse)
async def get_recommended_videos(
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Récupère les vidéos recommandées."""
    level = current_user.level or "3ème"

    logger.info(f"📹 Vidéos recommandées pour niveau {level}")

    videos = db.query(VideoScript).filter(
        VideoScript.level == level,
    ).order_by(
        VideoScript.rating_average.desc(),
        VideoScript.views_count.desc(),
    ).limit(limit).all()

    return VideoListResponse(
        videos=[VideoScriptResponse(**v.to_dict()) for v in videos],
        total=len(videos),
        page=1,
        page_size=limit,
        has_next=False,
    )


# ============================================================
# VIDÉOS POPULAIRES
# ============================================================

@router.get("/popular", response_model=VideoListResponse)
async def get_popular_videos(
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Récupère les vidéos les plus populaires."""
    logger.info(f"📹 Vidéos populaires")

    videos = db.query(VideoScript).order_by(
        VideoScript.views_count.desc(),
        VideoScript.rating_average.desc(),
    ).limit(limit).all()

    return VideoListResponse(
        videos=[VideoScriptResponse(**v.to_dict()) for v in videos],
        total=len(videos),
        page=1,
        page_size=limit,
        has_next=False,
    )


# ============================================================
# QUOTA VIDÉO
# ============================================================

@router.get("/quota", response_model=VideoQuotaResponse)
async def get_video_quota(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Récupère le quota vidéo de l'utilisateur."""
    logger.info(f"📊 Quota vidéo pour utilisateur {current_user.id}")

    quota = db.query(UserQuota).filter_by(user_id=current_user.id).first()

    if not quota:
        quota = UserQuota(
            user_id=current_user.id,
            daily_limit_seconds=1800,
            used_seconds_today=0,
        )
        db.add(quota)
        db.commit()
        db.refresh(quota)
    else:
        if quota.reset_if_needed():
            db.commit()
            db.refresh(quota)

    return VideoQuotaResponse(
        id=quota.id,
        user_id=quota.user_id,
        tier=quota.tier,
        daily_limit_seconds=quota.daily_limit_seconds,
        daily_limit_minutes=round(quota.daily_limit_seconds / 60, 1),
        used_seconds_today=quota.used_seconds_today,
        used_minutes_today=round(quota.used_seconds_today / 60, 1),
        remaining_seconds=quota.remaining_seconds,
        remaining_minutes=round(quota.remaining_seconds / 60, 1),
        used_percentage=quota.used_percentage,
        can_generate=quota.can_generate,
    )


# ============================================================
# GÉNÉRATION DE VIDÉO
# ============================================================

@router.post("/generate", response_model=VideoGenerationResponse)
async def generate_video(
    request: VideoGenerationRequest,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Lance la génération d'une vidéo pédagogique.

    - Vérifie le quota
    - Crée un job
    - Lance le traitement en arrière-plan
    """
    logger.info(f"🎬 Demande de génération pour {current_user.email}")
    logger.info(f"   Prompt: {request.prompt[:80]}...")

    # 1. Vérifier le quota
    quota = db.query(UserQuota).filter_by(user_id=current_user.id).first()

    if not quota:
        quota = UserQuota(
            user_id=current_user.id,
            daily_limit_seconds=1800,
            used_seconds_today=0,
        )
        db.add(quota)
        db.commit()
        db.refresh(quota)
    else:
        if quota.reset_if_needed():
            db.commit()
            db.refresh(quota)

    if not quota.can_generate:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "QUOTA_EXCEEDED",
                "message": "Ton quota journalier de 30 min est atteint. Reviens demain !",
                "remaining_seconds": 0,
            }
        )

    # 2. Créer le job
    duration = request.duration_seconds or 180

    job = VideoJob(
        user_id=current_user.id,
        prompt_context=request.prompt,
        concept=getattr(request, 'concept', None),
        status=JobStatusModel.PENDING,
        progress=0,
        estimated_duration_seconds=duration,
    )

    db.add(job)
    db.commit()
    db.refresh(job)

    logger.info(f"✅ Job créé : {job.id}")

    # 3. Lancer le traitement en arrière-plan
    background_tasks.add_task(
        _process_video_job,
        job_id=job.id,
    )

    # 4. Retourner la réponse
    return VideoGenerationResponse(
        job_id=job.id,
        status=job.status,
        quota_remaining_seconds=quota.remaining_seconds,
        quota_remaining_minutes=round(quota.remaining_seconds / 60, 1),
        estimated_time_seconds=360,
        message=f"🎬 Génération lancée ! Il te reste {round(quota.remaining_seconds / 60, 1)} min de vidéo.",
    )

@router.delete("/cache/purge")
async def purge_video_cache(
    current_user: User = Depends(get_current_active_user),
):
    """Purge tout le cache vidéo (debug)."""
    from ....services.video.stream_renderer import StreamRenderer
    removed = StreamRenderer.cleanup_cache(force=True)
    return {"purged": removed}
# ============================================================
# STATUT D'UN JOB
# ============================================================

@router.get("/status/{job_id}", response_model=VideoJobResponse)
async def get_job_status(
    job_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Récupère le statut d'un job."""
    job = db.query(VideoJob).filter(
        VideoJob.id == job_id,
        VideoJob.user_id == current_user.id,
    ).first()

    if not job:
        raise HTTPException(status_code=404, detail="Job non trouvé")

    return VideoJobResponse(
        id=job.id,
        user_id=job.user_id,
        prompt_context=job.prompt_context,
        concept=job.concept,
        status=job.status,
        progress=job.progress,
        estimated_duration_seconds=job.estimated_duration_seconds,
        actual_duration_seconds=job.actual_duration_seconds,
        elapsed_seconds=job.elapsed_seconds or 0,
        video_url=job.video_url,
        thumbnail_url=job.thumbnail_url,
        error_message=job.error_message,
        error_code=job.error_code,
        fallback_used=job.fallback_used or False,
        is_cached=job.is_cached or False,
        created_at=job.created_at.isoformat() if job.created_at else None,
        completed_at=job.completed_at.isoformat() if job.completed_at else None,
    )


# ============================================================
# ANNULER UN JOB
# ============================================================

@router.delete("/job/{job_id}")
async def cancel_job(
    job_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Annule un job."""
    job = db.query(VideoJob).filter(
        VideoJob.id == job_id,
        VideoJob.user_id == current_user.id,
    ).first()

    if not job:
        raise HTTPException(status_code=404, detail="Job non trouvé")

    job.status = JobStatusModel.CANCELLED
    db.commit()

    return {"message": "Job annulé"}


# ============================================================
# VIDÉOS PAR MATIÈRE
# ============================================================

@router.get("/by-subject/{subject_id}", response_model=VideoListResponse)
async def get_videos_by_subject(
    subject_id: int,
    level: Optional[str] = Query(None),
    chapter: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Récupère les vidéos d'une matière."""
    effective_level = level or current_user.level or "3ème"

    logger.info(f"📹 Vidéos pour matière {subject_id}, niveau {effective_level}")

    repo = VideoRepository(db)

    videos, total = repo.get_videos_by_subject(
        subject_id=subject_id,
        level=effective_level,
        chapter=chapter,
        page=page,
        page_size=page_size,
    )

    videos_with_progress = []
    for video in videos:
        progress = repo.get_user_progress(current_user.id, video.id)
        video_dict = video.to_dict()
        if progress:
            video_dict["user_progress"] = progress.to_dict()
        videos_with_progress.append(VideoScriptResponse(**video_dict))

    return VideoListResponse(
        videos=videos_with_progress,
        total=total,
        page=page,
        page_size=page_size,
        has_next=(page * page_size) < total,
    )


# ============================================================
# CHAPITRES
# ============================================================

@router.get("/chapters/{subject_id}", response_model=List[ChapterResponse])
async def get_chapters_by_subject(
    subject_id: int,
    level: Optional[str] = Query(None),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Récupère les chapitres d'une matière."""
    effective_level = level or current_user.level or "3ème"

    repo = VideoRepository(db)
    chapters = repo.get_chapters_by_subject(subject_id, effective_level)

    chapters_with_count = []
    for chapter in chapters:
        video_count = repo.count_videos_in_chapter(
            subject_id=subject_id,
            level=effective_level,
            chapter=chapter.name,
        )
        completed_count = repo.count_completed_in_chapter(
            user_id=current_user.id,
            subject_id=subject_id,
            level=effective_level,
            chapter=chapter.name,
        )

        chapter_dict = chapter.to_dict()
        chapter_dict["video_count"] = video_count
        chapter_dict["completed_count"] = completed_count
        chapters_with_count.append(ChapterResponse(**chapter_dict))

    return chapters_with_count


# ============================================================
# STREAM DE LA VIDÉO (génération à la volée, ZÉRO stockage MP4)
# ============================================================

@router.get("/{script_id}/stream")
async def stream_video(
    script_id: str,
    token: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user_from_query_or_header),
    db: Session = Depends(get_db),
):
    """
    Génère (si nécessaire) puis sert la vidéo.

    ⚠️ PRINCIPE DU PROJET :
      - Aucun MP4 n'est stocké de façon permanente.
      - Seul le SCRIPT est en BDD.
      - Le MP4 est mis en cache temporaire (/tmp) avec TTL 1h pour permettre
        la lecture fluide (barre de progression, seek, Range requests).

    Pourquoi un cache temporaire ? Parce qu'un MP4 streamé "à la volée" sans
    index global (fragmenté) empêche le navigateur de connaître la durée
    totale → barre de progression cassée. Le cache TTL résout ce problème tout
    en respectant l'esprit du projet (pas de stockage permanent).
    """
    from ....services.video.stream_renderer import StreamRenderer, CACHE_DIR

    logger.info(f"🎬 [Stream] script={script_id}, user={current_user.id}")

    # 1. Récupérer le script
    video = db.query(VideoScript).filter(VideoScript.id == script_id).first()
    if not video:
        raise HTTPException(404, detail="Vidéo non trouvée")

    scenes = video.scenes or []
    if not scenes:
        raise HTTPException(
            status_code=422,
            detail="Cette vidéo n'a pas encore de scènes générées.",
        )

    # 2. Nettoyer le cache expiré (au passage)
    StreamRenderer.cleanup_cache()

    # 3. Vérifier si le MP4 est en cache
    cache_filename = StreamRenderer.cache_key(script_id, scenes)
    cache_path = CACHE_DIR / cache_filename

    if cache_path.exists() and cache_path.stat().st_size > 0:
        logger.info(f"✅ [Stream] Cache hit : {cache_filename} ({cache_path.stat().st_size / 1024 / 1024:.1f} Mo)")
    else:
        logger.info(f"🎬 [Stream] Génération du MP4 : {cache_filename}")
        renderer = StreamRenderer()
        success = await renderer.render_video_to_file(
            script_id=script_id,
            scenes=scenes,
            output_path=str(cache_path),
        )
        if not success or not cache_path.exists():
            raise HTTPException(500, detail="Échec de génération de la vidéo")
        logger.info(f"✅ [Stream] MP4 généré : {cache_path.stat().st_size / 1024 / 1024:.1f} Mo")

    # 4. Servir avec FileResponse (Range géré nativement par Starlette)
    return FileResponse(
        path=str(cache_path),
        media_type="video/mp4",
        filename=f"{script_id}.mp4",
        headers={
            "Content-Disposition": f'inline; filename="{script_id}.mp4"',
            "Accept-Ranges": "bytes",
            "Cache-Control": f"private, max-age={StreamRenderer.CACHE_TTL_SECONDS if hasattr(StreamRenderer, 'CACHE_TTL_SECONDS') else 3600}",
        },
    )


# ============================================================
# ⚠️ ROUTE DYNAMIQUE - EN DERNIER
# ============================================================

@router.get("/{script_id}", response_model=VideoScriptDetailResponse)
async def get_video_detail(
    script_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Récupère le détail d'une vidéo."""
    repo = VideoRepository(db)
    video = repo.get_video_by_id(script_id)

    if not video:
        raise HTTPException(status_code=404, detail="Vidéo non trouvée")

    repo.increment_views(script_id)

    progress = repo.get_user_progress(current_user.id, script_id)
    video_dict = video.to_dict()
    video_dict["scenes"] = video.scenes or []
    if progress:
        video_dict["user_progress"] = progress.to_dict()

    return VideoScriptDetailResponse(**video_dict)


# ============================================================
# PROGRESSION
# ============================================================

@router.post("/{script_id}/progress", response_model=UserProgressResponse)
async def update_progress(
    script_id: str,
    request: UpdateProgressRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Met à jour la progression."""
    repo = VideoRepository(db)

    progress = repo.update_progress(
        user_id=current_user.id,
        script_id=script_id,
        last_position=request.last_position_seconds,
        watched_seconds=request.watched_seconds,
        completed=request.completed,
    )

    return UserProgressResponse(**progress.to_dict())


# ============================================================
# SIGNALEMENT
# ============================================================

@router.post("/{script_id}/report", response_model=VideoReportResponse)
async def report_video(
    script_id: str,
    request: VideoReportRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Signale une vidéo."""
    repo = VideoRepository(db)

    report = repo.create_report(
        user_id=current_user.id,
        script_id=script_id,
        scene_id=request.scene_id,
        reason=request.reason,
        comment=request.comment,
    )

    return VideoReportResponse(**report.to_dict())


# ============================================================
# WORKER DE GÉNÉRATION (arrière-plan)
# ============================================================

async def _process_video_job(job_id: str):
    """
    Traite un job de génération en arrière-plan.

    Pipeline RÉEL :
      1. Appel ia-service → /api/script/generate
      2. ia-service exécute : Planner → Narrator → Coder → Validator
      3. ia-service retourne le script complet (narration + code Manim par scène)
      4. On stocke UNIQUEMENT ce script dans VideoScript.scenes (JSON)
      5. AUCUNE vidéo n'est générée ici — elle le sera à la volée via /stream

    Le rendu Manim + TTS se fait UNIQUEMENT au moment du /stream.
    """
    from ....core.database import SessionLocal

    logger.info(f"🎬 [Worker] Démarrage du job {job_id}")

    db = SessionLocal()
    try:
        job = db.query(VideoJob).filter_by(id=job_id).first()
        if not job:
            logger.error(f"❌ [Worker] Job {job_id} introuvable")
            return

        if job.status == JobStatusModel.CANCELLED:
            logger.info(f"🚫 [Worker] Job {job_id} déjà annulé")
            return

        # ------------------------------------------------------------
        # ÉTAPE 1 : Génération du script via ia-service
        # ------------------------------------------------------------
        job.status = JobStatusModel.GENERATING_CODE
        job.progress = 10
        job.started_at = datetime.utcnow()
        db.commit()

        logger.info(f"🔄 [Worker] {job_id} → Appel ia-service /api/script/generate")

        ia = IAServiceClient()
        script_data = await ia.generate_script(
            prompt=job.prompt_context,
            duration_seconds=job.estimated_duration_seconds or 180,
            n_scenes=8,
        )

        if not script_data or not script_data.get("scenes"):
            logger.error(f"❌ [Worker] ia-service n'a pas retourné de script valide")
            job.status = JobStatusModel.FAILED
            job.error_message = "ia-service n'a pas pu générer le script"
            job.error_code = "IA_SERVICE_FAILED"
            db.commit()
            return

        scenes = script_data["scenes"]
        logger.info(f"✅ [Worker] Script généré : {len(scenes)} scènes")

        # ------------------------------------------------------------
        # ÉTAPE 2 : Création du VideoScript (SEUL le script est stocké)
        # ------------------------------------------------------------
        job.status = JobStatusModel.SYNTHESIZING
        job.progress = 60
        db.commit()

        total_duration = sum(
            float(s.get("duration", 10.0)) for s in scenes
        )

        video_script = VideoScript(
            user_id=job.user_id,
            subject_id=getattr(job, "subject_id", None),
            title=script_data.get("title", job.prompt_context[:100]),
            level=getattr(job, "level", None) or "3ème",
            scenes=scenes,  # ⚠️ STOCKAGE UNIQUEMENT DU SCRIPT
            total_duration_seconds=int(total_duration),
        )
        db.add(video_script)
        db.commit()
        db.refresh(video_script)

        logger.info(
            f"✅ [Worker] VideoScript créé : {video_script.id} "
            f"({len(scenes)} scènes, {total_duration:.0f}s)"
        )

        # ------------------------------------------------------------
        # ÉTAPE 3 : Finalisation du job
        # ------------------------------------------------------------
        job.status = JobStatusModel.READY
        job.progress = 100
        job.completed_at = datetime.utcnow()
        job.actual_duration_seconds = int(total_duration)
        job.script_id = video_script.id
        # ⚠️ On NE stocke PAS d'URL de fichier MP4 — la vidéo est générée à la volée
        job.video_url = f"/videos/{video_script.id}/stream"

        # Mise à jour du quota
        quota = db.query(UserQuota).filter_by(user_id=job.user_id).first()
        if quota:
            quota.add_usage(int(total_duration))

        db.commit()
        logger.info(f"✅ [Worker] Job {job_id} terminé → script {video_script.id}")

    except Exception as e:
        logger.exception(f"❌ [Worker] Erreur job {job_id}: {e}")
        try:
            job = db.query(VideoJob).filter_by(id=job_id).first()
            if job:
                job.status = JobStatusModel.FAILED
                job.error_message = str(e)[:500]
                job.error_code = "WORKER_ERROR"
                db.commit()
        except Exception:
            pass
    finally:
        db.close()