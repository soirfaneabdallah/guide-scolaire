#!/usr/bin/env python3
"""
Script d'insertion d'une vidéo pédagogique dans la base de données.

Sujet    : Le théorème de Pythagore
Matière  : Mathématiques
Niveau   : 4ème

Usage :
    python scripts/insert_video.py
"""

import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.core.database import SessionLocal
from app.models.video_script import VideoScript
from app.models.subject import Subject


TITLE = "Le théorème de Pythagore"
DESCRIPTION = (
    "Découvre comment retrouver la longueur d'un côté d'un triangle "
    "rectangle grâce à la relation entre les carrés de ses côtés."
)
SUBJECT_NAME = "Mathématiques"
LEVEL = "4ème"
CHAPTER = "Géométrie — Triangle rectangle"
TAGS = ["pythagore", "triangle rectangle", "géométrie", "théorème"]
LANGUAGE = "fr"


SCENES = [
    {
        "id": "scene_1",
        "order": 1,
        "title": "Un triangle bien particulier",
        "concept": "Présentation du triangle rectangle",
        "narration": (
            "Voici un triangle rectangle : il possède un angle droit, marqué "
            "ici par ce petit carré jaune. Ce triangle très particulier va "
            "nous permettre de découvrir l'un des théorèmes les plus connus "
            "des mathématiques."
        ),
        "manim_code": '''from manim import *
import numpy as np


class MainScene(Scene):
    def construct(self):
        titre = Text("Un triangle rectangle", font_size=40, color=WHITE)
        titre.to_edge(UP)
        self.play(Write(titre), run_time=1.5)

        A = np.array([-2.5, -1.5, 0])
        B = np.array([1.5, -1.5, 0])
        C = np.array([-2.5, 1.5, 0])

        triangle = Polygon(A, B, C, color=BLUE, fill_opacity=0.15)
        angle_marker = Square(side_length=0.3, color=YELLOW)
        angle_marker.move_to(A + np.array([0.15, 0.15, 0]))

        self.play(Create(triangle), run_time=2)
        self.play(FadeIn(angle_marker), run_time=1)

        label = Text("Angle droit", font_size=24, color=YELLOW)
        label.next_to(angle_marker, RIGHT, buff=0.3)
        self.play(FadeIn(label), run_time=1)
        self.wait(2)
''',
        "estimated_duration": 22,
    },
    {
        "id": "scene_2",
        "order": 2,
        "title": "Les trois côtés",
        "concept": "Nommer les côtés du triangle (côtés de l'angle droit et hypoténuse)",
        "narration": (
            "Ce triangle a trois côtés. Les deux côtés qui forment l'angle "
            "droit s'appellent a et b. Le troisième côté, toujours en face "
            "de l'angle droit, s'appelle l'hypoténuse : c'est toujours le "
            "côté le plus long."
        ),
        "manim_code": '''from manim import *
import numpy as np


class MainScene(Scene):
    def construct(self):
        titre = Text("Les trois côtés du triangle", font_size=36, color=WHITE)
        titre.to_edge(UP)
        self.play(Write(titre), run_time=1.5)

        A = np.array([-2.5, -1.5, 0])
        B = np.array([1.5, -1.5, 0])
        C = np.array([-2.5, 1.5, 0])

        triangle = Polygon(A, B, C, color=BLUE, fill_opacity=0.15)
        self.play(Create(triangle), run_time=1.5)

        cote_a = Line(A, B, color=GREEN, stroke_width=6)
        cote_b = Line(A, C, color=RED, stroke_width=6)
        hypotenuse = Line(B, C, color=YELLOW, stroke_width=6)

        label_a = Text("a", font_size=32, color=GREEN).next_to(cote_a, DOWN)
        label_b = Text("b", font_size=32, color=RED).next_to(cote_b, LEFT)
        label_c = Text("c (hypoténuse)", font_size=28, color=YELLOW)
        label_c.move_to((B + C) / 2 + np.array([0.9, 0.4, 0]))

        self.play(Create(cote_a), FadeIn(label_a), run_time=1.2)
        self.play(Create(cote_b), FadeIn(label_b), run_time=1.2)
        self.play(Create(hypotenuse), FadeIn(label_c), run_time=1.2)
        self.wait(2)
''',
        "estimated_duration": 25,
    },
    {
        "id": "scene_3",
        "order": 3,
        "title": "La relation entre les côtés",
        "concept": "Énoncé du théorème : a² + b² = c²",
        "narration": (
            "Le théorème de Pythagore dit ceci : dans un triangle rectangle, "
            "le carré de l'hypoténuse est égal à la somme des carrés des "
            "deux autres côtés. On écrit cette relation : a au carré plus b "
            "au carré égale c au carré."
        ),
        "manim_code": '''from manim import *
import numpy as np


class MainScene(Scene):
    def construct(self):
        titre = Text("Le théorème de Pythagore", font_size=36, color=WHITE)
        titre.to_edge(UP)
        self.play(Write(titre), run_time=1.5)

        A = np.array([-3.5, -1.0, 0])
        B = np.array([-0.5, -1.0, 0])
        C = np.array([-3.5, 1.0, 0])

        triangle = Polygon(A, B, C, color=BLUE, fill_opacity=0.15)
        self.play(Create(triangle), run_time=1.5)

        carre_a = Square(side_length=1.5, color=GREEN, fill_opacity=0.3)
        carre_a.move_to(A + np.array([1.5, -0.75, 0]))

        carre_b = Square(side_length=1.0, color=RED, fill_opacity=0.3)
        carre_b.move_to(A + np.array([-0.5, 0.5, 0]))

        self.play(FadeIn(carre_a), FadeIn(carre_b), run_time=1.5)

        formule = MathTex("a^2", "+", "b^2", "=", "c^2", font_size=56)
        formule[0].set_color(GREEN)
        formule[2].set_color(RED)
        formule[4].set_color(YELLOW)
        formule.next_to(triangle, RIGHT, buff=1.2)

        self.play(Write(formule), run_time=2)
        self.wait(2)
''',
        "estimated_duration": 28,
    },
    {
        "id": "scene_4",
        "order": 4,
        "title": "Un exemple avec des nombres",
        "concept": "Application numérique : vérification avec 3, 4, 5",
        "narration": (
            "Vérifions avec des nombres. Si a vaut 3 et b vaut 4, alors a "
            "au carré plus b au carré fait 9 plus 16, soit 25. Et 25 est "
            "bien le carré de 5. L'hypoténuse mesure donc exactement 5."
        ),
        "manim_code": '''from manim import *


class MainScene(Scene):
    def construct(self):
        titre = Text("Exemple : le triangle 3-4-5", font_size=36, color=WHITE)
        titre.to_edge(UP)
        self.play(Write(titre), run_time=1.5)

        etape1 = MathTex("a = 3", ",\\\\quad", "b = 4", font_size=44)
        etape1.move_to(UP * 1.2)
        self.play(Write(etape1), run_time=1.5)

        etape2 = MathTex("a^2 + b^2 = 3^2 + 4^2 = 9 + 16 = 25", font_size=40)
        etape2.next_to(etape1, DOWN, buff=0.6)
        self.play(Write(etape2), run_time=2)
        self.wait(1)

        etape3 = MathTex("c^2 = 25", "\\\\implies", "c = 5", font_size=48)
        etape3.set_color(YELLOW)
        etape3.next_to(etape2, DOWN, buff=0.6)
        self.play(Write(etape3), run_time=2)

        conclusion = Text("L'hypoténuse mesure 5 !", font_size=32, color=GREEN)
        conclusion.next_to(etape3, DOWN, buff=0.5)
        self.play(FadeIn(conclusion, shift=UP * 0.2), run_time=1.2)
        self.wait(2)
''',
        "estimated_duration": 25,
    },
]


def get_or_create_subject(db, name: str) -> Subject:
    """Récupère la matière si elle existe, la crée sinon."""
    subject = db.query(Subject).filter(Subject.name == name).first()
    if subject is not None:
        return subject
    subject = Subject(name=name)
    db.add(subject)
    db.flush()  # attribue l'id sans committer, pour pouvoir l'utiliser tout de suite
    return subject


def main() -> int:
    db = SessionLocal()
    try:
        subject = get_or_create_subject(db, SUBJECT_NAME)

        video = VideoScript(
            id=str(uuid.uuid4()),
            title=TITLE,
            description=DESCRIPTION,
            subject_id=subject.id,
            level=LEVEL,
            chapter=CHAPTER,
            tags=TAGS,
            thumbnail_url=None,
            thumbnail_prompt=None,
            scenes=SCENES,
            scene_count=len(SCENES),
            estimated_duration_seconds=sum(s["estimated_duration"] for s in SCENES),
            language=LANGUAGE,
            is_validated=False,
            is_generated=True,
            version=1,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
        )

        db.add(video)
        db.commit()
        db.refresh(video)

        print("=" * 60)
        print("✅ Vidéo insérée avec succès")
        print("=" * 60)
        print(f"ID            : {video.id}")
        print(f"Titre         : {video.title}")
        print(f"Matière       : {SUBJECT_NAME} (id={subject.id})")
        print(f"Niveau        : {video.level}")
        print(f"Chapitre      : {video.chapter}")
        print(f"Scènes        : {video.scene_count}")
        for s in video.scenes:
            print(f"  - [{s['order']}] {s['title']} ({s['estimated_duration']}s)")
        print(f"Durée totale  : {video.estimated_duration_seconds}s")
        print("=" * 60)
        return 0

    except Exception as exc:
        db.rollback()
        print(f"❌ Erreur lors de l'insertion : {exc}", file=sys.stderr)
        return 1

    finally:
        db.close()


if __name__ == "__main__":
    sys.exit(main())