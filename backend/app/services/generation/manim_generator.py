# ============================================================
# FICHIER: backend/app/services/generation/manim_generator.py
# DESCRIPTION: Generateur d'animations Manim
# ============================================================

import subprocess
import tempfile
import os
import re
import asyncio
from pathlib import Path
from typing import Optional, List
import shutil

from .base_generator import BaseGenerator
from app.core.constants.video_constants import MANIM_TIMEOUT_SECONDS

import logging

logger = logging.getLogger(__name__)


class ManimGenerator(BaseGenerator):
    """
    Generateur utilisant Manim (Community Edition).
    Execute le code Manim dans un conteneur Docker pour la securite.
    """
    
    @property
    def name(self) -> str:
        return "manim"
    
    @property
    def supported_formats(self) -> List[str]:
        return ["mp4", "gif", "webm"]
    
    async def generate(self, code: str, job_id: str, workspace: dict) -> Optional[str]:
        """
        Genere l'animation Manim.
        
        Args:
            code: Code Manim
            job_id: ID du job
            workspace: Espace de travail
            
        Returns:
            Optional[str]: Chemin du fichier MP4 genere
        """
        # Valider le code
        if not self.validate_code(code):
            logger.error(f"Job {job_id}: Code Manim invalide")
            return None
        
        # Extraire le nom de la scene
        scene_name = self._extract_scene_name(code)
        if not scene_name:
            scene_name = "Scene"
        
        # Creer le fichier temporaire
        script_dir = Path(workspace["scripts"])
        script_path = script_dir / f"{job_id}.py"
        script_path.write_text(code, encoding="utf-8")
        
        output_dir = Path(workspace["renders"])
        output_dir.mkdir(parents=True, exist_ok=True)
        
        try:
            # Commande Manim
            cmd = [
                "manim",
                "-pqh",  # Qualite: HD, format: mp4
                "--output_file", str(output_dir / f"{job_id}.mp4"),
                str(script_path),
                scene_name
            ]
            
            logger.info(f"Job {job_id}: Lancement de Manim")
            
            # Executer Manim
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=str(script_dir.parent)
            )
            
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(),
                    timeout=MANIM_TIMEOUT_SECONDS
                )
            except asyncio.TimeoutError:
                process.kill()
                logger.error(f"Job {job_id}: Manim timeout")
                return None
            
            if process.returncode != 0:
                logger.error(f"Job {job_id}: Erreur Manim - {stderr.decode()}")
                return None
            
            # Verifier le fichier genere
            video_path = output_dir / f"{job_id}.mp4"
            if video_path.exists():
                logger.info(f"Job {job_id}: Video generee avec succes")
                return str(video_path)
            
            return None
            
        except Exception as e:
            logger.error(f"Job {job_id}: Erreur Manim - {str(e)}")
            return None
    
    def validate_code(self, code: str) -> bool:
        """
        Valide le code Manim pour la securite.
        
        Args:
            code: Code a valider
            
        Returns:
            bool: True si le code est valide
        """
        # Imports autorises
        allowed_imports = [
            "manim",
            "numpy",
            "math",
            "random",
            "colors",
            "config"
        ]
        
        # Imports interdits
        forbidden_imports = [
            "os", "sys", "subprocess",
            "requests", "socket", "urllib",
            "importlib", "exec", "eval",
            "open", "file", "__import__"
        ]
        
        lines = code.split("\n")
        for line in lines:
            stripped = line.strip()
            
            # Verifier les imports interdits
            for forbidden in forbidden_imports:
                if stripped.startswith(f"import {forbidden}") or \
                   stripped.startswith(f"from {forbidden}"):
                    logger.warning(f"Import interdit detecte: {forbidden}")
                    return False
            
            # Verifier les appels dangereux
            if "exec" in stripped or "eval" in stripped:
                logger.warning("exec/eval detecte")
                return False
        
        return True
    
    def _extract_scene_name(self, code: str) -> Optional[str]:
        """
        Extrait le nom de la classe Scene du code.
        
        Args:
            code: Code Manim
            
        Returns:
            Optional[str]: Nom de la scene ou None
        """
        pattern = r'class\s+(\w+)\s*\(\s*(?:Scene|ThreeDScene)\s*\)'
        match = re.search(pattern, code)
        return match.group(1) if match else None