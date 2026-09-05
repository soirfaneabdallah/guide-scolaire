# ============================================================
# FICHIER: backend/app/services/renderers/local_renderer.py
# DESCRIPTION: Renderer local (sans Docker) pour le developpement
# ============================================================

import subprocess
import asyncio
import os
from pathlib import Path
from typing import Optional, List

from .base_renderer import BaseRenderer
from app.core.constants.video_constants import MANIM_TIMEOUT_SECONDS

import logging

logger = logging.getLogger(__name__)


class LocalRenderer(BaseRenderer):
    """
    Renderer local utilisant l'installation Manim du systeme.
    Plus rapide pour le developpement mais moins securise.
    """
    
    @property
    def name(self) -> str:
        return "local"
    
    async def render(
        self,
        code: str,
        job_id: str,
        workspace: dict,
        **kwargs
    ) -> Optional[str]:
        """
        Execute le rendu Manim en local.
        """
        try:
            # Valider l'environnement
            if not await self.validate_environment():
                logger.error("Manim non installe")
                return None
            
            # Preparer les chemins
            script_path = Path(workspace["scripts"]) / f"{job_id}.py"
            output_dir = Path(workspace["renders"])
            output_dir.mkdir(parents=True, exist_ok=True)
            
            # Extraire le nom de la scene
            scene_name = self._extract_scene_name(code) or "Scene"
            
            # Commande Manim
            cmd = [
                "manim",
                "-pqh",
                "-o", str(output_dir / f"{job_id}.mp4"),
                str(script_path),
                scene_name
            ]
            
            logger.info(f"Job {job_id}: Lancement du rendu local")
            
            # Executer Manim
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=str(workspace["root"])
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
                logger.error(f"Job {job_id}: Manim error - {stderr.decode()}")
                return None
            
            # Verifier le fichier genere
            video_path = output_dir / f"{job_id}.mp4"
            if video_path.exists():
                logger.info(f"Job {job_id}: Video locale generee avec succes")
                return str(video_path)
            
            return None
            
        except Exception as e:
            logger.error(f"Job {job_id}: Erreur rendu local - {str(e)}")
            return None
    
    async def validate_environment(self) -> bool:
        """
        Verifie que Manim est installe.
        """
        try:
            process = await asyncio.create_subprocess_exec(
                "manim", "--version",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            stdout, stderr = await process.communicate()
            return process.returncode == 0
        except Exception:
            return False
    
    def get_requirements(self) -> List[str]:
        """
        Retourne les dependances requises.
        """
        return ["manim"]
    
    def _extract_scene_name(self, code: str) -> Optional[str]:
        """
        Extrait le nom de la scene du code.
        """
        import re
        pattern = r'class\s+(\w+)\s*\(\s*(?:Scene|ThreeDScene)\s*\)'
        match = re.search(pattern, code)
        return match.group(1) if match else None