# ============================================================
# FICHIER: backend/app/agent/graph/graph.py
# DESCRIPTION: Construction du graphe LangGraph
# ============================================================

from typing import Literal, Dict, Any
from langgraph.graph import StateGraph, END

from .state import AgentGraphState
from .nodes import AgentNodes
import logging

logger = logging.getLogger(__name__)


class AgentGraph:
    """
    Graphe LangGraph pour l'agent.
    """
    
    def __init__(self):
        self.nodes = AgentNodes()
        self._graph = None
        self._app = None
        self._build_graph()
    
    def _build_graph(self):
        """Construit le graphe LangGraph."""
        
        graph = StateGraph(AgentGraphState)
        
        # Ajouter les noeuds
        graph.add_node("analyze", self.nodes.analyze_node)
        graph.add_node("decide", self.nodes.decide_node)
        graph.add_node("rag", self.nodes.rag_node)
        graph.add_node("tool", self.nodes.tool_node)
        graph.add_node("observe", self.nodes.observe_node)
        graph.add_node("evaluate", self.nodes.evaluate_node)
        
        # Transitions
        graph.add_edge("analyze", "decide")
        graph.add_edge("evaluate", "analyze")
        
        # Transitions conditionnelles
        graph.add_conditional_edges(
            "decide",
            self._route_decision,
            {
                "rag": "rag",
                "tool": "tool",
                "finish": END,
                "error": END
            }
        )
        
        graph.add_conditional_edges(
            "rag",
            self._route_after_action,
            {"observe": "observe", "error": END}
        )
        
        graph.add_conditional_edges(
            "tool",
            self._route_after_action,
            {"observe": "observe", "error": END}
        )
        
        graph.add_conditional_edges(
            "observe",
            self._route_after_action,
            {"evaluate": "evaluate", "error": END}
        )
        
        graph.add_conditional_edges(
            "evaluate",
            self._route_after_evaluate,
            {"continue": "analyze", "finish": END, "error": END}
        )
        
        # Point d'entree
        graph.set_entry_point("analyze")
        
        self._graph = graph
        self._app = graph.compile()
        
        logger.info("✅ Graphe LangGraph construit")
    
    def _route_decision(self, state: Dict[str, Any]) -> Literal["rag", "tool", "finish", "error"]:
        """Route la decision de l'agent."""
        action = state.get('current_action', 'finish')
        
        if action == 'rag':
            return 'rag'
        elif action == 'tool':
            return 'tool'
        elif action == 'finish':
            return 'finish'
        else:
            return 'error'
    
    def _route_after_action(self, state: Dict[str, Any]) -> Literal["observe", "error"]:
        """Route apres une action."""
        if state.get('error'):
            return 'error'
        return 'observe'
    
    def _route_after_evaluate(self, state: Dict[str, Any]) -> Literal["continue", "finish", "error"]:
        """Route apres l'evaluation."""
        if state.get('error'):
            return 'error'
        if state.get('should_continue') == 'continue':
            return 'continue'
        return 'finish'
    
    async def execute(
        self,
        objective: str,
        user_id: int,
        session_id: str,
        subject: str = "general",
        level: str = "3eme",
        max_iterations: int = 20
    ) -> Dict[str, Any]:
        """
        Execute l'agent sur un objectif.
        """
        initial_state: AgentGraphState = {
            "session_id": session_id,
            "user_id": user_id,
            "objective": objective,
            "initial_objective": objective,
            "subject": subject,
            "level": level,
            "iterations": 0,
            "max_iterations": max_iterations,
            "context": {},
            "rag_results": [],
            "tool_results": [],
            "accumulated_knowledge": [],
            "should_continue": "continue",
            "status": "idle",
            "is_complete": False,
            "step_history": [],
            "start_time": None
        }
        
        logger.info(f"🚀 Agent sur: {objective[:50]}...")
        
        try:
            final_state = await self._app.ainvoke(initial_state)
            
            return {
                "success": final_state.get("is_complete", False),
                "answer": final_state.get("final_answer", "Objectif non atteint."),
                "iterations": final_state.get("iterations", 0),
                "status": final_state.get("status", "completed"),
                "knowledge": final_state.get("accumulated_knowledge", [])
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur: {str(e)}")
            return {
                "success": False,
                "answer": f"Erreur: {str(e)}",
                "iterations": 0,
                "status": "failed"
            }


# Instance globale
agent_graph = AgentGraph()