# ============================================================
# FICHIER: backend/app/services/video/intent_detector.py
# DESCRIPTION: Detection d'intention de video dans les messages
# ============================================================

import re
from typing import Dict, Any, Optional, List
from enum import Enum


class IntentConfidence(Enum):
    """Niveau de confiance de la detection"""
    HIGH = 0.9
    MEDIUM = 0.6
    LOW = 0.3
    NONE = 0.0


class IntentDetector:
    """
    Detecte si l'utilisateur demande explicitement une video.
    Utilise une combinaison de mots-cles et de patterns.
    """
    
    # Mots-cles forts (confiance elevee)
    STRONG_KEYWORDS = [
        "video", "animation", "anime", "genere", "generer",
        "montre-moi", "visualise", "illustre", "dessine",
        "simulation", "modelise"
    ]
    
    # Mots-cles faibles (confiance moyenne)
    WEAK_KEYWORDS = [
        "voir", "montre", "explique", "apprendre",
        "comprendre", "schema", "graphique"
    ]
    
    # Patterns regex
    PATTERNS = [
        r"gen[eè]re(?:s)?\s+une\s+vid[ée]o",
        r"vid[ée]o\s+(?:sur|pour|de)",
        r"animation\s+(?:sur|pour)",
        r"montre-moi\s+(?:avec\s+)?(?:une\s+)?(?:vid[ée]o|animation)",
        r"j'aimerais\s+(?:voir|avoir)\s+une\s+vid[ée]o",
        r"est-ce que\s+tu\s+peux\s+(?:m'|me\s+)?(?:faire|gen[eè]rer)\s+une\s+vid[ée]o"
    ]
    
    @classmethod
    def detect(cls, text: str) -> Dict[str, Any]:
        """
        Detecte si le message demande une video.
        
        Args:
            text: Message de l'utilisateur
            
        Returns:
            dict: {
                "wants_video": bool,
                "confidence": float,
                "concept": Optional[str],
                "method": str
            }
        """
        text_lower = text.lower()
        
        # 1. Detection par patterns (confiance elevee)
        for pattern in cls.PATTERNS:
            if re.search(pattern, text_lower, re.IGNORECASE):
                concept = cls._extract_concept(text)
                return {
                    "wants_video": True,
                    "confidence": IntentConfidence.HIGH.value,
                    "concept": concept,
                    "method": "pattern"
                }
        
        # 2. Detection par mots-cles forts
        for keyword in cls.STRONG_KEYWORDS:
            if keyword in text_lower:
                concept = cls._extract_concept(text)
                return {
                    "wants_video": True,
                    "confidence": IntentConfidence.HIGH.value,
                    "concept": concept,
                    "method": "strong_keyword"
                }
        
        # 3. Detection par mots-cles faibles
        weak_match_count = 0
        for keyword in cls.WEAK_KEYWORDS:
            if keyword in text_lower:
                weak_match_count += 1
        
        if weak_match_count >= 2:
            concept = cls._extract_concept(text)
            return {
                "wants_video": True,
                "confidence": IntentConfidence.MEDIUM.value,
                "concept": concept,
                "method": "weak_keyword"
            }
        
        # 4. Pas de detection
        return {
            "wants_video": False,
            "confidence": IntentConfidence.NONE.value,
            "concept": None,
            "method": "none"
        }
    
    @classmethod
    def _extract_concept(cls, text: str) -> Optional[str]:
        """
        Extrait le concept principal du message.
        
        Args:
            text: Message de l'utilisateur
            
        Returns:
            Optional[str]: Concept extrait ou None
        """
        # Patterns pour extraire le concept
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
        
        # Fallback: prendre les 3-5 premiers mots
        words = text.split()
        if len(words) >= 3:
            concept = " ".join(words[:3])
            if len(concept) > 3:
                return concept
        
        return None