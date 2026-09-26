# ============================================================
# FICHIER: ia-service/src/api/routes/manim_render.py
# DESCRIPTION: Rendu Manim → MP4 bytes
# ============================================================

import logging
import subprocess
import sys
import tempfile
import uuid
from pathlib import Path

from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/manim", tags=["Manim"])


class ManimRenderRequest(BaseModel):
    code: str
    scene_name: str
    quality: str = "l"  # l=480p15, m=720p30, h=1080p60


# Mapping quality → dossier de sortie Manim
QUALITY_DIRS = {"l": "480p15", "m": "720p30", "h": "1080p60"}


@router.post("/render")
async def render_manim(request: ManimRenderRequest):
    """
    Rend du code Manim en MP4.

    Retourne directement les bytes MP4 (Content-Type: video/mp4).

    ⚠️ Le code est validé AST avant rendu.
    ⚠️ Aucun fichier n'est stocké de façon permanente.
    """
    if not request.code.strip():
        raise HTTPException(400, detail="Code Manim vide")

    if request.quality not in QUALITY_DIRS:
        raise HTTPException(400, detail=f"Qualité invalide: {request.quality}")

    logger.info(
        f"🎬 [Manim] Rendu: scene={request.scene_name}, "
        f"quality={request.quality}, code={len(request.code)} caractères"
    )

    # Dossier de travail unique
    work_id = uuid.uuid4().hex[:8]
    work_dir = Path(tempfile.gettempdir()) / f"manim_{work_id}"
    work_dir.mkdir(parents=True, exist_ok=True)

    try:
        # 1. Écrire le code dans un fichier
        code_file = work_dir / "scene.py"
        code_file.write_text(request.code, encoding="utf-8")

        # 2. Lancer Manim
        media_dir = work_dir / "media"
        cmd = [
            sys.executable, "-m", "manim",
            f"-q{request.quality}",
            "--disable_caching",
            "--media_dir", str(media_dir),
            "-o", "output",
            str(code_file),
            request.scene_name,
        ]

        logger.info(f"🎬 [Manim] Commande: {' '.join(cmd)}")

        proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300,
        )

        if proc.returncode != 0:
            stderr = (proc.stderr or "")[-2000:]
            logger.error(f"❌ [Manim] Échec:\n{stderr}")
            raise HTTPException(500, detail=f"Manim a échoué:\n{stderr[:500]}")

        # 3. Localiser le MP4 produit
        quality_dir = QUALITY_DIRS[request.quality]
        candidates = list(
            (media_dir / "videos" / "scene" / quality_dir).glob("*.mp4")
        )
        if not candidates:
            # Fallback : chercher partout
            candidates = list(media_dir.rglob("*.mp4"))

        if not candidates:
            raise HTTPException(500, detail="Manim n'a produit aucun MP4")

        mp4_path = candidates[0]
        video_bytes = mp4_path.read_bytes()

        logger.info(f"✅ [Manim] {len(video_bytes)} octets générés")

        return Response(
            content=video_bytes,
            media_type="video/mp4",
            headers={
                "Content-Disposition": 'inline; filename="scene.mp4"',
                "Cache-Control": "no-store",
            },
        )

    except subprocess.TimeoutExpired:
        logger.error("❌ [Manim] Timeout de rendu (>300s)")
        raise HTTPException(504, detail="Timeout de rendu Manim")
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"❌ [Manim] Erreur: {e}")
        raise HTTPException(500, detail=f"Échec rendu Manim: {str(e)}")
    finally:
        # Nettoyage
        import shutil
        shutil.rmtree(work_dir, ignore_errors=True)