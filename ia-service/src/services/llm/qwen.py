# ============================================================
# FICHIER: ia-service/src/services/llm/qwen.py
# DESCRIPTION: Client Qwen avec mémoire de conversation et gestion video
# ============================================================

import os
import torch
import json
import re
from transformers import AutoTokenizer, AutoModelForCausalLM
from typing import Optional, List, Dict, Any, Tuple
from datetime import datetime
import logging
import traceback

logger = logging.getLogger(__name__)


class QwenLLM:
    """
    Client Qwen avec mémoire de conversation et détection d'intention vidéo.
    """
    
    def __init__(
        self,
        model_name: str = "Qwen/Qwen2.5-0.5B-Instruct",
        device: Optional[str] = None,
        max_length: int = 2048,
        max_history: int = 10,
        temperature: float = 0.3,
        top_p: float = 0.9,
    ):
        self.model_name = model_name
        self.max_length = max_length
        self.max_history = max_history
        self.temperature = temperature
        self.top_p = top_p
        self._model_loaded = False
        
        self.conversation_history: List[Dict[str, str]] = []
        self.user_level: str = "collège"
        self.user_interests: List[str] = []
        
        if device is None:
            self.device = "cuda" if torch.cuda.is_available() else "cpu"
        else:
            self.device = device
        
        try:
            logger.info(f"Chargement du modèle {model_name} sur {self.device}...")
            
            # ✅ CORRECTION 1: Utiliser 'dtype' au lieu de 'torch_dtype'
            self.tokenizer = AutoTokenizer.from_pretrained(
                model_name,
                trust_remote_code=True,
                padding_side="left",
            )
            
            if self.tokenizer.pad_token is None:
                self.tokenizer.pad_token = self.tokenizer.eos_token
            
            self.model = AutoModelForCausalLM.from_pretrained(
                model_name,
                dtype=torch.float16 if self.device == "cuda" else torch.float32,  # ✅ dtype au lieu de torch_dtype
                device_map="auto" if self.device == "cuda" else None,
                trust_remote_code=True,
                low_cpu_mem_usage=True,
            )
            
            if self.device == "cpu":
                self.model = self.model.to(self.device)
            
            self.model.eval()
            self._model_loaded = True
            logger.info(f"✅ Modèle chargé avec succès sur {self.device} !")
            
        except Exception as e:
            logger.error(f"❌ Erreur chargement du modèle: {str(e)}")
            logger.error(traceback.format_exc())
            self._model_loaded = False
            self.tokenizer = None
            self.model = None
    
    # ============================================================
    # GESTION DE LA CONVERSATION
    # ============================================================
    
    def add_to_history(self, role: str, content: str):
        """Ajoute un message à l'historique."""
        self.conversation_history.append({
            "role": role,
            "content": content,
            "timestamp": datetime.now().isoformat()
        })
        
        if len(self.conversation_history) > self.max_history * 2:
            self.conversation_history = self.conversation_history[-self.max_history * 2:]
    
    def get_conversation_context(self) -> str:
        """Génère le contexte de la conversation pour le prompt."""
        if not self.conversation_history:
            return ""
        
        context = "Historique de la conversation:\n"
        for msg in self.conversation_history[-self.max_history * 2:]:
            role = "Élève" if msg["role"] == "user" else "Professeur"
            context += f"{role}: {msg['content']}\n"
        
        return context
    
    def clear_history(self):
        """Efface l'historique de la conversation."""
        self.conversation_history = []
        logger.info("Historique effacé")
    
    def set_user_level(self, level: str):
        """Définit le niveau de l'élève."""
        self.user_level = level
        logger.info(f"Niveau défini: {level}")
    
    # ============================================================
    # DÉTECTION D'INTENTION VIDÉO
    # ============================================================
    
    def detect_video_intent(self, text: str) -> Dict[str, Any]:
        """Détecte si l'utilisateur demande une vidéo."""
        text_lower = text.lower()
        
        strong_keywords = [
            "vidéo", "video", "animation", "anime",
            "génère", "genere", "montre-moi", "visualise",
            "illustre", "dessine", "simulation"
        ]
        
        weak_keywords = [
            "voir", "montre", "explique", "apprendre",
            "comprendre", "schéma", "graphique"
        ]
        
        for keyword in strong_keywords:
            if keyword in text_lower:
                concept = self._extract_concept(text)
                return {
                    "wants_video": True,
                    "concept": concept,
                    "confidence": 0.9,
                    "method": "strong_keyword"
                }
        
        weak_count = sum(1 for kw in weak_keywords if kw in text_lower)
        if weak_count >= 2:
            concept = self._extract_concept(text)
            return {
                "wants_video": True,
                "concept": concept,
                "confidence": 0.6,
                "method": "weak_keyword"
            }
        
        patterns = [
            r"gen[eè]re(?:s)?\s+une\s+vid[ée]o",
            r"vid[ée]o\s+(?:sur|pour|de)",
            r"animation\s+(?:sur|pour)",
            r"j['']?aimerais\s+(?:voir|avoir)\s+une\s+vid[ée]o"
        ]
        
        for pattern in patterns:
            if re.search(pattern, text_lower):
                concept = self._extract_concept(text)
                return {
                    "wants_video": True,
                    "concept": concept,
                    "confidence": 0.8,
                    "method": "pattern"
                }
        
        return {
            "wants_video": False,
            "concept": None,
            "confidence": 0.0,
            "method": "none"
        }
    
    def _extract_concept(self, text: str) -> Optional[str]:
        """Extrait le concept principal du message."""
        patterns = [
            r"(?:sur|pour|de|:)\s*['\"]?([a-zA-Zéèàêâôîïûüç-]{3,}(?:\s+[a-zA-Zéèàêâôîïûüç-]{3,}){0,4})",
            r"(?:theoreme|th[ée]or[èe]me|loi|principe)\s+de\s+['\"]?([a-zA-Zéèàêâôîïûüç-]{3,})",
            r"(?:fonction|equation|identite)\s+['\"]?([a-zA-Zéèàêâôîïûüç-]{3,})"
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                concept = match.group(1).strip()
                if len(concept) > 3:
                    return concept
        
        words = text.split()
        if len(words) >= 3:
            concept = " ".join(words[:3])
            if len(concept) > 3:
                return concept
        
        return None
    
    # ============================================================
    # GÉNÉRATION PRINCIPALE
    # ============================================================
    
    def generate(
        self,
        prompt: str,
        max_new_tokens: int = 512,
        temperature: Optional[float] = None,
        top_p: Optional[float] = None,
        system_message: Optional[str] = None,
    ) -> str:
        """
        Génère une réponse avec le contexte de la conversation.
        
        Returns:
            str: Réponse générée
        """
        # ✅ Si le modèle n'est pas chargé, fallback
        if not self._model_loaded:
            logger.warning("⚠️ Modèle non chargé, utilisation du fallback")
            return self._get_fallback_response(prompt)
        
        if temperature is None:
            temperature = self.temperature
        
        if top_p is None:
            top_p = self.top_p
        
        try:
            context = self.get_conversation_context()
            
            default_system = f"""Tu es un professeur particulier pour des élèves comoriens.
Niveau actuel de l'élève: {self.user_level}

RÈGLES:
1. Réponds en français, de manière claire et pédagogique
2. Adapte ton langage au niveau de l'élève ({self.user_level})
3. Sois encourageant et patient
4. Utilise des exemples concrets
5. Si l'élève demande une vidéo, propose de générer une animation

CONTEXTE:
{context}
"""
            
            system = system_message or default_system
            
            # Ajouter le prompt à l'historique
            self.add_to_history("user", prompt)
            
            # ✅ CONSTRUIRE LES MESSAGES
            messages = [
                {"role": "system", "content": system},
                {"role": "user", "content": prompt}
            ]
            
            for msg in self.conversation_history[-6:]:
                if msg["role"] == "user":
                    messages.append({"role": "user", "content": msg["content"]})
                else:
                    messages.append({"role": "assistant", "content": msg["content"]})
            
            # ✅ ESSAYER LE TEMPLATE QWEN
            try:
                formatted_prompt = self.tokenizer.apply_chat_template(
                    messages,
                    tokenize=False,
                    add_generation_prompt=True,
                )
            except Exception as e:
                logger.warning(f"⚠️ apply_chat_template a échoué: {str(e)}")
                # ✅ FALLBACK: format manuel
                formatted_prompt = ""
                for msg in messages:
                    if msg["role"] == "system":
                        formatted_prompt += f"<|im_start|>system\n{msg['content']}<|im_end|>\n"
                    elif msg["role"] == "user":
                        formatted_prompt += f"<|im_start|>user\n{msg['content']}<|im_end|>\n"
                    elif msg["role"] == "assistant":
                        formatted_prompt += f"<|im_start|>assistant\n{msg['content']}<|im_end|>\n"
                formatted_prompt += "<|im_start|>assistant\n"
            
            logger.debug(f"📝 Prompt: {formatted_prompt[:200]}...")
            
            # ✅ TOKENIZER
            inputs = self.tokenizer(
                formatted_prompt,
                return_tensors="pt",
                truncation=True,
                max_length=self.max_length,
            ).to(self.device)
            
            # ✅ GENERER
            with torch.no_grad():
                outputs = self.model.generate(
                    **inputs,
                    max_new_tokens=max_new_tokens,
                    temperature=temperature,
                    top_p=top_p,
                    do_sample=True,
                    pad_token_id=self.tokenizer.eos_token_id,
                    repetition_penalty=1.1,
                )
            
            # ✅ DECODER
            response = self.tokenizer.decode(
                outputs[0][inputs.input_ids.shape[1]:],
                skip_special_tokens=True,
            )
            
            response = response.strip()
            
            # ✅ Si réponse vide, fallback
            if not response:
                logger.warning("⚠️ Réponse vide du modèle")
                return self._get_fallback_response(prompt)
            
            # Ajouter la réponse à l'historique
            self.add_to_history("assistant", response)
            
            logger.info(f"✅ Réponse générée: {response[:50]}...")
            return response
            
        except Exception as e:
            logger.error(f"❌ Erreur generation: {str(e)}")
            logger.error(traceback.format_exc())
            return self._get_fallback_response(prompt)
    
    def _get_fallback_response(self, prompt: str) -> str:
        """
        Génère une réponse de fallback quand le modèle n'est pas disponible.
        """
        import random
        
        fallbacks = [
            f"Je comprends votre question. Pour vous répondre correctement, je dois vous expliquer les concepts étape par étape. Pouvez-vous me préciser ce que vous ne comprenez pas exactement ?",
            
            f"C'est une excellente question ! Pour bien comprendre, il faut d'abord maîtriser les bases. Par quoi voulez-vous commencer ?",
            
            f"Je vois que vous voulez en savoir plus sur ce sujet. Pour vous aider au mieux, pouvez-vous me dire ce que vous savez déjà ?",
            
            f"Très intéressant ! Pour répondre à votre question, je vous propose de décomposer le problème en petites étapes. Commençons par le début."
        ]
        
        return random.choice(fallbacks)
    
    # ============================================================
    # CHAT AVEC DÉTECTION VIDÉO
    # ============================================================
    
    def chat(self, user_message: str, system_message: Optional[str] = None, **kwargs) -> Dict[str, Any]:
        """
        Chat intelligent avec détection d'intention vidéo.
        
        Returns:
            Dict: {
                "response": str,
                "wants_video": bool,
                "concept": Optional[str],
                "confidence": float
            }
        """
        intent = self.detect_video_intent(user_message)
        
        response = self.generate(
            prompt=user_message,
            system_message=system_message,
            **kwargs
        )
        
        if intent["wants_video"] and intent["confidence"] >= 0.6:
            concept = intent["concept"] or "le concept"
            video_prompt = self._generate_video_prompt(user_message, concept)
            
            return {
                "response": response,
                "wants_video": True,
                "concept": concept,
                "confidence": intent["confidence"],
                "video_prompt": video_prompt,
                "needs_video_generation": True
            }
        
        return {
            "response": response,
            "wants_video": False,
            "concept": None,
            "confidence": 0.0,
            "needs_video_generation": False
        }
    
    def _generate_video_prompt(self, user_message: str, concept: str) -> str:
        """Génère un prompt pour la création de la vidéo."""
        return f"""
Explique le concept de "{concept}" avec une animation pédagogique.

CONTEXTE:
- Niveau: {self.user_level}
- Concept: {concept}
- Question originale: {user_message}

INSTRUCTIONS:
1. Crée une animation claire et progressive
2. Adapte la complexité au niveau {self.user_level}
3. Inclus des explications textuelles
4. La vidéo doit durer environ 2-3 minutes
"""
    
    # ============================================================
    # UTILITAIRES
    # ============================================================
    
    def get_history(self) -> List[Dict[str, str]]:
        """Retourne l'historique de la conversation."""
        return self.conversation_history.copy()
    
    def get_summary(self) -> str:
        """Retourne un résumé de la conversation."""
        if not self.conversation_history:
            return "Aucune conversation en cours."
        
        summary = f"Conversation - Niveau: {self.user_level}\n"
        summary += f"Nombre de messages: {len(self.conversation_history)}\n"
        
        concepts = []
        for msg in self.conversation_history:
            if msg["role"] == "user":
                concept = self._extract_concept(msg["content"])
                if concept:
                    concepts.append(concept)
        
        if concepts:
            summary += f"Concepts abordés: {', '.join(set(concepts))}"
        
        return summary
    
    def reset(self):
        """Réinitialise complètement la session."""
        self.clear_history()
        self.user_level = "collège"
        self.user_interests = []
        logger.info("Session réinitialisée")