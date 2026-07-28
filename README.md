# 📚 Guide Scolaire Comores

## 🎓 Plateforme éducative d'aide aux devoirs et de suivi scolaire pour les élèves comoriens.

**Guide Scolaire Comores** est un assistant intelligent qui accompagne les élèves du collège et du lycée aux Comores dans leur apprentissage. Il propose :

- ✅ Un **chat intelligent** pour poser des questions (à venir)
- ✅ Une **bibliothèque de cours** par niveau et matière (à venir)
- ✅ Un **cahier numérique** pour écrire à la main (à venir)
- ✅ Un **système de gamification** pour motiver l'apprentissage (à venir)

---

## 🛠️ Technologies utilisées

| Composant | Technologie |
|-----------|-------------|
| **Frontend** | Flutter (Web, Mobile, Desktop) |
| **Backend** | FastAPI (Python) |
| **Base de données** | PostgreSQL / SQLite (dev) |
| **Authentification** | JWT (JSON Web Tokens) |
| **Communication** | REST API |
| **Hébergement** | Render / Netlify (à venir) |

---

## 🚀 Installation et démarrage

### 1️⃣ Prérequis

- Flutter SDK 3.11+ (pour le frontend)
- Python 3.10+ (pour le backend)
- Node.js / npm (optionnel)
- Git

---

### 2️⃣ Backend

```bash
cd backend

# Créer l'environnement virtuel
python -m venv venv

# Activer l'environnement
source venv/bin/activate   # Sur Linux/Mac
venv\Scripts\activate      # Sur Windows

# Installer les dépendances
pip install -r requirements.txt

# Copier le fichier de configuration
cp .env.example .env

# Lancer le serveur
uvicorn app.main:app --reload