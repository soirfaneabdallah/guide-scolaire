# backend/app/services/ia_client.py

import httpx
from typing import Dict, Any, Optional
from ..core.config import settings

class IAClient:
    """Client pour communiquer avec le service IA."""

    def __init__(self, base_url: Optional[str] = None):
        self.base_url = base_url or settings.IA_SERVICE_URL
        self.timeout = 120.0  # 2 minutes pour le modèle

    async def ask(self, question: str, level: str = "3ème") -> Dict[str, Any]:
        """Envoie une question au service IA."""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(
                f"{self.base_url}/api/ask",
                json={
                    "question": question,
                    "level": level,
                }
            )
            response.raise_for_status()
            return response.json()

    async def health(self) -> Dict[str, Any]:
        """Vérifie la santé du service IA."""
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{self.base_url}/api/health")
            return response.json()