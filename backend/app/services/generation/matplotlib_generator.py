# ============================================================
# FICHIER: backend/app/services/generation/matplotlib_generator.py
# DESCRIPTION: Generateur de fallback avec Matplotlib
# ============================================================

from typing import Optional, List
import matplotlib
matplotlib.use('Agg')  # Pas de GUI
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import numpy as np
from pathlib import Path

from .base_generator import BaseGenerator

import logging

logger = logging.getLogger(__name__)


class MatplotlibGenerator(BaseGenerator):
    """
    Generateur de fallback utilisant Matplotlib.
    Produit des animations simples quand Manim echoue.
    """
    
    @property
    def name(self) -> str:
        return "matplotlib"
    
    @property
    def supported_formats(self) -> List[str]:
        return ["mp4", "gif"]
    
    async def generate(self, code: str, job_id: str, workspace: dict) -> Optional[str]:
        """
        Genere une animation simple avec Matplotlib.
        Ce generateur est un fallback, il ne fait pas de parsing complexe.
        
        Args:
            code: Code (ignore, genere une animation par defaut)
            job_id: ID du job
            workspace: Espace de travail
            
        Returns:
            Optional[str]: Chemin du fichier genere
        """
        try:
            output_dir = Path(workspace["renders"])
            output_dir.mkdir(parents=True, exist_ok=True)
            
            # Creer une animation simple (animation de sinus)
            fig, ax = plt.subplots()
            x = np.linspace(0, 2 * np.pi, 100)
            line, = ax.plot(x, np.sin(x))
            
            def update(frame):
                line.set_ydata(np.sin(x + frame * 0.1))
                return line,
            
            anim = animation.FuncAnimation(
                fig, update, frames=100, interval=50, blit=True
            )
            
            video_path = output_dir / f"{job_id}_fallback.mp4"
            
            # Sauvegarder
            anim.save(
                str(video_path),
                writer=animation.FFMpegWriter(fps=20, bitrate=1000)
            )
            
            plt.close(fig)
            
            logger.info(f"Job {job_id}: Fallback Matplotlib genere avec succes")
            return str(video_path)
            
        except Exception as e:
            logger.error(f"Job {job_id}: Erreur Matplotlib - {str(e)}")
            return None
    
    def validate_code(self, code: str) -> bool:
        """Matplotlib accepte tout code car c'est un fallback"""
        return True