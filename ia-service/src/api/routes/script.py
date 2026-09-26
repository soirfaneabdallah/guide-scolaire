# ============================================================
# FICHIER: ia-service/src/api/routes/script.py
# DESCRIPTION: Route de génération de script (version pédagogique)
# ============================================================

from fastapi import APIRouter
import logging

from src.schemas.video_schemas import (
    ScriptRequest,
    ScriptResponse,
    Scene,
)
from src.services.script.planner import PlannerService
from src.services.script.narrator import NarratorService
from src.services.script.coder import CoderService

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/generate", response_model=ScriptResponse)
async def generate_script(request: ScriptRequest):
    """
    Génère un script pédagogique COMPLET (10-15 minutes).

    Pipeline :
    1. Planner → décompose en 10-15 scènes
    2. Narrator → génère la narration détaillée (100-200 mots/scène)
    3. Coder → génère le code Manim détaillé (45-90s/scène)
    """
    logger.info(f"📝 [Script] Demande : {request.prompt[:60]}...")

    try:
        # 1. Planner (10-15 scènes)
        planner = PlannerService()
        plan = await planner.plan(
            prompt=request.prompt,
            subject=request.subject or "Général",
            level=request.level,
            language=request.language,
            target_duration=720,  # 12 minutes
        )

        if not plan.get("scenes"):
            return ScriptResponse(
                success=False,
                title=request.prompt[:80],
                error="Aucune scène générée",
            )

        # 2. Narrator + Coder pour chaque scène
        narrator = NarratorService()
        coder = CoderService()

        scenes = []
        total_duration = 0

        for scene_data in plan["scenes"]:
            phase = scene_data.get("phase", "explication")
            
            # ✅ Narration détaillée (100-200 mots)
            narration = await narrator.narrate(
                concept=scene_data.get("concept", request.prompt),
                title=scene_data.get("title", ""),
                phase=phase,
                level=request.level,
                narration_hint=scene_data.get("narration_hint", ""),
            )

            # ✅ Code Manim détaillé (45-90s)
            scene_duration = 60  # 60s par défaut
            if phase == "introduction":
                scene_duration = 60
            elif phase == "definition":
                scene_duration = 75
            elif phase == "explication":
                scene_duration = 90
            elif phase == "exemple":
                scene_duration = 75
            elif phase == "exercice":
                scene_duration = 90
            else:
                scene_duration = 60

            manim_code = await coder.code(
                concept=scene_data.get("concept", request.prompt),
                narration=narration,
                phase=phase,
                level=request.level,
                duration=scene_duration,
            )

            scene = Scene(
                id=f"scene_{scene_data.get('order', len(scenes) + 1)}",
                order=scene_data.get("order", len(scenes) + 1),
                title=scene_data.get("title", f"Scène {len(scenes) + 1}"),
                concept=scene_data.get("concept", request.prompt),
                manim_code=manim_code,
                narration=narration,
                estimated_duration=scene_duration,
            )
            scenes.append(scene)
            total_duration += scene_duration

        logger.info(
            f"✅ [Script] {len(scenes)} scènes, "
            f"{total_duration // 60}min {total_duration % 60}s"
        )

        return ScriptResponse(
            success=True,
            title=plan.get("title", request.prompt[:80]),
            description=plan.get("description"),
            scenes=scenes,
            total_duration=total_duration,
        )

    except Exception as e:
        logger.error(f"❌ [Script] Erreur : {e}")
        return ScriptResponse(
            success=False,
            title=request.prompt[:80],
            error=str(e),
        )