# Scripts - Rhapsodie Quiz IA

Ce dossier contient tous les scripts shell (`.sh`) du projet.

## Scripts Disponibles

### 🚀 Gestion de la Plateforme

#### `start.sh`
Démarre tous les services Docker Compose.

```bash
./scripts/start.sh                    # Démarre les services de base
./scripts/start.sh --ai               # Démarre avec les services AI
./scripts/start.sh --tools           # Démarre avec les outils de développement
./scripts/start.sh --ai --tools      # Démarre tout
```

#### `stop.sh`
Arrête tous les services Docker Compose.

```bash
./scripts/stop.sh                     # Arrête les conteneurs (conserve volumes/images)
./scripts/stop.sh --volumes           # Arrête et supprime les volumes
./scripts/stop.sh --images            # Arrête et supprime les images
./scripts/stop.sh --all               # Arrête et supprime tout
```

### 💾 Gestion de la Base de Données

#### `export-database.sh`
Exporte la base de données depuis le conteneur Docker.

```bash
./scripts/export-database.sh
```

Le fichier de sauvegarde sera créé dans `database-backups/` avec un timestamp.

#### `import-db.sh`
Importe une base de données depuis un fichier SQL.

```bash
./scripts/import-db.sh                                    # Utilise la sauvegarde par défaut
./scripts/import-db.sh database-backups/backup.sql       # Spécifie un fichier
```

#### `export-db.sh`
Ancien script d'export (utiliser `export-database.sh` à la place).

#### `generate-secrets.sh`
Génère des secrets pour l'application (JWT, API keys, etc.).

```bash
./scripts/generate-secrets.sh
```

## Structure

Tous les scripts sont conçus pour être exécutés depuis n'importe où dans le projet. Ils :
- Détectent automatiquement le répertoire racine du projet
- Chargent les variables d'environnement depuis `.env` à la racine
- S'exécutent depuis le répertoire racine pour accéder à `docker-compose.yml`

## Prérequis

- Docker et Docker Compose installés
- Fichier `.env` configuré à la racine du projet
- Conteneurs Docker démarrés (pour les scripts de base de données)

## Notes

- Les scripts utilisent le conteneur `rhapsody-db` pour les opérations de base de données
- Les sauvegardes sont stockées dans `database-backups/`
- Les scripts vérifient automatiquement que les conteneurs sont en cours d'exécution avant d'effectuer des opérations

