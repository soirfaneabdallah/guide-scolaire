# ============================================================
# FICHIER: backend/app/agent/orchestrator/agent_orchestrator.py
# DESCRIPTION: Orchestrateur principal de l'agent
# ============================================================

import uuid
import logging
from typing import Optional, Dict, Any, List  # ✅ AJOUTÉ List
from datetime import datetime

from ..graph.graph import agent_graph
from ..models.agent_state import AgentState, AgentStatus
from .execution_tracker import ExecutionTracker

logger = logging.getLogger(__name__)


class AgentOrchestrator:
    """
    Orchestrateur principal de l'agent.
    Gere les sessions, le contexte et l'execution du graphe.
    """
    
    def __init__(self):
        self.tracker = ExecutionTracker()
        self._sessions: Dict[str, AgentState] = {}
    
    async def execute(
        self,
        objective: str,
        user_id: int,
        subject: Optional[str] = None,
        level: str = "3eme",
        context: Optional[Dict[str, Any]] = None,
        max_iterations: int = 20
    ) -> Dict[str, Any]:
        """
        Execute l'agent sur un objectif.
        """
        # Generer un ID de session
        session_id = f"agent_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:8]}"
        
        logger.info(f"🚀 Lancement de l'agent")
        logger.info(f"   Session: {session_id}")
        logger.info(f"   Objectif: {objective[:100]}...")
        logger.info(f"   Utilisateur: {user_id}")
        logger.info(f"   Niveau: {level}, Matiere: {subject or 'general'}")
        
        # Creer l'etat
        state = AgentState(
            session_id=session_id,
            user_id=user_id,
            objective=objective,
            initial_objective=objective,
            subject=subject or "general",
            level=level,
            context=context or {},
            max_steps=max_iterations,
            status=AgentStatus.IDLE
        )
        
        # Stocker la session
        self._sessions[session_id] = state
        
        start_time = datetime.now()
        
        try:
            # Executer le graphe
            result = await agent_graph.execute(
                objective=objective,
                user_id=user_id,
                session_id=session_id,
                subject=subject or "general",
                level=level,
                max_iterations=max_iterations
            )
            
            duration_ms = (datetime.now() - start_time).total_seconds() * 1000
            
            # Mettre a jour l'etat
            state.is_complete = result.get("success", False)
            state.status = AgentStatus.COMPLETED if result.get("success") else AgentStatus.FAILED
            state.updated_at = datetime.now()
            
            # Enregistrer l'execution
            await self.tracker.record_execution(
                session_id=session_id,
                user_id=user_id,
                objective=objective,
                result=result,
                duration_ms=duration_ms
            )
            
            return {
                "session_id": session_id,
                "success": result.get("success", False),
                "answer": result.get("answer", "Objectif non atteint."),
                "iterations": result.get("iterations", 0),
                "status": result.get("status", "completed"),
                "knowledge": result.get("knowledge", []),
                "duration_ms": duration_ms
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur execution agent: {str(e)}")
            
            state.status = AgentStatus.FAILED
            state.is_failed = True
            state.failure_reason = str(e)
            state.updated_at = datetime.now()
            
            return {
                "session_id": session_id,
                "success": False,
                "answer": f"Erreur: {str(e)}",
                "iterations": 0,
                "status": "failed",
                "knowledge": [],
                "error": str(e)
            }
    
    async def get_session(self, session_id: str) -> Optional[AgentState]:
        """Recupere une session par son ID."""
        return self._sessions.get(session_id)
    
    async def cancel_session(self, session_id: str) -> bool:
        """Annule une session en cours."""
        if session_id in self._sessions:
            state = self._sessions[session_id]
            if state.status in [AgentStatus.IDLE, AgentStatus.ANALYZING, AgentStatus.DECIDING]:
                state.status = AgentStatus.CANCELLED
                state.is_complete = True
                state.updated_at = datetime.now()
                logger.info(f"⏹️ Session annulee: {session_id}")
                return True
            else:
                logger.warning(f"⚠️ Impossible d'annuler la session {session_id} (status: {state.status})")
                return False
        return False
    
    async def get_history(self, user_id: int, limit: int = 10) -> List[Dict[str, Any]]:
        """Recupere l'historique des executions pour un utilisateur."""
        return await self.tracker.get_user_executions(user_id, limit)
    
    def get_sessions(self) -> Dict[str, AgentState]:
        """Recupere toutes les sessions actives."""
        return self._sessions.copy()
    
    def cleanup_sessions(self, max_age_hours: int = 24):
        """Nettoie les sessions plus vieilles que max_age_hours."""
        now = datetime.now()
        to_remove = []
        
        for session_id, state in self._sessions.items():
            age = (now - state.updated_at).total_seconds() / 3600
            if age > max_age_hours:
                to_remove.append(session_id)
        
        for session_id in to_remove:
            del self._sessions[session_id]
        
        if to_remove:
            logger.info(f"🧹 Nettoyage de {len(to_remove)} sessions")
        
        return len(to_remove)


# Instance globale
agent_orchestrator = AgentOrchestrator()