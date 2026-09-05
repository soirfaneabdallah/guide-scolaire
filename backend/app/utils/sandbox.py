# ============================================================
# FICHIER: backend/app/utils/sandbox.py
# DESCRIPTION: Sandbox pour l'execution securisee de code
# ============================================================

import subprocess
import tempfile
import os
import shutil
from pathlib import Path
from typing import Optional, Tuple
import asyncio

from app.core.constants.video_constants import MANIM_TIMEOUT_SECONDS

import logging

logger = logging.getLogger(__name__)


class Sandbox:
    """
    Sandbox pour l'execution securisee de code Manim.
    Utilise Docker pour l'isolation.
    """
    
    DEFAULT_IMAGE = "manimcommunity/manim:stable"
    
    def __init__(self, image: str = DEFAULT_IMAGE):
        self.image = image
        self._docker_available = None
    
    def is_docker_available(self) -> bool:
        """
        Verifie si Docker est disponible.
        
        Returns:
            bool: True si Docker est disponible
        """
        if self._docker_available is not None:
            return self._docker_available
        
        try:
            result = subprocess.run(
                ["docker", "--version"],
                capture_output=True,
                text=True
            )
            self._docker_available = result.returncode == 0
            return self._docker_available
            
        except Exception:
            self._docker_available = False
            return False
    
    async def run_manim(
        self,
        code: str,
        scene_name: str,
        output_dir: str,
        timeout: int = MANIM_TIMEOUT_SECONDS
    ) -> Tuple[bool, Optional[str], Optional[str]]:
        """
        Execute le code Manim dans un sandbox Docker.
        
        Args:
            code: Code Manim
            scene_name: Nom de la scene
            output_dir: Dossier de sortie
            timeout: Timeout en secondes
            
        Returns:
            Tuple[bool, Optional[str], Optional[str]]: (succes, stdout, stderr)
        """
        if not self.is_docker_available():
            # Fallback: execution locale
            return await self._run_local(code, scene_name, output_dir, timeout)
        
        # Execution Docker
        return await self._run_docker(code, scene_name, output_dir, timeout)
    
    async def _run_docker(
        self,
        code: str,
        scene_name: str,
        output_dir: str,
        timeout: int
    ) -> Tuple[bool, Optional[str], Optional[str]]:
        """
        Execute le code dans un conteneur Docker.
        """
        # Creer un fichier temporaire
        with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
            f.write(code)
            script_path = f.name
        
        try:
            # Commande Docker
            cmd = [
                "docker", "run",
                "--rm",
                "--network", "none",  # Pas d'acces reseau
                "--memory", "2g",
                "--cpus", "2",
                "-v", f"{script_path}:/app/script.py:ro",
                "-v", f"{output_dir}:/app/output",
                self.image,
                "manim", "-pqh",
                "/app/script.py",
                scene_name,
                "-o", "/app/output/output.mp4"
            ]
            
            # Executer le processus
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(),
                    timeout=timeout
                )
                success = process.returncode == 0
                return success, stdout.decode(), stderr.decode()
                
            except asyncio.TimeoutError:
                process.kill()
                await process.wait()
                return False, "", "Timeout lors de l'execution"
                
        finally:
            # Nettoyer le fichier temporaire
            os.unlink(script_path)
    
    async def _run_local(
        self,
        code: str,
        scene_name: str,
        output_dir: str,
        timeout: int
    ) -> Tuple[bool, Optional[str], Optional[str]]:
        """
        Execute le code en local (fallback).
        """
        with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
            f.write(code)
            script_path = f.name
        
        try:
            cmd = [
                "manim",
                "-pqh",
                script_path,
                scene_name,
                "-o", f"{output_dir}/output.mp4"
            ]
            
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(),
                    timeout=timeout
                )
                success = process.returncode == 0
                return success, stdout.decode(), stderr.decode()
                
            except asyncio.TimeoutError:
                process.kill()
                await process.wait()
                return False, "", "Timeout lors de l'execution"
                
        finally:
            os.unlink(script_path)
    
    def cleanup_workspace(self, workspace_path: str):
        """
        Nettoie l'espace de travail.
        
        Args:
            workspace_path: Chemin de l'espace de travail
        """
        path = Path(workspace_path)
        if path.exists():
            shutil.rmtree(path)
            logger.info(f"Workspace cleaned: {workspace_path}")