# backend/scripts/migrate_video_scripts.py

"""
Script pour ajouter les colonnes manquantes à la table video_scripts
"""

import sqlite3
from pathlib import Path


def migrate():
    # Chemin de la base de données
    db_path = Path("guide_scolaire.db")
    
    if not db_path.exists():
        print(f"❌ Base de données non trouvée : {db_path}")
        return
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Vérifier les colonnes existantes
    cursor.execute("PRAGMA table_info(video_scripts)")
    existing_columns = {row[1] for row in cursor.fetchall()}
    
    print(f"📋 Colonnes existantes : {existing_columns}")
    
    # Colonnes à ajouter
    columns_to_add = {
        "thumbnail_url": "VARCHAR(500)",
        "thumbnail_prompt": "TEXT",
        "language": "VARCHAR(10) DEFAULT 'fr'",
    }
    
    # Ajouter les colonnes manquantes
    for column_name, column_type in columns_to_add.items():
        if column_name not in existing_columns:
            try:
                cursor.execute(
                    f"ALTER TABLE video_scripts ADD COLUMN {column_name} {column_type}"
                )
                print(f"✅ Colonne ajoutée : {column_name}")
            except Exception as e:
                print(f"❌ Erreur pour {column_name} : {e}")
        else:
            print(f"⏭️  Colonne déjà présente : {column_name}")
    
    conn.commit()
    conn.close()
    
    print("\n✅ Migration terminée !")


if __name__ == "__main__":
    migrate()