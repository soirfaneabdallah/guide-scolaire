# ============================================================
# FICHIER: backend/app/services/tts/coqui_tts_client.py
# DESCRIPTION: Client TTS utilisant Coqui TTS (open source, auto-heberge)
# ============================================================

import os
import tempfile
from pathlib import Path
from typing import List, Optional
import asyncio
import subprocess

from .base_tts import BaseTTS
from src.schemas.video_schemas import NarrationScript
from src.core.constants.video_constants import TTS_TIMEOUT_SECONDS

import logging

logger = logging.getLogger(__name__)


class CoquiTTSClient(BaseTTS):
    """
    Client TTS utilisant Coqui TTS (open source).
    Auto-heberge, necessite un GPU pour de bonnes performances.
    """
    
    DEFAULT_MODEL = "tts_models/fr/css10/vits"
    DEFAULT_VOICE = "fr_FR"
    
    def __init__(
        self,
        model_name: str = DEFAULT_MODEL,
        voice: str = DEFAULT_VOICE,
        use_gpu: bool = False
    ):
        self.model_name = model_name
        self.voice = voice
        self.use_gpu = use_gpu
        self._tts = None
        self._initialized = False
    
    async def _initialize(self):
        """
        Initialise le modele TTS (lazy loading).
        """
        if self._initialized:
            return
        
        try:
            # Verifier si TTS est installe
            try:
                import TTS
            except ImportError:
                logger.warning("TTS non installe. Utilisation du fallback Edge TTS.")
                # Fallback vers Edge TTS
                from .edge_tts_client import EdgeTTSClient
                self._tts = EdgeTTSClient()
                self._initialized = True
                return
            
            # Initialiser TTS
            from TTS.api import TTS
            
            logger.info(f"Chargement du modele TTS: {self.model_name}")
            
            # Charger le modele
            self._tts = TTS(
                model_name=self.model_name,
                gpu=self.use_gpu
            )
            
            self._initialized = True
            logger.info("Modele TTS charge avec succes")
            
        except Exception as e:
            logger.error(f"Erreur initialisation Coqui TTS: {str(e)}")
            # Fallback vers Edge TTS
            from .edge_tts_client import EdgeTTSClient
            self._tts = EdgeTTSClient()
            self._initialized = True
    
    async def generate_audio(
        self,
        text: str,
        output_path: str,
        voice: Optional[str] = None
    ) -> str:
        """
        Genere un fichier audio avec Coqui TTS.
        """
        try:
            await self._initialize()
            
            # Si le fallback Edge TTS a ete utilise
            if hasattr(self._tts, 'generate_audio') and not hasattr(self._tts, 'tts_to_file'):
                return await self._tts.generate_audio(text, output_path, voice)
            
            # Coqui TTS
            voice_to_use = voice or self.voice
            
            # Generer l'audio
            self._tts.tts_to_file(
                text=text,
                file_path=output_path,
                speaker=voice_to_use
            )
            
            logger.debug(f"Audio genere: {output_path}")
            return output_path
            
        except Exception as e:
            logger.error(f"Erreur Coqui TTS: {str(e)}")
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
        await self._initialize()
        
        audio_dir = Path(workspace["audio"])
        audio_dir.mkdir(parents=True, exist_ok=True)
        
        audio_paths = []
        
        for i, segment in enumerate(script.segments):
            output_path = audio_dir / f"segment_{i:03d}.wav"
            
            await self.generate_audio(
                text=segment.text,
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
        # Coqui TTS supporte plusieurs voix selon le modele
        # Pour l'instant, retourner la voix par defaut
        return [self.DEFAULT_VOICE]
    
    @staticmethod
    async def is_available() -> bool:
        """
        Verifie si Coqui TTS est disponible.
        """
        try:
            import TTS
            return True
        except ImportError:
            return False


# ============================================================
# VERSION LEGER POUR CPU (sans GPU)
# ============================================================

class CoquiTTSCPUClient(CoquiTTSClient):
    """
    Version CPU de Coqui TTS (plus lent mais sans GPU).
    """
    
    def __init__(self, model_name: str = "tts_models/fr/css10/vits"):
        super().__init__(
            model_name=model_name,
            use_gpu=False
        )


# ============================================================
# VERSION AVEC PIPELINE DE TRAITEMENT
# ============================================================

class CoquiTTSBatchClient(CoquiTTSClient):
    """
    Version batch de Coqui TTS pour generer plusieurs fichiers en une fois.
    """
    
    async def generate_batch(
        self,
        texts: List[str],
        output_dir: str,
        prefix: str = "audio"
    ) -> List[str]:
        """
        Genere plusieurs fichiers audio en batch.
        
        Args:
            texts: Liste des textes a synthetiser
            output_dir: Dossier de sortie
            prefix: Prefixe des fichiers
            
        Returns:
            List[str]: Chemins des fichiers generes
        """
        await self._initialize()
        
        output_paths = []
        output_dir_path = Path(output_dir)
        output_dir_path.mkdir(parents=True, exist_ok=True)
        
        for i, text in enumerate(texts):
            output_path = output_dir_path / f"{prefix}_{i:03d}.wav"
            
            await self.generate_audio(
                text=text,
                output_path=str(output_path)
            )
            
            output_paths.append(str(output_path))
        
        return output_paths


# ============================================================
# UTILITAIRE D'INSTALLATION
# ============================================================

def install_coqui_tts():
    """
    Installe Coqui TTS avec pip.
    """
    import subprocess
    import sys
    
    print("Installation de Coqui TTS...")
    subprocess.check_call([
        sys.executable, "-m", "pip", "install",
        "TTS",
        "torch", "torchaudio",  # Pour le support GPU
        "--extra-index-url", "https://download.pytorch.org/whl/cu118"
    ])
    print("Coqui TTS installe avec succes !")
