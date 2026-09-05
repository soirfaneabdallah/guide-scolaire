# ============================================================
# FICHIER: backend/app/agent/graph/state.py
# DESCRIPTION: Etat du graphe LangGraph
# ============================================================

from typing import TypedDict, Optional, List, Dict, Any, Literal
from datetime import datetime


class AgentGraphState(TypedDict, total=False):
    """
    Etat du graphe LangGraph.
    C'est le type d'etat qui circule entre les noeuds.
    """
    
    # Session
    session_id: str
    user_id: int
    
    # Objectif
    objective: str
    initial_objective: str
    
    # Contexte
    subject: Optional[str]
    level: str
    context: Dict[str, Any]
    
    # Iterations
    iterations: int
    max_iterations: int
    
    # Decision actuelle
    current_action: Optional[str]
    current_query: Optional[str]
    current_tool: Optional[str]
    current_arguments: Optional[Dict[str, Any]]
    
    # Resultats
    rag_results: List[Dict[str, Any]]
    tool_results: List[Dict[str, Any]]
    accumulated_knowledge: List[str]
    
    # Statut
    should_continue: Literal["continue", "finish", "error"]
    status: str
    is_complete: bool
    error: Optional[str]
    
    # Final
    final_answer: Optional[str]
    completion_reason: Optional[str]
    
    # Metadonnees
    start_time: Optional[datetime]
    step_history: List[Dict[str, Any]]