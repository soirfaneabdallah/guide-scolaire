# ============================================================
# FICHIER: backend/app/services/renderers/docker_renderer.py
# DESCRIPTION: Renderer utilisant Docker pour l'isolation
# ============================================================

import subprocess
import asyncio
import json
from pathlib import Path
from typing import Optional, List, Dict, Any

from .base_renderer import BaseRenderer
from app.core.constants.video_constants import MANIM_TIMEOUT_SECONDS

import logging

logger = logging.getLogger(__name__)


class DockerRenderer(BaseRenderer):
    """
    Renderer utilisant Docker pour executer Manim en isolation.
    Securite et portabilite maximales.
    """
    
    DEFAULT_IMAGE = "manimcommunity/manim:stable"
    CONTAINER_TIMEOUT = MANIM_TIMEOUT_SECONDS
    
    def __init__(
        self,
        image: str = DEFAULT_IMAGE,
        memory_limit: str = "2g",
        cpu_limit: str = "2"
    ):
        self.image = image
        self.memory_limit = memory_limit
        self.cpu_limit = cpu_limit
    
    @property
    def name(self) -> str:
        return "docker"
    
    async def render(
        self,
        code: str,
        job_id: str,
        workspace: dict,
        **kwargs
    ) -> Optional[str]:
        """
        Execute le rendu Manim dans un conteneur Docker.
        """
        try:
            # Valider l'environnement
            if not await self.validate_environment():
                logger.error("Docker non disponible")
                return None
            
            # Preparer les chemins
            script_path = Path(workspace["scripts"]) / f"{job_id}.py"
            output_dir = Path(workspace["renders"])
            output_dir.mkdir(parents=True, exist_ok=True)
            
            # Extraire le nom de la scene
            scene_name = self._extract_scene_name(code) or "Scene"
            
            # Commande Docker
            cmd = [
                "docker", "run",
                "--rm",
                "--memory", self.memory_limit,
                "--cpus", self.cpu_limit,
                "--network", "none",  # Pas d'acces reseau
                "-v", f"{str(script_path.parent)}:/app/scripts:ro",
                "-v", f"{str(output_dir)}:/app/output",
                self.image,
                "manim", "-pqh",
                str(script_path),
                scene_name,
                "-o", f"/app/output/{job_id}.mp4"
            ]
            
            logger.info(f"Job {job_id}: Lancement du rendu Docker")
            
            # Executer Docker
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(),
                    timeout=self.CONTAINER_TIMEOUT
                )
            except asyncio.TimeoutError:
                process.kill()
                logger.error(f"Job {job_id}: Docker timeout")
                return None
            
            if process.returncode != 0:
                logger.error(f"Job {job_id}: Docker error - {stderr.decode()}")
                return None
            
            # Verifier le fichier genere
            video_path = output_dir / f"{job_id}.mp4"
            if video_path.exists():
                logger.info(f"Job {job_id}: Video Docker generee avec succes")
                return str(video_path)
            
            return None
            
        except Exception as e:
            logger.error(f"Job {job_id}: Erreur Docker - {str(e)}")
            return None
    
    async def validate_environment(self) -> bool:
        """
        Verifie que Docker est installe et accessible.
        """
        try:
            process = await asyncio.create_subprocess_exec(
                "docker", "--version",
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
        return ["docker"]
    
    def _extract_scene_name(self, code: str) -> Optional[str]:
        """
        Extrait le nom de la scene du code.
        """
        import re
        pattern = r'class\s+(\w+)\s*\(\s*(?:Scene|ThreeDScene)\s*\)'
        match = re.search(pattern, code)
        return match.group(1) if match else None