# ============================================================
# FICHIER: backend/app/utils/validation.py
# DESCRIPTION: Validation de code et de donnees
# ============================================================

import ast
import re
from typing import List, Tuple, Optional


class CodeValidator:
    """
    Validateur de code Python.
    """
    
    # Modules autorises
    ALLOWED_IMPORTS = {
        "manim", "numpy", "math", "random",
        "colors", "config", "utils", "constants"
    }
    
    # Modules interdits
    FORBIDDEN_IMPORTS = {
        "os", "sys", "subprocess", "socket",
        "requests", "urllib", "httpx",
        "importlib", "inspect", "exec", "eval",
        "compile", "open", "file", "__import__",
        "pickle", "marshal", "cryptography"
    }
    
    # Fonctions interdites
    FORBIDDEN_FUNCTIONS = {
        "exec", "eval", "compile", "__import__",
        "open", "file", "input", "raw_input"
    }
    
    @classmethod
    def validate_manim_code(cls, code: str) -> Tuple[bool, Optional[str]]:
        """
        Valide le code Manim pour la securite.
        
        Args:
            code: Code a valider
            
        Returns:
            Tuple[bool, Optional[str]]: (valide, message_erreur)
        """
        try:
            # Parser le code
            tree = ast.parse(code)
        except SyntaxError as e:
            return False, f"Erreur de syntaxe: {str(e)}"
        
        # Verifier les imports
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    name = alias.name.split('.')[0]
                    if name in cls.FORBIDDEN_IMPORTS:
                        return False, f"Import interdit: {name}"
            
            elif isinstance(node, ast.ImportFrom):
                module = node.module
                if module:
                    base_module = module.split('.')[0]
                    if base_module in cls.FORBIDDEN_IMPORTS:
                        return False, f"Import interdit: {module}"
            
            # Verifier les appels de fonctions dangereuses
            elif isinstance(node, ast.Call):
                if isinstance(node.func, ast.Name):
                    if node.func.id in cls.FORBIDDEN_FUNCTIONS:
                        return False, f"Fonction interdite: {node.func.id}"
                elif isinstance(node.func, ast.Attribute):
                    if node.func.attr in cls.FORBIDDEN_FUNCTIONS:
                        return False, f"Fonction interdite: {node.func.attr}"
        
        return True, None
    
    @classmethod
    def extract_scene_name(cls, code: str) -> Optional[str]:
        """
        Extrait le nom de la scene Manim.
        
        Args:
            code: Code Manim
            
        Returns:
            Optional[str]: Nom de la scene ou None
        """
        pattern = r'class\s+(\w+)\s*\(\s*(?:Scene|ThreeDScene)\s*\)'
        match = re.search(pattern, code)
        return match.group(1) if match else None
    
    @classmethod
    def has_main_scene(cls, code: str) -> bool:
        """
        Verifie si le code contient une scene Manim.
        
        Args:
            code: Code Manim
            
        Returns:
            bool: True si une scene est presente
        """
        pattern = r'class\s+\w+\s*\(\s*(?:Scene|ThreeDScene)\s*\)'
        return bool(re.search(pattern, code))


class PromptValidator:
    """
    Validateur de prompts utilisateur.
    """
    
    MAX_PROMPT_LENGTH = 1000
    MIN_PROMPT_LENGTH = 3
    
    @classmethod
    def validate_prompt(cls, prompt: str) -> Tuple[bool, Optional[str]]:
        """
        Valide un prompt utilisateur.
        
        Args:
            prompt: Prompt a valider
            
        Returns:
            Tuple[bool, Optional[str]]: (valide, message_erreur)
        """
        if not prompt or len(prompt.strip()) < cls.MIN_PROMPT_LENGTH:
            return False, f"Le prompt doit contenir au moins {cls.MIN_PROMPT_LENGTH} caracteres"
        
        if len(prompt) > cls.MAX_PROMPT_LENGTH:
            return False, f"Le prompt ne peut pas depasser {cls.MAX_PROMPT_LENGTH} caracteres"
        
        # Verifier les caracteres interdits
        forbidden = ["<script", "javascript:", "onclick", "onerror"]
        for term in forbidden:
            if term.lower() in prompt.lower():
                return False, "Caracteres interdits dans le prompt"
        
        return True, None


class VideoRequestValidator:
    """
    Validateur de requetes video.
    """
    
    @classmethod
    def validate_duration(cls, duration: int) -> Tuple[bool, Optional[str]]:
        """
        Valide la duree demandee.
        
        Args:
            duration: Duree en secondes
            
        Returns:
            Tuple[bool, Optional[str]]: (valide, message_erreur)
        """
        if duration < 30:
            return False, "La duree minimale est de 30 secondes"
        if duration > 600:
            return False, "La duree maximale est de 600 secondes (10 minutes)"
        return True, None
    
    @classmethod
    def validate_language(cls, language: str) -> Tuple[bool, Optional[str]]:
        """
        Valide la langue.
        
        Args:
            language: Code langue
            
        Returns:
            Tuple[bool, Optional[str]]: (valide, message_erreur)
        """
        supported = ["fr", "en", "es", "de", "it", "pt"]
        if language not in supported:
            return False, f"Langue non supportee. Langues supportees: {', '.join(supported)}"
        return True, None