# ============================================================
# FICHIER: backend/app/services/video/ia_service_client.py
# DESCRIPTION: Client HTTP vers ia-service (localhost:8002)
# ============================================================

import logging
from typing import Optional

import httpx

logger = logging.getLogger(__name__)


class IAServiceClient:
    """Client HTTP vers ia-service (localhost:8002)."""

    BASE_URL = "http://localhost:8002"

    async def generate_script(
        self,
        prompt: str,
        duration_seconds: int = 180,
        n_scenes: int = 8,
    ) -> Optional[dict]:
        """
        Demande à ia-service de générer un script complet.

        Retourne :
            {
                "title": "...",
                "subject_hint": "...",
                "scenes": [
                    {
                        "index": 0,
                        "archetype": "title_card",
                        "title": "...",
                        "narration": "...",
                        "class_name": "Scene00",
                        "manim_code": "...",
                        "duration": 8.5,
                    },
                    ...
                ]
            }
        ou None en cas d'échec.
        """
        async with httpx.AsyncClient(timeout=600.0) as client:
            try:
                resp = await client.post(
                    f"{self.BASE_URL}/api/script/generate",
                    json={
                        "prompt": prompt,
                        "duration_seconds": duration_seconds,
                        "n_scenes": n_scenes,
                    },
                )
                resp.raise_for_status()
                data = resp.json()
                logger.info(
                    f"✅ [IA] Script reçu : {len(data.get('scenes', []))} scènes"
                )
                return data
            except httpx.HTTPStatusError as e:
                logger.error(
                    f"❌ [IA] generate_script HTTP {e.response.status_code}: "
                    f"{e.response.text[:200]}"
                )
                return None
            except Exception as e:
                logger.error(f"❌ [IA] generate_script échoué: {e}")
                return None

    async def synthesize_tts(self, text: str, lang: str = "fr") -> Optional[bytes]:
        """Synthétise la narration en audio (MP3 bytes)."""
        async with httpx.AsyncClient(timeout=120.0) as client:
            try:
                resp = await client.post(
                    f"{self.BASE_URL}/api/tts/synthesize",
                    json={"text": text, "lang": lang},
                )
                resp.raise_for_status()
                return resp.content
            except Exception as e:
                logger.error(f"❌ [IA] synthesize_tts échoué: {e}")
                return None

    async def render_manim(
        self,
        code: str,
        scene_name: str,
        quality: str = "l",
    ) -> Optional[bytes]:
        """Rend le code Manim en MP4 (bytes)."""
        async with httpx.AsyncClient(timeout=300.0) as client:
            try:
                resp = await client.post(
                    f"{self.BASE_URL}/api/manim/render",
                    json={
                        "code": code,
                        "scene_name": scene_name,
                        "quality": quality,
                    },
                )
                resp.raise_for_status()
                return resp.content
            except Exception as e:
                logger.error(f"❌ [IA] render_manim échoué: {e}")
                return None