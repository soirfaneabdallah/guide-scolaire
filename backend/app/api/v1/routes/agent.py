# ============================================================
# FICHIER: backend/app/api/v1/routes/agent.py
# DESCRIPTION: Endpoints API pour l'agent
# ============================================================

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
import logging

from ....core.dependencies import get_current_active_user
from ....models.user import User
from ....agent.orchestrator.agent_orchestrator import agent_orchestrator
from ....agent.models.agent_state import AgentState

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/agent", tags=["Agent"])


# ============================================================
# MODÈLES DE REQUÊTE / RÉPONSE
# ============================================================

class AgentExecuteRequest(BaseModel):
    """Requête pour exécuter l'agent."""
    objective: str = Field(..., description="L'objectif à atteindre", min_length=3, max_length=500)
    subject: Optional[str] = Field(None, description="Matière concernée")
    level: str = Field("3ème", description="Niveau scolaire")
    context: Optional[Dict[str, Any]] = Field(None, description="Contexte supplémentaire")
    max_iterations: int = Field(20, description="Nombre maximum d'itérations", ge=1, le=50)


class AgentExecuteResponse(BaseModel):
    """Réponse de l'exécution de l'agent."""
    session_id: str
    success: bool
    answer: str
    iterations: int
    status: str
    knowledge: List[str] = []
    duration_ms: Optional[float] = None


class AgentSessionResponse(BaseModel):
    """Statut d'une session."""
    session_id: str
    user_id: int
    objective: str
    status: str
    is_complete: bool
    iterations: int
    knowledge_count: int
    created_at: str
    updated_at: str


class AgentHistoryResponse(BaseModel):
    """Réponse de l'historique."""
    session_id: str
    objective: str
    timestamp: str
    success: bool
    iterations: int


# ============================================================
# ROUTES
# ============================================================

@router.post("/execute", response_model=AgentExecuteResponse)
async def execute_agent(
    request: AgentExecuteRequest,
    current_user: User = Depends(get_current_active_user),
):
    """
    Exécute l'agent sur un objectif.
    
    L'agent va :
    1. Analyser l'objectif
    2. Décider des actions à entreprendre
    3. Utiliser les outils disponibles (recherche, calcul, vidéo)
    4. Observer les résultats
    5. Évaluer si l'objectif est atteint
    6. Itérer jusqu'à ce que l'objectif soit atteint ou que la limite soit dépassée
    """
    try:
        logger.info(f"🤖 Lancement de l'agent pour l'utilisateur {current_user.email}")
        logger.info(f"📌 Objectif: {request.objective[:100]}...")
        
        result = await agent_orchestrator.execute(
            objective=request.objective,
            user_id=current_user.id,
            subject=request.subject,
            level=request.level,
            context=request.context,
            max_iterations=request.max_iterations
        )
        
        return AgentExecuteResponse(
            session_id=result["session_id"],
            success=result["success"],
            answer=result["answer"],
            iterations=result["iterations"],
            status=result["status"],
            knowledge=result.get("knowledge", []),
            duration_ms=result.get("duration_ms")
        )
        
    except Exception as e:
        logger.error(f"❌ Erreur agent: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/session/{session_id}", response_model=AgentSessionResponse)
async def get_session_status(
    session_id: str,
    current_user: User = Depends(get_current_active_user),
):
    """
    Récupère le statut d'une session.
    """
    session = await agent_orchestrator.get_session(session_id)
    
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session non trouvée"
        )
    
    if session.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous n'avez pas accès à cette session"
        )
    
    return AgentSessionResponse(
        session_id=session.session_id,
        user_id=session.user_id,
        objective=session.objective,
        status=session.status.value if hasattr(session.status, 'value') else str(session.status),
        is_complete=session.is_complete,
        iterations=session.iterations,
        knowledge_count=len(session.knowledge),
        created_at=session.created_at.isoformat(),
        updated_at=session.updated_at.isoformat()
    )


@router.delete("/session/{session_id}")
async def cancel_session(
    session_id: str,
    current_user: User = Depends(get_current_active_user),
):
    """
    Annule une session en cours.
    """
    session = await agent_orchestrator.get_session(session_id)
    
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session non trouvée"
        )
    
    if session.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous n'avez pas accès à cette session"
        )
    
    cancelled = await agent_orchestrator.cancel_session(session_id)
    
    if not cancelled:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Impossible d'annuler cette session (déjà terminée ou non annulable)"
        )
    
    return {"message": "Session annulée avec succès"}


@router.get("/history", response_model=List[AgentHistoryResponse])
async def get_agent_history(
    current_user: User = Depends(get_current_active_user),
    limit: int = 10,
):
    """
    Récupère l'historique des exécutions de l'agent.
    """
    history = await agent_orchestrator.get_history(
        user_id=current_user.id,
        limit=limit
    )
    
    return [
        AgentHistoryResponse(
            session_id=h["session_id"],
            objective=h["objective"],
            timestamp=h["timestamp"],
            success=h["success"],
            iterations=h["iterations"]
        )
        for h in history
    ]


@router.get("/status")
async def get_agent_status():
    """
    Vérifie le statut de l'agent.
    """
    try:
        sessions = agent_orchestrator.get_sessions()
        active_sessions = len([
            s for s in sessions.values()
            if s.status.value not in ["completed", "failed", "cancelled"]
        ])
        
        return {
            "status": "ok",
            "agent": "AgentOrchestrator",
            "active_sessions": active_sessions,
            "total_sessions": len(sessions)
        }
    except Exception as e:
        return {
            "status": "error",
            "error": str(e)
        }