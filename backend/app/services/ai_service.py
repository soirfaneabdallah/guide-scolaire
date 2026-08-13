# backend/app/services/ia_client.py

import httpx
from typing import Dict, Any, Optional
from ..core.config import settings

class IAClient:
    """Client pour communiquer avec le service IA."""
    
    def __init__(self, base_url: Optional[str] = None):
        self.base_url = base_url or settings.IA_SERVICE_URL
        self.timeout = 180.0  # 2 minutes pour le modèle
        print(f"🔗 IA Client connecté à: {self.base_url}")  # 👈 Log pour vérifier
    
    async def ask(self, question: str, level: str = "3ème") -> Dict[str, Any]:
        """Envoie une question au service IA."""
        url = f"{self.base_url}/api/ask"
        print(f"📤 Envoi à: {url}")  # 👈 Log pour vérifier
        
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(
                url,
                json={
                    "question": question,
                    "level": level,
                }
            )
            print(f"📥 Réponse: {response.status_code}")  # 👈 Log pour vérifier
            response.raise_for_status()
            return response.json()