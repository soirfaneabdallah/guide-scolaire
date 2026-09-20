# ============================================================
# FICHIER: backend/app/api/v1/routes/chat.py
# DESCRIPTION: Routes de chat avec contexte et mémoire
# ============================================================

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional, List, Dict, Any
import httpx
import logging
import time
import traceback
import re

from ....core.database import get_db
from ....core.dependencies import get_current_active_user
from ....models.user import User
from ....models.subject import Subject
from ....services.ia_client import IAClient
from ....repositories.chat_repository import ChatRepository
from ....repositories.subject_repository import SubjectRepository
from ....api.v1.schemas.chat_schemas import (
    AskRequest,
    AskResponse,
    ChatHistoryResponse,
    ChatMessageResponse,
)
from ....agent.orchestrator.agent_orchestrator import agent_orchestrator

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/chat", tags=["Chat"])


# ============================================================
#  DÉTECTION AMÉLIORÉE DE L'AGENT
# ============================================================

def should_use_agent(question: str, level: str = "3ème") -> bool:
    """
    Détecte si la question nécessite l'utilisation de l'agent.
    Utilise plusieurs critères : mots-clés, longueur, niveau, patterns.
    """
    question_lower = question.lower()
    
    # ============================================================
    # CRITÈRE 1: Mots-clés forts (agent obligatoire)
    # ============================================================
    strong_keywords = [
        # Mathématiques avancées (avec et sans accents)
        "primitive", "intégrale", "integrale",
        "derivee", "deriver", "dérivée", "dériver",
        "equation differentielle", "équation différentielle",
        "limite", "suite",
        "fonction exponentielle", "logarithme", "trigonométrie",
        "vecteur", "matrice", "complexe", "nombre complexe",
        "exponentielle", "logarithme", "log", "ln",
        "sinus", "cosinus", "tangente",
        
        # Analyse et raisonnement
        "demontre", "démontre", "prouve", "demonstration", "démonstration",
        "raisonnement", "justifie", "explique pourquoi", "montre que",
        "etudie", "étudie", "analyse", "compare", "synthese", "synthèse",
        
        # Recherche d'informations
        "recherche", "trouve", "cherche", "document", "source",
        "theoreme", "théorème", "loi", "principe", "regle", "règle",
        
        # Mots-clés complexes
        "etape par etape", "étape par étape", "pas a pas", "pas à pas",
        "detaille", "détaillé", "approfondi", "complexe", "difficile",
        
        # Mots-clés mathématiques supplémentaires
        "integral", "integrales", "derive", "derivees", "derivee",
        "equation", "équation", "resolution", "résolution",
        "calculer", "calcule", "calcul",
    ]
    
    for keyword in strong_keywords:
        if keyword in question_lower:
            logger.info(f"🔍 Agent déclenché par mot-clé fort: '{keyword}'")
            return True
    
    # ============================================================
    # CRITÈRE 2: Patterns mathématiques (avec accents)
    # ============================================================
    math_patterns = [
        r'f\(x\)\s*=',           # f(x) =
        r'g\(x\)\s*=',           # g(x) =
        r'\bderiv[ée]e\b',       # dérivée (avec accent)
        r'\bderivee\b',          # derivee (sans accent)
        r'\bprimitive\b',        # primitive
        r'\bintegral[ée]\b',     # intégrale
        r'\bln\s*\(',            # ln(
        r'\be\^',                # e^
        r'\bexp\s*\(',           # exp(
        r'\bsin\s*\(',           # sin(
        r'\bcos\s*\(',           # cos(
        r'\btan\s*\(',           # tan(
        r'\blimite\b',           # limite
        r'\bint_',               # ∫
        r'\bsomme\b',            # somme
        r'\bproduit\b',          # produit
        r'\bracine\b',           # racine
        r'\bcar[ée]\b',          # carré/carre
        r'\bcube\b',             # cube
        r'\bpuissance\b',        # puissance
        r'\bexposant\b',         # exposant
        r'\blogarithme\b',       # logarithme
        r'\b[0-9]+\s*[=+*/^()]', # nombres avec symboles
        r'\bcalculer\b',         # calculer
        r'\brésoudre\b',         # résoudre
        r'\bresoudre\b',         # resoudre
    ]
    
    for pattern in math_patterns:
        if re.search(pattern, question_lower):
            logger.info(f"🔍 Agent déclenché par pattern mathématique: '{pattern}'")
            return True
    
    # ============================================================
    # CRITÈRE 3: Niveau avancé
    # ============================================================
    advanced_levels = ["terminale", "première", "premiere", "seconde", "licence", "master"]
    if any(lvl in level.lower() for lvl in advanced_levels):
        if len(question.split()) > 5:
            logger.info(f"🔍 Agent déclenché par niveau avancé: {level}")
            return True
    
    # ============================================================
    # CRITÈRE 4: Longueur de la question
    # ============================================================
    word_count = len(question.split())
    if word_count > 15:
        logger.info(f"🔍 Agent déclenché par longueur: {word_count} mots")
        return True
    
    # ============================================================
    # CRITÈRE 5: Mots-clés faibles (agent recommandé)
    # ============================================================
    weak_keywords = [
        "explique", "expliquer", "comment", "pourquoi", "quel est",
        "calcule", "calculer", "résous", "resous", "trouve", "determine", "détermine",
        "sais-tu", "peux-tu", "pourrais-tu",
        "j'aimerais", "je voudrais",
    ]
    
    weak_count = sum(1 for kw in weak_keywords if kw in question_lower)
    if weak_count >= 2 and len(question.split()) > 8:
        logger.info(f"🔍 Agent déclenché par mots-clés faibles: {weak_count}")
        return True
    
    # ============================================================
    # CRITÈRE 6: Questions avec des nombres ou formules
    # ============================================================
    has_numbers = bool(re.search(r'\d', question))
    has_math_symbols = bool(re.search(r'[=+*/^()]', question))
    
    if has_numbers and has_math_symbols and len(question.split()) > 5:
        logger.info(f"🔍 Agent déclenché par nombres et symboles mathématiques")
        return True
    
    # ============================================================
    # CRITÈRE 7: Mots de la question précédente
    # ============================================================
    follow_up_patterns = [
        r'primitive', r'intégrale', r'integrale', r'dérivée', r'derivee',
        r'donc', r'alors', r'ensuite',
        r'et si', r'mais', r'pourquoi',
    ]
    
    for pattern in follow_up_patterns:
        if pattern in question_lower:
            logger.info(f"🔍 Agent déclenché par question de suivi: '{pattern}'")
            return True
    
    # ============================================================
    # DÉFAUT: Ne pas utiliser l'agent
    # ============================================================
    logger.info("ℹ️ Question simple, utilisation du LLM standard")
    return True



def format_chat_history(messages: list, limit: int = 10) -> List[Dict[str, str]]:
    """
    Formate l'historique des messages pour le service IA.
    """
    history = []
    for msg in messages[-limit:]:
        role = "user" if msg.is_user else "assistant"
        history.append({
            "role": role,
            "content": msg.content
        })
    return history


# ============================================================
#  POSER UNE QUESTION
# ============================================================

@router.post("/ask", response_model=AskResponse)
async def ask_question(
    request: AskRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Endpoint pour poser une question à l'assistant IA.
    Utilise l'agent pour les questions complexes,
    le LLM simple pour les questions rapides.
    Le contexte de la conversation est conservé.
    """
    chat_repo = ChatRepository(db)
    subject_repo = SubjectRepository(db)

    try:
        # ✅ 1. Récupérer la matière
        subject = None
        
        if hasattr(request, 'subject_id') and request.subject_id:
            subject = subject_repo.get_subject_by_id(request.subject_id)
        
        if not subject and hasattr(request, 'subject_slug') and request.subject_slug:
            subject = subject_repo.get_subject_by_slug(request.subject_slug)
        
        if not subject:
            default_subjects = subject_repo.get_default_subjects()
            if default_subjects:
                subject = default_subjects[0]
            else:
                from ....models.subject import Subject
                subject = Subject(
                    name="Général",
                    slug="general",
                    is_default=True,
                    icon="📚",
                    color="#4F46E5"
                )
                db.add(subject)
                db.commit()
                db.refresh(subject)

        # ✅ 2. Récupérer l'historique récent (pour le contexte)
        recent_messages = chat_repo.get_messages_for_subject(
            user_id=current_user.id,
            subject_id=subject.id,
            limit=10
        )
        
        history_formatted = format_chat_history(recent_messages)
        
        logger.info(f"📚 Historique: {len(history_formatted)} messages")

        # ✅ 3. Sauvegarder la question de l'utilisateur
        chat_repo.save_message(
            user_id=current_user.id,
            subject_id=subject.id,
            content=request.question,
            is_user=True,
            level=request.level,
        )

        start_time = time.time()
        answer = ""
        model_used = "unknown"
        processing_time = 0

        # ✅ 4. Décider si on utilise l'agent ou le LLM simple
        use_agent = should_use_agent(request.question, request.level)
        
        logger.info(f"📌 Question: {request.question[:50]}...")
        logger.info(f"📚 Niveau: {request.level}")
        logger.info(f"🤖 Utiliser l'agent: {use_agent}")
        
        if use_agent:
            # ✅ UTILISER L'AGENT AVEC CONTEXTE
            logger.info("🧠 Lancement de l'agent avec contexte...")
            
            try:
                agent_result = await agent_orchestrator.execute(
                    objective=request.question,
                    user_id=current_user.id,
                    subject=subject.name if subject else None,
                    level=request.level,
                    context={
                        "chat_history": history_formatted,
                        "last_messages": recent_messages
                    },
                    max_iterations=10
                )
                
                answer = agent_result.get("answer", "L'agent n'a pas pu générer une réponse.")
                model_used = f"agent_{agent_result.get('status', 'unknown')}"
                processing_time = (time.time() - start_time) * 1000
                
                logger.info(f"✅ Agent terminé: {agent_result.get('iterations', 0)} itérations")
                
                # ✅ Si l'agent a échoué, fallback sur le LLM
                if "Erreur" in answer or "pas pu" in answer:
                    logger.warning("⚠️ Agent a échoué, fallback sur le LLM")
                    use_agent = False
                
            except Exception as e:
                logger.error(f"❌ Erreur agent: {str(e)}")
                logger.info("🔄 Fallback sur le LLM simple...")
                use_agent = False
        
        if not use_agent:
            # ✅ UTILISER LE LLM SIMPLE AVEC CONTEXTE
            try:
                ia_client = IAClient()
                
                result = await ia_client.ask(
                    question=request.question,
                    level=request.level,
                    subject=subject.name if subject else None,
                    history=history_formatted,  # ✅ CONTEXTE TRANSMIS
                    session_id=f"user_{current_user.id}_subject_{subject.id}",
                    turn_number=len(recent_messages) + 1
                )
                
                processing_time = (time.time() - start_time) * 1000
                answer = result.get("response") or result.get("answer") or "Je n'ai pas pu générer une réponse."
                model_used = result.get("model_used") or result.get("model") or "qwen"
                
                logger.info(f"✅ LLM simple avec contexte: {len(history_formatted)} messages d'historique")
                
            except httpx.TimeoutException:
                logger.error("⏰ Timeout du service IA")
                answer = "Le service IA met trop de temps à répondre. Veuillez réessayer."
                model_used = "timeout"
                processing_time = 0
                
            except httpx.ConnectError:
                logger.error("🔌 Connexion au service IA impossible")
                answer = "Le service IA n'est pas disponible. Veuillez réessayer plus tard."
                model_used = "unavailable"
                processing_time = 0
                
            except Exception as e:
                logger.error(f"❌ Erreur IA: {str(e)}")
                answer = "Je n'ai pas pu générer une réponse. Veuillez réessayer."
                model_used = "error"
                processing_time = 0

        # ✅ 5. Sauvegarder la réponse
        chat_repo.save_message(
            user_id=current_user.id,
            subject_id=subject.id,
            content=answer,
            is_user=False,
            level=request.level,
            model_used=model_used,
            processing_time=int(processing_time),
        )

        # ✅ 6. Retourner la réponse
        return AskResponse(
            answer=answer,
            level=request.level,
            model=model_used,
            processing_time=processing_time / 1000,
            subject_slug=subject.slug,
        )

    except Exception as e:
        logger.error(f"❌ ERREUR: {type(e).__name__}: {e}")
        logger.error(traceback.format_exc())
        
        try:
            chat_repo.save_message(
                user_id=current_user.id,
                subject_id=subject.id if subject else 1,
                content="Je n'ai pas pu générer une réponse.",
                is_user=False,
                level=request.level,
                model_used="error",
                is_error=True,
            )
        except:
            pass
        
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors du traitement de la question: {str(e)}"
        )


# ============================================================
#  RÉCUPÉRER L'HISTORIQUE
# ============================================================

@router.get("/history/{subject_id}", response_model=ChatHistoryResponse)
async def get_chat_history(
    subject_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
    limit: int = 100,
    offset: int = 0,
):
    """Récupère l'historique des messages pour une matière donnée."""
    chat_repo = ChatRepository(db)
    subject_repo = SubjectRepository(db)

    subject = subject_repo.get_subject_by_id(subject_id)
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Matière avec l'ID {subject_id} non trouvée"
        )

    messages = chat_repo.get_messages_for_subject(
        user_id=current_user.id,
        subject_id=subject.id,
        limit=limit,
        offset=offset,
    )

    return ChatHistoryResponse(
        subject_id=subject.id,
        subject_name=subject.name,
        subject_slug=subject.slug,
        messages=[
            ChatMessageResponse(
                id=m.id,
                content=m.content,
                is_user=m.is_user,
                is_error=getattr(m, 'is_error', False),
                level=m.level,
                model_used=m.model_used,
                created_at=m.created_at,
            )
            for m in messages
        ],
        total_messages=len(messages),
    )


# ============================================================
#  RÉCUPÉRER L'HISTORIQUE PAR SLUG
# ============================================================

@router.get("/history/slug/{subject_slug}", response_model=ChatHistoryResponse)
async def get_chat_history_by_slug(
    subject_slug: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
    limit: int = 100,
    offset: int = 0,
):
    """Récupère l'historique des messages pour une matière donnée (par slug)."""
    chat_repo = ChatRepository(db)
    subject_repo = SubjectRepository(db)

    subject = subject_repo.get_subject_by_slug(subject_slug)
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Matière avec le slug '{subject_slug}' non trouvée"
        )

    messages = chat_repo.get_messages_for_subject(
        user_id=current_user.id,
        subject_id=subject.id,
        limit=limit,
        offset=offset,
    )

    return ChatHistoryResponse(
        subject_id=subject.id,
        subject_name=subject.name,
        subject_slug=subject.slug,
        messages=[
            ChatMessageResponse(
                id=m.id,
                content=m.content,
                is_user=m.is_user,
                is_error=getattr(m, 'is_error', False),
                level=m.level,
                model_used=m.model_used,
                created_at=m.created_at,
            )
            for m in messages
        ],
        total_messages=len(messages),
    )


# ============================================================
#  SUPPRIMER L'HISTORIQUE
# ============================================================

@router.delete("/history/{subject_id}", status_code=status.HTTP_204_NO_CONTENT)
async def clear_chat_history(
    subject_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Supprime tout l'historique des messages pour une matière donnée."""
    chat_repo = ChatRepository(db)
    subject_repo = SubjectRepository(db)

    subject = subject_repo.get_subject_by_id(subject_id)
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Matière avec l'ID {subject_id} non trouvée"
        )

    deleted = chat_repo.clear_subject_history(current_user.id, subject.id)
    return None


# ============================================================
#  SUPPRIMER UN MESSAGE SPÉCIFIQUE
# ============================================================

@router.delete("/message/{message_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_message(
    message_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Supprime un message spécifique."""
    chat_repo = ChatRepository(db)
    
    message = chat_repo.get_message(message_id)
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Message avec l'ID {message_id} non trouvé"
        )
    
    if message.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous n'avez pas le droit de supprimer ce message"
        )
    
    chat_repo.delete_message(message_id)
    return None


# ============================================================
#  STATUS DU SERVICE IA
# ============================================================

@router.get("/ia/status")
async def get_ia_status():
    """Vérifie le statut du service IA."""
    try:
        ia_client = IAClient()
        status = await ia_client.get_status()
        return {
            "status": "ok",
            "ia_service": status
        }
    except Exception as e:
        return {
            "status": "error",
            "error": str(e)
        }


# ============================================================
#  HEALTH CHECK
# ============================================================

@router.get("/health")
async def health_check():
    """Vérifie la santé du service chat."""
    try:
        ia_client = IAClient()
        health = await ia_client.check_health()
        return {
            "status": "ok",
            "service": "chat",
            "ia_service": health
        }
    except Exception as e:
        return {
            "status": "error",
            "service": "chat",
            "error": str(e)
        }


# ============================================================
#  STATUT DE L'AGENT
# ============================================================

@router.get("/agent/status")
async def get_agent_status():
    """Vérifie le statut de l'agent."""
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


# ============================================================
#  DÉTECTER SI L'AGENT SERAIT UTILISÉ (TEST)
# ============================================================

@router.post("/detect-agent")
async def detect_agent_usage(request: AskRequest):
    """
    Endpoint de test pour vérifier si l'agent serait utilisé.
    """
    use_agent = should_use_agent(request.question, request.level)
    
    return {
        "question": request.question,
        "level": request.level,
        "would_use_agent": use_agent,
        "reason": "Agent would be used" if use_agent else "Simple question, using standard LLM"
    }