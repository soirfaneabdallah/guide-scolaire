# ============================================================
# FICHIER: backend/app/services/tts/edge_tts_client.py
# DESCRIPTION: Client TTS utilisant l'API Edge (Microsoft)
# ============================================================

import edge_tts
import asyncio
from pathlib import Path
from typing import List, Optional

from .base_tts import BaseTTS
from src.schemas.video_schemas import NarrationScript
from src.core.constants.video_constants import TTS_TIMEOUT_SECONDS

import logging

logger = logging.getLogger(__name__)


class EdgeTTSClient(BaseTTS):
    """
    Client TTS utilisant l'API Microsoft Edge (gratuit).
    Qualite excellente, sans GPU requis.
    """
    
    DEFAULT_VOICE = "fr-FR-DeniseNeural"
    SUPPORTED_VOICES = {
        "fr-FR-DeniseNeural": "Francais - Denise (naturelle)",
        "fr-FR-HenriNeural": "Francais - Henri (masculin)",
        "en-US-JennyNeural": "Anglais - Jenny",
        "en-US-GuyNeural": "Anglais - Guy",
        "es-ES-ElviraNeural": "Espagnol - Elvira",
        "de-DE-KatjaNeural": "Allemand - Katja",
    }
    
    def __init__(self, voice: str = DEFAULT_VOICE, speed: float = 1.2):
        self.voice = voice
        self.speed = speed
    
    async def generate_audio(
        self,
        text: str,
        output_path: str,
        voice: Optional[str] = None
    ) -> str:
        """
        Genere un fichier audio avec Edge TTS.
        """
        try:
            voice_to_use = voice or self.voice
            
            communicate = edge_tts.Communicate(
                text, 
                voice_to_use,
                rate=self.speed
            )
            
            await communicate.save(output_path)
            
            logger.debug(f"Audio genere: {output_path}")
            return output_path
            
        except Exception as e:
            logger.error(f"Erreur Edge TTS: {str(e)}")
            raise
    
    async def generate_segments(
        self,
        script: NarrationScript,
        job_id: str,
        workspace: dict,
        voice: Optional[str] = None
    ) -> List[str]:
        """
        Genere les segments audio pour un script complet.
        """
        audio_dir = Path(workspace["audio"])
        audio_dir.mkdir(parents=True, exist_ok=True)
        
        audio_paths = []
        
        for i, segment in enumerate(script.segments):
            output_path = audio_dir / f"segment_{i:03d}.mp3"
            
            # Ajouter une petite pause avant chaque segment
            text_with_pause = f" {segment.text} "
            
            await self.generate_audio(
                text=text_with_pause,
                output_path=str(output_path),
                voice=voice
            )
            
            audio_paths.append(str(output_path))
            logger.debug(f"Segment {i} genere: {output_path}")
        
        return audio_paths
    
    async def get_voices(self) -> List[str]:
        """
        Recupere la liste des voix disponibles.
        """
        return list(self.SUPPORTED_VOICES.keys())
