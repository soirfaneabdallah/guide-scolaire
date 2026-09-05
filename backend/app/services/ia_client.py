# ============================================================
# FICHIER: backend/app/services/ia_client.py
# DESCRIPTION: Client pour communiquer avec le service IA
# ============================================================

import httpx
import logging
from typing import Dict, Any, Optional, List

from ..core.config import settings

logger = logging.getLogger(__name__)


class IAClient:
    """
    Client pour communiquer avec le service IA (ia-service).
    Gère les appels HTTP vers l'API du service IA.
    """
    
    def __init__(self, base_url: Optional[str] = None):
        self.base_url = base_url or settings.IA_SERVICE_URL
        self.timeout = 180.0  # 3 minutes pour le modèle
        logger.info(f"🔗 IA Client connecté à: {self.base_url}")
    
    async def ask(
        self,
        question: str,
        level: str = "3ème",
        subject: Optional[str] = None,
        history: Optional[List[Dict[str, str]]] = None,
        session_id: Optional[str] = None,
        turn_number: int = 1
    ) -> Dict[str, Any]:
        """
        Envoie une question au service IA.
        
        Args:
            question: Question de l'utilisateur
            level: Niveau scolaire
            subject: Matière (optionnel)
            history: Historique de la conversation
            session_id: ID de session (optionnel)
            turn_number: Numéro du tour
            
        Returns:
            Dict: Réponse du service IA
        """
        url = f"{self.base_url}/api/ask"
        
        # Construire le payload
        payload = {
            "question": question,
            "level": level,
            "turn_number": turn_number
        }
        
        if subject:
            payload["subject"] = subject
        
        if history:
            payload["history"] = history
        
        if session_id:
            payload["session_id"] = session_id
        
        logger.info(f"📤 Envoi à: {url}")
        logger.info(f"📝 Question: {question[:50]}...")
        logger.info(f"📚 Niveau: {level}, Matière: {subject or 'général'}")
        
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    url,
                    json=payload,
                    headers={"Content-Type": "application/json"}
                )
                
                logger.info(f"📥 Réponse status: {response.status_code}")
                
                if response.status_code != 200:
                    logger.error(f"❌ Erreur IA: {response.status_code} - {response.text}")
                    return self._get_fallback_response(question)
                
                data = response.json()
                
                # Vérifier si la réponse est vide
                if not data.get("response"):
                    logger.warning("⚠️ Réponse IA vide")
                    return self._get_fallback_response(question)
                
                logger.info(f"✅ Réponse reçue: {data.get('response', '')[:50]}...")
                return data
                
        except httpx.TimeoutException:
            logger.error("⏰ Timeout du service IA")
            return self._get_fallback_response(question, "timeout")
            
        except httpx.ConnectError:
            logger.error("🔌 Connexion au service IA impossible")
            return self._get_fallback_response(question, "connection_error")
            
        except httpx.HTTPStatusError as e:
            logger.error(f"❌ HTTP Error: {e.response.status_code} - {e.response.text}")
            return self._get_fallback_response(question, f"http_{e.response.status_code}")
            
        except Exception as e:
            logger.error(f"❌ Erreur IA: {str(e)}")
            return self._get_fallback_response(question, str(e))
    
    def _get_fallback_response(self, question: str, error: Optional[str] = None) -> Dict[str, Any]:
        """
        Retourne une réponse de fallback si le service IA n'est pas disponible.
        """
        import random
        
        fallbacks = [
            "Je comprends votre question. Pour vous aider au mieux, pourriez-vous me donner plus de détails ? 😊",
            "C'est une question intéressante ! Je vais vous expliquer de manière simple et claire.",
            "Je vois que vous voulez en savoir plus. Je vous propose une explication étape par étape.",
            "Très bonne question ! Je vais vous donner une réponse détaillée et adaptée à votre niveau."
        ]
        
        return {
            "response": random.choice(fallbacks),
            "intent": question,
            "subject": "général",
            "wants_video": False,
            "concept": None,
            "needs_video_generation": False,
            "video_prompt": None,
            "model_loaded": False,
            "fallback": True,
            "error": error
        }
    
    async def video_prompt(
        self,
        concept: str,
        level: str = "3ème",
        subject: Optional[str] = None,
        duration_sec: int = 90,
        history: Optional[List[Dict[str, str]]] = None
    ) -> Dict[str, Any]:
        """
        Génère un prompt pour la création de vidéo.
        """
        url = f"{self.base_url}/api/video_prompt"
        
        payload = {
            "concept": concept,
            "level": level,
            "duration_sec": duration_sec,
            "history": history or []
        }
        
        if subject:
            payload["subject"] = subject
        
        logger.info(f"🎬 Video prompt pour: {concept}")
        
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(url, json=payload)
                
                if response.status_code != 200:
                    logger.error(f"❌ Erreur video prompt: {response.status_code}")
                    return {
                        "system_prompt": f"Crée une animation pédagogique sur {concept}",
                        "user_prompt": f"Explique {concept} de manière claire",
                        "concept": concept,
                        "level": level,
                        "fallback": True
                    }
                
                return response.json()
                
        except Exception as e:
            logger.error(f"❌ Erreur video prompt: {str(e)}")
            return {
                "system_prompt": f"Crée une animation pédagogique sur {concept}",
                "user_prompt": f"Explique {concept} de manière claire",
                "concept": concept,
                "level": level,
                "fallback": True
            }
    
    async def get_status(self) -> Dict[str, Any]:
        """
        Récupère le statut du service IA.
        """
        url = f"{self.base_url}/api/status"
        
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(url)
                
                if response.status_code != 200:
                    return {"status": "error", "detail": "Service IA non disponible"}
                
                return response.json()
                
        except Exception as e:
            logger.error(f"❌ Erreur status: {str(e)}")
            return {"status": "error", "detail": str(e)}
    
    async def check_health(self) -> Dict[str, Any]:
        """
        Vérifie la santé du service IA.
        """
        url = f"{self.base_url}/health"
        
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(url)
                
                if response.status_code != 200:
                    return {"status": "error", "detail": "Service IA non disponible"}
                
                return response.json()
                
        except Exception as e:
            logger.error(f"❌ Erreur health: {str(e)}")
            return {"status": "error", "detail": str(e)}