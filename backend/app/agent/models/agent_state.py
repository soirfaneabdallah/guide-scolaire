# ============================================================
# FICHIER: backend/app/agent/models/agent_state.py
# DESCRIPTION: Etat de l'agent
# ============================================================

from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime
from enum import Enum


class AgentStatus(str, Enum):
    """Statut de l'agent"""
    IDLE = "idle"
    ANALYZING = "analyzing"
    DECIDING = "deciding"
    EXECUTING = "executing"
    OBSERVING = "observing"
    EVALUATING = "evaluating"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class ExecutionStep(BaseModel):
    """Une etape d'execution"""
    step_number: int
    timestamp: datetime = Field(default_factory=datetime.now)
    status: AgentStatus
    action: Optional[str] = None
    observation: Optional[str] = None
    error: Optional[str] = None
    duration_ms: Optional[float] = None


class AgentState(BaseModel):
    """Etat complet de l'agent"""
    # Identifiants
    session_id: str
    user_id: int
    
    # Objectif
    objective: str
    initial_objective: str
    
    # Contexte
    subject: Optional[str] = None
    level: str = "3eme"
    context: Dict[str, Any] = Field(default_factory=dict)
    
    # Historique
    steps: List[ExecutionStep] = Field(default_factory=list)
    current_step: int = 0
    max_steps: int = 20
    
    # Connaissances accumulees
    knowledge: List[str] = Field(default_factory=list)
    
    # Statut
    status: AgentStatus = AgentStatus.IDLE
    is_complete: bool = False
    is_failed: bool = False
    failure_reason: Optional[str] = None
    
    # Metadonnees
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    iterations: int = 0
    
    def add_step(self, status: AgentStatus, action: Optional[str] = None, observation: Optional[str] = None):
        """Ajoute une etape a l'historique"""
        self.current_step += 1
        self.steps.append(
            ExecutionStep(
                step_number=self.current_step,
                status=status,
                action=action,
                observation=observation
            )
        )
        self.updated_at = datetime.now()
        self.iterations = self.current_step
    
    def add_knowledge(self, knowledge: str):
        """Ajoute une connaissance"""
        if knowledge not in self.knowledge:
            self.knowledge.append(knowledge)
            self.updated_at = datetime.now()
    
    def to_dict(self) -> Dict[str, Any]:
        """Convertit en dictionnaire"""
        return {
            "session_id": self.session_id,
            "user_id": self.user_id,
            "objective": self.objective,
            "subject": self.subject,
            "level": self.level,
            "status": self.status.value if hasattr(self.status, 'value') else str(self.status),
            "iterations": self.iterations,
            "is_complete": self.is_complete,
            "is_failed": self.is_failed,
            "knowledge_count": len(self.knowledge),
            "steps_count": len(self.steps),
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat()
        }