# ============================================================
# FICHIER: backend/app/agent/models/decisions.py
# DESCRIPTION: Decisions structurees de l'agent
# ============================================================

from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field
from enum import Enum


class ActionType(str, Enum):
    """Types d'actions possibles"""
    RAG = "rag"
    TOOL = "tool"
    FINISH = "finish"
    CLARIFY = "clarify"
    WAIT = "wait"


class AgentDecision(BaseModel):
    """Decision structuree de l'agent"""
    action: ActionType
    reason: str = Field(..., description="Raison de la decision")
    
    # Pour RAG
    rag_query: Optional[str] = None
    rag_filters: Optional[Dict[str, Any]] = None
    
    # Pour Tool
    tool_name: Optional[str] = None
    tool_arguments: Optional[Dict[str, Any]] = None
    
    # Pour Finish
    final_answer: Optional[str] = None
    completion_reason: Optional[str] = None
    
    # Pour Clarify
    clarification_question: Optional[str] = None
    
    # Metadonnees
    confidence: float = Field(0.0, ge=0.0, le=1.0)
    requires_human: bool = False
    
    def to_dict(self) -> Dict[str, Any]:
        """Convertit en dictionnaire"""
        result = {
            "action": self.action.value if hasattr(self.action, 'value') else str(self.action),
            "reason": self.reason,
            "confidence": self.confidence
        }
        
        if self.rag_query:
            result["rag_query"] = self.rag_query
        if self.tool_name:
            result["tool_name"] = self.tool_name
            result["tool_arguments"] = self.tool_arguments
        if self.final_answer:
            result["final_answer"] = self.final_answer
        if self.clarification_question:
            result["clarification_question"] = self.clarification_question
        
        return result


class ToolCall(BaseModel):
    """Appel d'outil structure"""
    tool_name: str
    arguments: Dict[str, Any] = Field(default_factory=dict)
    result: Optional[Any] = None
    error: Optional[str] = None
    success: bool = False
    duration_ms: Optional[float] = None


class RagQuery(BaseModel):
    """Requete RAG structuree"""
    query: str
    filters: Optional[Dict[str, Any]] = None
    top_k: int = 5
    results: Optional[List[Dict[str, Any]]] = None
    success: bool = False
    error: Optional[str] = None