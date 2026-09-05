# ============================================================
# FICHIER: backend/docker/manim/Dockerfile
# DESCRIPTION: Image Docker pour Manim
# ============================================================

FROM manimcommunity/manim:stable

# Dependances supplementaires
RUN pip install --no-cache-dir \
    numpy==1.24.3 \
    matplotlib==3.7.1 \
    scipy==1.10.1

# Creer les dossiers de travail
WORKDIR /app
RUN mkdir -p /app/scripts /app/output /app/temp

# Utilisateur non-root pour la securite
RUN useradd -m -u 1000 manimuser && \
    chown -R manimuser:manimuser /app

USER manimuser

# Point d'entree
ENTRYPOINT ["manim"]
CMD ["--help"]