# ============================================================
# FICHIER: backend/app/agent/graph/nodes.py
# DESCRIPTION: Noeuds du graphe LangGraph
# ============================================================

import json
import logging
from datetime import datetime
from typing import Any, Dict, Optional

from .state import AgentGraphState
from ..models.agent_state import AgentStatus
from ..tools.registry import tool_registry
from ...services.ia_client import IAClient

logger = logging.getLogger(__name__)


class AgentNodes:
    """
    Noeuds du graphe LangGraph.
    Chaque noeud est une etape de la boucle agentique.
    """
    
    def __init__(self):
        self.ia_client = IAClient()
    
    def _get_tools_description(self) -> str:
        """Retourne la description des outils pour le prompt."""
        return tool_registry.get_tools_for_prompt()
    
    def _build_decision_prompt(self, state: AgentGraphState) -> str:
        """Construit le prompt pour la decision."""
        
        # Connaissances
        knowledge = state.get('accumulated_knowledge', [])
        if knowledge:
            knowledge_text = "\n".join(f"- {k[:200]}" for k in knowledge[-5:])
        else:
            knowledge_text = "Aucune connaissance acquise pour le moment."
        
        # Historique
        history = state.get('step_history', [])
        if history:
            history_text = "\n".join(
                f"- Etape {i+1}: {step.get('action', 'unknown')} -> {str(step.get('result', ''))[:100]}"
                for i, step in enumerate(history[-5:])
            )
        else:
            history_text = "Aucune action effectuee pour le moment."
        
        # Outils
        tools_text = self._get_tools_description()
        
        return f"""Tu es un agent intelligent charge d'atteindre un objectif.

📌 OBJECTIF: {state['objective']}

📚 CONTEXTE:
- Niveau: {state.get('level', '3eme')}
- Matiere: {state.get('subject', 'general')}
- Iteration: {state.get('iterations', 0)}/{state.get('max_iterations', 20)}

📖 CONNAISSANCES ACQUISES:
{knowledge_text}

📋 HISTORIQUE DES ACTIONS:
{history_text}

🔧 OUTILS DISPONIBLES:
{tools_text}

🎯 DECISION A PRENDRE:
Tu dois decider de la prochaine action.

Actions possibles:
1. **rag** - Rechercher des informations
   Format: {{"action": "rag", "query": "recherche"}}

2. **tool** - Utiliser un outil
   Format: {{"action": "tool", "tool": "nom", "arguments": {{...}}}}

3. **finish** - Terminer
   Format: {{"action": "finish", "final_answer": "reponse", "reason": "raison"}}

4. **clarify** - Demander une clarification
   Format: {{"action": "clarify", "question": "question"}}

REPONDS AVEC UN JSON UNIQUEMENT."""
    
    async def analyze_node(self, state: AgentGraphState) -> Dict[str, Any]:
        """
        Noeud d'analyse.
        """
        logger.info(f"🔍 Analyse: {state['objective'][:50]}...")
        
        return {
            "status": "analyzing",
            "context": {
                **state.get("context", {}),
                "analysis_started_at": datetime.now().isoformat()
            }
        }
    
    async def decide_node(self, state: AgentGraphState) -> Dict[str, Any]:
        """
        Noeud de decision.
        """
        logger.info(f"🧠 Decision (iteration {state.get('iterations', 0)})")
        
        try:
            prompt = self._build_decision_prompt(state)
            
            # Appel au service IA
            response = await self.ia_client.ask(
                question=prompt,
                level=state.get('level', '3eme'),
                subject=state.get('subject', 'general')
            )
            
            decision_text = response.get('response', '')
            
            # Parser la decision JSON
            try:
                import re
                json_match = re.search(r'\{.*\}', decision_text, re.DOTALL)
                if json_match:
                    decision_data = json.loads(json_match.group())
                else:
                    decision_data = {
                        "action": "finish",
                        "final_answer": decision_text[:500],
                        "reason": "Decision extraite du texte"
                    }
            except:
                decision_data = {
                    "action": "finish",
                    "final_answer": decision_text[:500],
                    "reason": "Format de decision invalide"
                }
            
            action = decision_data.get('action', 'finish')
            
            # Mettre a jour l'historique
            step_history = state.get('step_history', [])
            step_history.append({
                "action": action,
                "query": decision_data.get('query'),
                "tool": decision_data.get('tool'),
                "timestamp": datetime.now().isoformat()
            })
            
            return {
                "current_action": action,
                "current_query": decision_data.get('query'),
                "current_tool": decision_data.get('tool'),
                "current_arguments": decision_data.get('arguments', {}),
                "final_answer": decision_data.get('final_answer'),
                "completion_reason": decision_data.get('reason'),
                "step_history": step_history,
                "status": "deciding"
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur decision: {str(e)}")
            return {
                "current_action": "finish",
                "final_answer": f"Erreur: {str(e)}",
                "completion_reason": "error",
                "status": "failed",
                "error": str(e)
            }
    
    async def rag_node(self, state: AgentGraphState) -> Dict[str, Any]:
        """
        Noeud RAG - recherche de documents.
        """
        query = state.get('current_query', state.get('objective', ''))
        logger.info(f"📚 RAG: {query[:50]}...")
        
        try:
            # Appel au service IA pour la recherche RAG
            # Pour l'instant, simulation
            results = [
                {
                    "content": f"Information sur '{query}': Ce concept est fondamental.",
                    "source": "base_connaissances",
                    "score": 0.95
                },
                {
                    "content": f"Exemple d'application de '{query}':",
                    "source": "exemples",
                    "score": 0.82
                }
            ]
            
            knowledge = state.get('accumulated_knowledge', [])
            for r in results:
                knowledge.append(f"Recherche: {r['content'][:100]}...")
            
            return {
                "rag_results": results,
                "accumulated_knowledge": knowledge,
                "status": "observing"
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur RAG: {str(e)}")
            return {
                "rag_results": [],
                "status": "observing",
                "error": str(e)
            }
    
    async def tool_node(self, state: AgentGraphState) -> Dict[str, Any]:
        """
        Noeud d'execution d'outil.
        """
        tool_name = state.get('current_tool')
        arguments = state.get('current_arguments', {})
        
        logger.info(f"🔧 Outil: {tool_name}")
        
        if not tool_name:
            return {
                "status": "observing",
                "error": "Aucun outil specifie"
            }
        
        tool = tool_registry.get_tool(tool_name)
        if not tool:
            return {
                "status": "observing",
                "error": f"Outil inconnu: {tool_name}"
            }
        
        try:
            result = await tool.run(**arguments)
            
            knowledge = state.get('accumulated_knowledge', [])
            if result.success:
                knowledge.append(f"Outil '{tool_name}': {str(result.result)[:200]}")
            else:
                knowledge.append(f"Erreur outil '{tool_name}': {result.error}")
            
            return {
                "tool_results": [{
                    "tool": tool_name,
                    "success": result.success,
                    "result": result.result,
                    "error": result.error
                }],
                "accumulated_knowledge": knowledge,
                "status": "observing"
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur outil: {str(e)}")
            return {
                "tool_results": [{
                    "tool": tool_name,
                    "success": False,
                    "error": str(e)
                }],
                "status": "observing",
                "error": str(e)
            }
    
    async def observe_node(self, state: AgentGraphState) -> Dict[str, Any]:
        """
        Noeud d'observation.
        """
        logger.info("👁️ Observation")
        
        rag_count = len(state.get('rag_results', []))
        tool_count = len(state.get('tool_results', []))
        knowledge_count = len(state.get('accumulated_knowledge', []))
        
        return {
            "status": "evaluating",
            "context": {
                **state.get('context', {}),
                "rag_count": rag_count,
                "tool_count": tool_count,
                "knowledge_count": knowledge_count,
                "observed_at": datetime.now().isoformat()
            }
        }
    
    async def evaluate_node(self, state: AgentGraphState) -> Dict[str, Any]:
        """
        Noeud d'evaluation.
        """
        logger.info("📊 Evaluation")
        
        iterations = state.get('iterations', 0)
        max_iterations = state.get('max_iterations', 20)
        knowledge = state.get('accumulated_knowledge', [])
        
        # Si on a une reponse finale
        if state.get('final_answer'):
            return {
                "should_continue": "finish",
                "status": "completed",
                "is_complete": True,
                "final_answer": state.get('final_answer')
            }
        
        # Si on a assez de connaissances
        if len(knowledge) >= 3:
            return {
                "should_continue": "finish",
                "status": "completed",
                "is_complete": True,
                "final_answer": self._generate_final_answer(state)
            }
        
        # Si on a depasse le nombre max d'iterations
        if iterations >= max_iterations:
            return {
                "should_continue": "finish",
                "status": "failed",
                "is_complete": False,
                "final_answer": "Limite d'iterations atteinte.",
                "completion_reason": "max_iterations_exceeded"
            }
        
        # Continuer
        return {
            "should_continue": "continue",
            "status": "analyzing"
        }
    
    def _generate_final_answer(self, state: AgentGraphState) -> str:
        """Genere une reponse finale."""
        knowledge = state.get('accumulated_knowledge', [])
        
        if not knowledge:
            return "Je n'ai pas trouve suffisamment d'informations."
        
        answer = "Voici ce que j'ai pu trouver :\n\n"
        for item in knowledge[:5]:
            answer += f"- {item}\n"
        answer += "\nN'hesitez pas si vous avez besoin de plus de details."
        
        return answer