# ============================================================
# FICHIER: backend/app/agent/orchestrator/execution_tracker.py
# DESCRIPTION: Suivi des executions de l'agent
# ============================================================

import json
from typing import Dict, Any, Optional, List
from datetime import datetime
from pathlib import Path
import logging

logger = logging.getLogger(__name__)


class ExecutionTracker:
    """
    Suivi des executions de l'agent.
    Stocke les historiques dans des fichiers JSON pour l'instant.
    Plus tard, passage en base de donnees.
    """
    
    def __init__(self, storage_dir: str = "data/agent_executions"):
        self.storage_dir = Path(storage_dir)
        self.storage_dir.mkdir(parents=True, exist_ok=True)
    
    async def record_execution(
        self,
        session_id: str,
        user_id: int,
        objective: str,
        result: Dict[str, Any],
        duration_ms: Optional[float] = None
    ) -> None:
        """
        Enregistre une execution.
        """
        try:
            record = {
                "session_id": session_id,
                "user_id": user_id,
                "objective": objective,
                "result": result,
                "duration_ms": duration_ms,
                "timestamp": datetime.now().isoformat()
            }
            
            # Stocker dans un fichier JSON
            file_path = self.storage_dir / f"{session_id}.json"
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(record, f, indent=2, ensure_ascii=False)
            
            logger.info(f"📝 Execution enregistree: {session_id}")
            
        except Exception as e:
            logger.error(f"❌ Erreur enregistrement execution: {str(e)}")
    
    async def get_execution(self, session_id: str) -> Optional[Dict[str, Any]]:
        """
        Recupere une execution par son ID.
        """
        try:
            file_path = self.storage_dir / f"{session_id}.json"
            if not file_path.exists():
                return None
            
            with open(file_path, 'r', encoding='utf-8') as f:
                return json.load(f)
                
        except Exception as e:
            logger.error(f"❌ Erreur recuperation execution: {str(e)}")
            return None
    
    async def get_user_executions(
        self,
        user_id: int,
        limit: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Recupere les executions d'un utilisateur.
        """
        try:
            executions = []
            for file_path in self.storage_dir.glob("*.json"):
                with open(file_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    if data.get("user_id") == user_id:
                        executions.append({
                            "session_id": data.get("session_id"),
                            "objective": data.get("objective"),
                            "timestamp": data.get("timestamp"),
                            "success": data.get("result", {}).get("success", False),
                            "iterations": data.get("result", {}).get("iterations", 0)
                        })
            
            # Trier par date
            executions.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
            return executions[:limit]
            
        except Exception as e:
            logger.error(f"❌ Erreur recuperation historique: {str(e)}")
            return []