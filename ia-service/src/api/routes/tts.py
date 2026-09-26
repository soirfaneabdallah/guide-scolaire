# ============================================================
# FICHIER: ia-service/src/api/routes/tts.py
# DESCRIPTION: Synthèse vocale via Edge TTS
# ============================================================

import logging
import tempfile
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/tts", tags=["TTS"])


class TTSRequest(BaseModel):
    text: str
    lang: str = "fr"
    voice: Optional[str] = None  # ex: "fr-FR-DeniseNeural"


# Voix par défaut par langue (Edge TTS)
DEFAULT_VOICES = {
    "fr": "fr-FR-DeniseNeural",
    "en": "en-US-AriaNeural",
    "ar": "ar-SA-ZariyahNeural",
}


@router.post("/synthesize")
async def synthesize(request: TTSRequest):
    """
    Synthétise un texte en audio MP3 via Edge TTS.

    Retourne directement les bytes MP3 (Content-Type: audio/mpeg).

    ⚠️ Aucun fichier n'est stocké de façon permanente.
    """
    if not request.text.strip():
        raise HTTPException(400, detail="Texte vide")

    voice = request.voice or DEFAULT_VOICES.get(request.lang, "fr-FR-DeniseNeural")

    logger.info(
        f"🎙️ [TTS] Synthèse: {len(request.text)} caractères, "
        f"lang={request.lang}, voice={voice}"
    )

    try:
        import edge_tts

        # Edge TTS écrit dans un fichier temporaire
        with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as f:
            tmp_path = Path(f.name)

        try:
            communicate = edge_tts.Communicate(request.text, voice)
            await communicate.save(str(tmp_path))

            if not tmp_path.exists() or tmp_path.stat().st_size == 0:
                raise HTTPException(500, detail="Edge TTS a produit un fichier vide")

            audio_bytes = tmp_path.read_bytes()
            logger.info(f"✅ [TTS] {len(audio_bytes)} octets générés")

            return Response(
                content=audio_bytes,
                media_type="audio/mpeg",
                headers={
                    "Content-Disposition": 'inline; filename="narration.mp3"',
                    "Cache-Control": "no-store",
                },
            )
        finally:
            tmp_path.unlink(missing_ok=True)

    except ImportError:
        logger.error("❌ [TTS] edge-tts non installé : pip install edge-tts")
        raise HTTPException(
            500,
            detail="edge-tts non installé. Exécute : pip install edge-tts",
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"❌ [TTS] Erreur: {e}")
        raise HTTPException(500, detail=f"Échec TTS: {str(e)}")