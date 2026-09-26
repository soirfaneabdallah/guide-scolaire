# ============================================================
# FICHIER: backend/app/services/video/stream_renderer.py
# DESCRIPTION: Génération vidéo avec montage propre + cache TTL
# ============================================================

import asyncio
import glob
import hashlib
import json
import logging
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import List, Dict, Optional

from .ia_service_client import IAServiceClient

logger = logging.getLogger(__name__)


# ============================================================
# DÉTECTION FFMPEG (multi-plateforme)
# ============================================================

_FFMPEG_CACHE: Optional[str] = None


def find_ffmpeg() -> str:
    global _FFMPEG_CACHE
    if _FFMPEG_CACHE:
        return _FFMPEG_CACHE

    # 1. Override manuel
    env_bin = os.environ.get("FFMPEG_BIN")
    if env_bin and os.path.exists(env_bin):
        _FFMPEG_CACHE = env_bin
        return _FFMPEG_CACHE

    # 2. PATH système
    found = shutil.which("ffmpeg")
    if found:
        _FFMPEG_CACHE = found
        return _FFMPEG_CACHE

    # 3. imageio-ffmpeg (fallback Python)
    try:
        import imageio_ffmpeg
        _FFMPEG_CACHE = imageio_ffmpeg.get_ffmpeg_exe()
        return _FFMPEG_CACHE
    except ImportError:
        pass

    # 4. Chemins connus par OS
    if sys.platform == "win32":
        candidates = [
            os.path.expandvars(
                r"%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg*\**\bin\ffmpeg.exe"
            ),
            r"C:\ffmpeg\bin\ffmpeg.exe",
            r"C:\Program Files\ffmpeg\bin\ffmpeg.exe",
        ]
    elif sys.platform == "darwin":
        candidates = ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg"]
    else:
        candidates = ["/usr/bin/ffmpeg", "/usr/local/bin/ffmpeg"]

    for pattern in candidates:
        matches = glob.glob(pattern, recursive=True)
        if matches:
            _FFMPEG_CACHE = matches[0]
            return _FFMPEG_CACHE

    _FFMPEG_CACHE = "ffmpeg"
    return _FFMPEG_CACHE


FFMPEG_BIN = find_ffmpeg()


# ============================================================
# CONSTANTES DE MONTAGE
# ============================================================

VIDEO_FADE_DURATION = 0.4       # fondu ouverture/fermeture vidéo globale
AUDIO_FADE_DURATION = 0.2       # fondu ouverture/fermeture audio global
SCENE_PADDING = 0.6             # silence de respiration fin de scène
TRANSITION_DURATION = 0.5       # crossfade entre scènes

VIDEO_CODEC = "libx264"
VIDEO_PRESET = "medium"
VIDEO_CRF = "23"
AUDIO_CODEC = "aac"
AUDIO_BITRATE = "192k"

# Cache des vidéos générées
CACHE_DIR = Path(tempfile.gettempdir()) / "elearning_video_cache"
CACHE_TTL_SECONDS = 3600        # 1 heure


# ============================================================
# CLASSE PRINCIPALE
# ============================================================

class StreamRenderer:
    """
    Génère une vidéo pédagogique à partir d'un script.

    ⚠️ AUCUNE VIDÉO N'EST STOCKÉE DE FAÇON PERMANENTE.
    Les MP4 générés sont mis en cache temporaire dans /tmp avec un TTL de 1h,
    puis automatiquement supprimés.

    ARCHITECTURE DU MONTAGE
    -----------------------
    - Chaque scène est alignée en durée + normalisée (fps/format/audio).
    - Les transitions ENTRE scènes sont assurées par xfade/acrossfade.
    - Le fondu d'OUVERTURE et de FERMETURE est appliqué UNE FOIS sur le flux final.
    - Le MP4 final est produit avec `+faststart` (moov au début) → la durée
      totale est connue instantanément par le navigateur → barre de progression
      fonctionnelle + seek possible.
    """

    def __init__(self):
        self.ia = IAServiceClient()
        logger.info(f"🎬 [Stream] FFmpeg = {FFMPEG_BIN}")
        CACHE_DIR.mkdir(exist_ok=True, parents=True)

    # ============================================================
    # EXTRACTION DU NOM DE CLASSE MANIM
    # ============================================================

    @staticmethod
    def _extract_class_name(code: str, fallback: str = "MainScene") -> str:
        if not code:
            return fallback
        match = re.search(r'class\s+(\w+)\s*\(\s*[^)]*\bScene\w*\b[^)]*\)', code)
        if match:
            return match.group(1)
        logger.warning(f"⚠️ [Render] Pas de classe Scene trouvée, fallback: {fallback}")
        return fallback

    # ============================================================
    # MESURE DE DURÉE
    # ============================================================

    @staticmethod
    def _get_duration(path: str) -> float:
        """Mesure la durée d'un média via ffprobe."""
        ffprobe = FFMPEG_BIN.replace("ffmpeg", "ffprobe")
        if not os.path.exists(ffprobe):
            ffprobe = "ffprobe"

        try:
            result = subprocess.run(
                [
                    ffprobe, "-v", "error",
                    "-show_entries", "format=duration",
                    "-of", "default=noprint_wrappers=1:nokey=1",
                    path,
                ],
                capture_output=True, text=True, timeout=30,
            )
            return float(result.stdout.strip())
        except Exception as e:
            logger.warning(f"⚠️ Impossible de mesurer la durée de {path}: {e}")
            return 0.0

    # ============================================================
    # CACHE : clé + nettoyage
    # ============================================================

    @staticmethod
    def cache_key(script_id: str, scenes: List[Dict]) -> str:
        """Clé de cache = script_id + hash des scènes (invalide si le script change)."""
        content = json.dumps(scenes, sort_keys=True, ensure_ascii=False)
        scene_hash = hashlib.sha256(content.encode()).hexdigest()[:16]
        return f"{script_id}_{scene_hash}.mp4"

    @staticmethod
    def cleanup_cache(force: bool = False) -> int:
        """
        Supprime les MP4 du cache plus vieux que CACHE_TTL_SECONDS.
        Retourne le nombre de fichiers supprimés.
        """
        if not CACHE_DIR.exists():
            return 0

        now = time.time()
        removed = 0
        for f in CACHE_DIR.glob("*.mp4"):
            try:
                age = now - f.stat().st_mtime
                if force or age > CACHE_TTL_SECONDS:
                    f.unlink()
                    removed += 1
                    logger.info(f"🧹 [Cache] Supprimé : {f.name} (âge {age/60:.0f}min)")
            except OSError as e:
                logger.warning(f"⚠️ [Cache] Impossible de supprimer {f.name}: {e}")
        return removed

    # ============================================================
    # POINT D'ENTRÉE : générer un MP4 complet dans un fichier
    # ============================================================

    async def render_video_to_file(
        self,
        script_id: str,
        scenes: List[Dict],
        output_path: str,
    ) -> bool:
        """
        Génère UN SEUL MP4 final avec :
        - Alignement des durées par scène
        - Crossfade entre scènes (xfade)
        - Fondu global ouverture/fermeture
        - Index global en début de fichier (faststart)
          → durée totale connue instantanément → barre de progression OK
          → seek possible
          → Range requests gérées nativement par FileResponse

        Retourne True si succès, False sinon.
        """
        logger.info(f"🎬 [Render] Démarrage pour script {script_id}")
        logger.info(f"🎬 [Render] {len(scenes)} scènes à traiter")

        temp_dir = tempfile.mkdtemp(prefix=f"render_{script_id}_")
        logger.info(f"📁 [Render] Dossier temporaire : {temp_dir}")

        try:
            scene_files = []

            # ---- 1. Générer chaque scène (TTS + Manim + mux) ----
            for i, scene in enumerate(scenes):
                logger.info(f"🎬 [Render] Scène {i+1}/{len(scenes)} : {scene.get('title', 'Sans titre')}")

                # TTS
                narration = scene.get("narration", "")
                audio_bytes = await self.ia.synthesize_tts(text=narration)
                if not audio_bytes:
                    logger.warning(f"⚠️ Scène {i+1}: TTS échoué, ignorée")
                    continue

                # Manim
                manim_code = scene.get("manim_code", "")
                class_name = scene.get("class_name") or self._extract_class_name(manim_code)
                video_bytes = await self.ia.render_manim(
                    code=manim_code,
                    scene_name=class_name,
                )
                if not video_bytes:
                    logger.warning(f"⚠️ Scène {i+1}: Manim échoué, ignorée")
                    continue

                # Écrire les bytes
                audio_path = os.path.join(temp_dir, f"audio_{i:03d}.mp3")
                video_path = os.path.join(temp_dir, f"video_{i:03d}.mp4")
                scene_final = os.path.join(temp_dir, f"scene_{i:03d}.mp4")

                with open(audio_path, "wb") as f:
                    f.write(audio_bytes)
                with open(video_path, "wb") as f:
                    f.write(video_bytes)

                # Mux + normalisation (sans fondu)
                try:
                    await self._mux_scene_pro(
                        video_path=video_path,
                        audio_path=audio_path,
                        output_path=scene_final,
                    )
                except Exception as e:
                    logger.error(f"❌ Scène {i+1}: mux échoué ({e}), ignorée")
                    continue

                scene_files.append(scene_final)

                # Nettoyer les intermédiaires
                for p in (audio_path, video_path):
                    try:
                        os.unlink(p)
                    except OSError:
                        pass

                logger.info(f"   ✅ Scène {i+1} prête")

            if not scene_files:
                logger.error("❌ Aucune scène générée")
                return False

            # ---- 2. Concaténer avec transitions + fondu global ----
            logger.info(f"🎬 [Render] Assemblage de {len(scene_files)} scènes")

            success = await self._render_final_to_file(scene_files, output_path)

            return success

        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)
            logger.info(f"🧹 [Render] Nettoyage terminé")

    # ============================================================
    # MUXER UNE SCÈNE (alignement + normalisation, SANS fondu)
    # ============================================================

    async def _mux_scene_pro(
        self,
        video_path: str,
        audio_path: str,
        output_path: str,
    ):
        """
        Muxe vidéo + audio d'UNE scène :
        - Aligne la vidéo sur la durée cible (audio + silence de respiration)
        - Normalise fps/format/sample-rate pour que toutes les scènes soient
          bit-compatibles entre elles au moment du crossfade
        - Aucun fondu ici (voir note d'architecture)
        """
        audio_dur = self._get_duration(audio_path)
        video_dur = self._get_duration(video_path)
        target_dur = audio_dur + SCENE_PADDING

        logger.info(f"   Durées : vidéo={video_dur:.2f}s, audio={audio_dur:.2f}s, cible={target_dur:.2f}s")

        # --- Filtre vidéo : alignement + normalisation ---
        video_filters = []
        if video_dur < target_dur:
            pad_dur = target_dur - video_dur
            video_filters.append(f"tpad=stop_mode=clone:stop_duration={pad_dur:.3f}")
        else:
            video_filters.append(f"trim=0:{target_dur:.3f}")
            video_filters.append("setpts=PTS-STARTPTS")
        video_filters.append("fps=30")
        video_filters.append("format=yuv420p")

        # --- Filtre audio : silence de respiration + normalisation ---
        audio_filters = [
            f"apad=whole_dur={target_dur:.3f}",
            "loudnorm=I=-16:TP=-1.5:LRA=11",
        ]

        video_filter_str = ",".join(video_filters)
        audio_filter_str = ",".join(audio_filters)

        cmd = [
            FFMPEG_BIN, "-y", "-loglevel", "error",
            "-i", video_path,
            "-i", audio_path,
            "-filter_complex",
            f"[0:v]{video_filter_str}[v];[1:a]{audio_filter_str}[a]",
            "-map", "[v]", "-map", "[a]",
            "-c:v", VIDEO_CODEC,
            "-preset", VIDEO_PRESET,
            "-crf", VIDEO_CRF,
            "-pix_fmt", "yuv420p",
            "-r", "30",
            "-c:a", AUDIO_CODEC,
            "-b:a", AUDIO_BITRATE,
            "-ar", "44100",
            "-ac", "2",
            "-t", f"{target_dur:.3f}",
            output_path,
        ]

        def _run():
            return subprocess.run(cmd, capture_output=True, timeout=180)

        result = await asyncio.to_thread(_run)

        if result.returncode != 0:
            stderr = result.stderr.decode(errors="ignore")[:800]
            logger.error(f"❌ Mux error: {stderr}")
            raise Exception(f"Mux failed: {stderr[:200]}")

    # ============================================================
    # RENDU FINAL → fichier (avec faststart)
    # ============================================================

    async def _render_final_to_file(
        self,
        scene_files: List[str],
        output_path: str,
    ) -> bool:
        """
        Concatène les scènes avec xfade, applique le fondu global, et écrit
        le résultat dans output_path avec `+faststart` (moov au début).
        """
        durations = [self._get_duration(f) for f in scene_files]
        logger.info(f"🎬 [Render] Durées : {[f'{d:.2f}' for d in durations]}")

        # ---- Cas d'une seule scène ----
        if len(scene_files) == 1:
            total_duration = durations[0]
            video_out = (
                f"fade=t=in:st=0:d={VIDEO_FADE_DURATION},"
                f"fade=t=out:st={max(0.0, total_duration - VIDEO_FADE_DURATION):.3f}"
                f":d={VIDEO_FADE_DURATION}"
            )
            audio_out = (
                f"afade=t=in:st=0:d={AUDIO_FADE_DURATION},"
                f"afade=t=out:st={max(0.0, total_duration - AUDIO_FADE_DURATION):.3f}"
                f":d={AUDIO_FADE_DURATION}"
            )
            cmd = [
                FFMPEG_BIN, "-y", "-loglevel", "error",
                "-i", scene_files[0],
                "-filter_complex", f"[0:v]{video_out}[v];[0:a]{audio_out}[a]",
                "-map", "[v]", "-map", "[a]",
                "-c:v", VIDEO_CODEC, "-preset", VIDEO_PRESET, "-crf", VIDEO_CRF,
                "-pix_fmt", "yuv420p", "-r", "30",
                "-c:a", AUDIO_CODEC, "-b:a", AUDIO_BITRATE,
                "-movflags", "+faststart",
                output_path,
            ]
            logger.info("🎬 [Render] Une seule scène : fondu global uniquement")
            return await self._run_ffmpeg_to_file(cmd)

        # ---- Plusieurs scènes : xfade ----
        transition = min(TRANSITION_DURATION, min(durations) / 2)
        if transition < TRANSITION_DURATION:
            logger.warning(
                f"⚠️ [Render] Scène(s) courte(s) — transition réduite à "
                f"{transition:.2f}s (au lieu de {TRANSITION_DURATION}s)"
            )

        inputs = []
        for f in scene_files:
            inputs.extend(["-i", f])

        filter_parts = []
        cumulative_offset = 0.0

        for i in range(len(scene_files)):
            if i == 0:
                filter_parts.append("[0:v]setpts=PTS-STARTPTS[v0]")
                filter_parts.append("[0:a]asetpts=PTS-STARTPTS[a0]")
                cumulative_offset = durations[0]
            else:
                offset = cumulative_offset - transition
                prev_v = f"[v{i-1}]" if i > 1 else "[v0]"
                prev_a = f"[a{i-1}]" if i > 1 else "[a0]"
                curr_v = f"[{i}:v]"
                curr_a = f"[{i}:a]"

                filter_parts.append(
                    f"{prev_v}{curr_v}xfade=transition=fade:"
                    f"duration={transition:.3f}:offset={offset:.3f}[v{i}]"
                )
                filter_parts.append(
                    f"{prev_a}{curr_a}acrossfade=d={transition:.3f}[a{i}]"
                )

                cumulative_offset = offset + durations[i]

        last = len(scene_files) - 1
        total_duration = cumulative_offset

        # Fondu global ouverture/fermeture (une seule fois)
        filter_parts.append(
            f"[v{last}]fade=t=in:st=0:d={VIDEO_FADE_DURATION},"
            f"fade=t=out:st={max(0.0, total_duration - VIDEO_FADE_DURATION):.3f}"
            f":d={VIDEO_FADE_DURATION}[vout]"
        )
        filter_parts.append(
            f"[a{last}]afade=t=in:st=0:d={AUDIO_FADE_DURATION},"
            f"afade=t=out:st={max(0.0, total_duration - AUDIO_FADE_DURATION):.3f}"
            f":d={AUDIO_FADE_DURATION}[aout]"
        )

        filter_complex = ";".join(filter_parts)

        cmd = [
            FFMPEG_BIN, "-y", "-loglevel", "error",
            *inputs,
            "-filter_complex", filter_complex,
            "-map", "[vout]", "-map", "[aout]",
            "-c:v", VIDEO_CODEC, "-preset", VIDEO_PRESET, "-crf", VIDEO_CRF,
            "-pix_fmt", "yuv420p", "-r", "30",
            "-c:a", AUDIO_CODEC, "-b:a", AUDIO_BITRATE,
            "-movflags", "+faststart",   # ← index global au début
            output_path,
        ]

        logger.info(
            f"🎬 [Render] xfade sur {len(scene_files)} scènes "
            f"(transition={transition:.2f}s, durée totale≈{total_duration:.2f}s)"
        )
        return await self._run_ffmpeg_to_file(cmd)

    # ============================================================
    # FFMPEG → fichier (avec drainage stderr pour éviter deadlock)
    # ============================================================

    async def _run_ffmpeg_to_file(self, cmd: List[str]) -> bool:
        """
        Lance FFmpeg et attend la fin. Drainage stderr en parallèle pour
        éviter le deadlock du tampon.
        """
        def _start():
            return subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                bufsize=0,
            )

        process = await asyncio.to_thread(_start)

        stderr_chunks: List[bytes] = []

        def _drain_stderr():
            for chunk in iter(lambda: process.stderr.read(4096), b""):
                stderr_chunks.append(chunk)

        stderr_task = asyncio.create_task(asyncio.to_thread(_drain_stderr))

        try:
            await asyncio.to_thread(process.wait)
        finally:
            await stderr_task

        if process.returncode != 0:
            stderr = b"".join(stderr_chunks).decode(errors="ignore")
            logger.error(f"❌ FFmpeg error: {stderr[:800]}")
            return False

        if not os.path.exists(cmd[-1]) or os.path.getsize(cmd[-1]) == 0:
            logger.error(f"❌ FFmpeg: fichier de sortie vide ou absent : {cmd[-1]}")
            return False

        size_mb = os.path.getsize(cmd[-1]) / 1024 / 1024
        logger.info(f"✅ [Render] Fichier final : {size_mb:.2f} Mo")
        return True