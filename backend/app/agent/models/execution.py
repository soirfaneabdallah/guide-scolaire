# ============================================================
# FICHIER: backend/app/agent/models/execution.py
# DESCRIPTION: Modeles d'execution de l'agent
# ============================================================

from typing import Optional, List, Dict, Any
from pydantic import BaseModel
from datetime import datetime


class ExecutionResult(BaseModel):
    """Resultat d'une execution"""
    session_id: str
    user_id: int
    objective: str
    success: bool
    answer: str
    iterations: int
    duration_seconds: float
    status: str
    knowledge: List[str] = []
    steps_summary: List[Dict[str, Any]] = []
    error: Optional[str] = None


class ExecutionSummary(BaseModel):
    """Resume d'une session"""
    session_id: str
    user_id: int
    objective: str
    status: str
    iterations: int
    created_at: datetime
    completed_at: Optional[datetime] = None
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "session_id": self.session_id,
            "user_id": self.user_id,
            "objective": self.objective[:100] + ("..." if len(self.objective) > 100 else ""),
            "status": self.status,
            "iterations": self.iterations,
            "created_at": self.created_at.isoformat(),
            "completed_at": self.completed_at.isoformat() if self.completed_at else None
        }