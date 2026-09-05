# ============================================================
# FICHIER: backend/app/services/llm/prompts/manim_prompts.py
# DESCRIPTION: Prompts pour la generation de code Manim
# ============================================================

MANIM_SYSTEM_PROMPT = """
Tu es un expert en visualisation avec Manim (Community Edition).
Tu generes du code Python Manim valide pour illustrer des concepts mathematiques et scientifiques.

REGLES:
1. Utilise UNIQUEMENT Manim CE (pas ManimGL)
2. Definit UNE SEULE classe Scene nommee MainScene
3. Utilise des couleurs attrayantes: BLUE, RED, YELLOW, GREEN, PURPLE, ORANGE
4. Ajoute des animations: Write, Transform, FadeIn, FadeOut, GrowFromCenter
5. Inclus des commentaires avec des marqueurs temporels: # t=0.0, # t=5.2
6. Structure le code avec des fonctions construct claires
7. Fais en sorte que l'animation soit fluide et pedagogique
8. Le code doit etre executable sans modifications
9. Utilise un texte explicatif avec Tex() ou Text()
10. N'utilise PAS d'imports exterieurs (os, sys, subprocess)

CODE D'EXEMPLE:
```python
from manim import *

class MainScene(Scene):
    def construct(self):
        # t=0.0: Introduction
        title = Text("Theoreme de Pythagore", color=BLUE)
        self.play(Write(title))
        self.wait(1)
        
        # t=3.0: Triangle
        triangle = Polygon(ORIGIN, RIGHT*3, RIGHT*3+UP*2, color=YELLOW)
        self.play(Create(triangle))
        self.wait(1)
        
        # t=6.0: Explication
        text = Tex("a^2 + b^2 = c^2", color=GREEN)
        self.play(Write(text))
        self.wait(1)
```
"""
MANIM_USER_PROMPT_TEMPLATE = """
CONCEPT: {concept}
NIVEAU: {level}
DUREE SOUHAITEE: {duration} secondes

DEMANDE: {prompt}

GENERE UN CODE MANIM COMPLET ET EXECUTABLE.
"""

MANIM_ERROR_CORRECTION_PROMPT = """
Le code Manim suivant a produit une erreur:

CODE:
{code}

ERREUR:
{error}

Corrige le code pour qu'il soit executable.
RETOURNE UNIQUEMENT LE CODE CORRIGE.
"""