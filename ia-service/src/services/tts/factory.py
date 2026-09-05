# ============================================================
# FICHIER: backend/app/services/tts/factory.py
# DESCRIPTION: Factory de services TTS
# ============================================================

from enum import Enum
from typing import Dict, Type, Optional

from .base_tts import BaseTTS
from .edge_tts_client import EdgeTTSClient
from .coqui_tts_client import CoquiTTSClient
from src.core.constants.video_constants import PREFERRED_TTS_ENGINES


class TTSType(Enum):
    """Types de moteurs TTS disponibles"""
    EDGE = "edge"
    COQUI = "coqui"
    ELEVENLABS = "elevenlabs"  # Future extension
    AZURE = "azure"  # Future extension


class TTSFactory:
    """
    Factory pour les services TTS.
    Pattern Registry pour une extensibilite maximale.
    """
    
    _tts_engines: Dict[str, Type[BaseTTS]] = {}
    
    @classmethod
    def register(cls, tts_type: TTSType, tts_class: Type[BaseTTS]):
        """
        Enregistre un nouveau moteur TTS.
        
        Args:
            tts_type: Type du moteur
            tts_class: Classe du moteur
        """
        cls._tts_engines[tts_type.value] = tts_class
        print(f"✅ Moteur TTS enregistre: {tts_type.value}")
    
    @classmethod
    def get_tts(cls, tts_type: TTSType, **kwargs) -> Optional[BaseTTS]:
        """
        Recupere une instance du moteur TTS.
        
        Args:
            tts_type: Type du moteur
            **kwargs: Arguments pour l'initialisation
            
        Returns:
            Optional[BaseTTS]: Instance du moteur ou None
        """
        tts_class = cls._tts_engines.get(tts_type.value)
        if not tts_class:
            return None
        return tts_class(**kwargs)
    
    @classmethod
    def get_preferred_tts(cls, **kwargs) -> Optional[BaseTTS]:
        """
        Recupere le moteur TTS prefere selon la configuration.
        
        Returns:
            Optional[BaseTTS]: Moteur prefere ou None
        """
        for preferred in PREFERRED_TTS_ENGINES:
            tts = cls.get_tts(TTSType(preferred), **kwargs)
            if tts:
                return tts
        return None


# Enregistrer les moteurs TTS par defaut
TTSFactory.register(TTSType.EDGE, EdgeTTSClient)
TTSFactory.register(TTSType.COQUI, CoquiTTSClient)
