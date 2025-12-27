# Cahier de Charges - Plateforme Rhapsodie Quiz IA

**Version:** 1.0  
**Date:** Décembre 2024  
**Projet:** Plateforme de Quiz Mobile avec Génération IA de Questions

---

## Table des Matières

1. [Vue d'ensemble du Projet](#1-vue-densemble-du-projet)
2. [Architecture du Système](#2-architecture-du-système)
3. [Cas d'Usage](#3-cas-dusage)
4. [Modèles de Données](#4-modèles-de-données)
5. [Fonctionnalités Détaillées](#5-fonctionnalités-détaillées)
6. [Workflows Principaux](#6-workflows-principaux)
7. [Exigences Techniques](#7-exigences-techniques)
8. [Plan de Développement](#8-plan-de-développement)

---

## 1. Vue d'ensemble du Projet

### 1.1 Objectif

Créer une plateforme mobile de quiz/gaming centrée sur le contenu religieux, principalement "Rhapsody of Realities" (Rhapsodie des Réalités), avec génération automatique de questions à partir de PDFs via l'IA, système de récompenses, classements hiérarchiques et gestion de groupes.

### 1.2 Contexte Métier

**Rhapsody of Realities** est un livre mensuel publié en trois versions :
- **Kids** (Enfants)
- **Teens** (Adolescents)
- **Adult** (Adultes)

Chaque édition mensuelle contient :
- Un texte biblique quotidien
- Une prière quotidienne
- 30 jours de contenu (un par jour du mois)

### 1.3 Portée du Projet

**Phase 1 (Focus Initial):**
- Support du topic "Rhapsody of Realities"
- **Questions manuelles/factices** (génération IA repoussée à Phase 6)
- Quiz quotidiens avec récompenses
- Système de groupes hiérarchiques
- Classements multi-niveaux

**Phase 2 (Extension):**
- Support de multiples topics (Bible, Love World News, Heroes of Faith, etc.)
- Gestion de groupes personnalisés par topic
- Fonctionnalités avancées de gamification

**Phase 6 (Optionnel - Plus tard):**
- Génération automatique de QCM via IA (Ollama)
- Traitement PDF automatique
- Workflow de validation des questions générées par IA

---

## 2. Architecture du Système

### 2.1 Architecture Générale

```
┌─────────────────────────────────────────────────────────────┐
│                    MOBILE APP (Flutter)                     │
│  - Quiz Interface                                           │
│  - Group Management                                         │
│  - Leaderboards                                             │
│  - User Profile                                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ REST API
                       │
┌──────────────────────┴──────────────────────────────────────┐
│              ADMIN PANEL (CodeIgniter/PHP)                   │
│  - Content Management                                        │
│  - Question Validation Workflow                             │
│  - Group Administration                                      │
│  - User Management                                           │
│  - Analytics & Reports                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ Database (MySQL)
                       │
┌──────────────────────┴──────────────────────────────────────┐
│              AI QCM GENERATOR (Laravel API)                  │
│  - PDF Processing                                            │
│  - Question Generation (Ollama)                             │
│  - Question Storage                                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ File Upload
                       │
┌──────────────────────┴──────────────────────────────────────┐
│              PYTHON PDF PROCESSOR                            │
│  - PDF Text Extraction                                      │
│  - Chunking & Processing                                    │
│  - QCM Generation                                           │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Composants Principaux

#### 2.2.1 Application Mobile (Flutter)
- **Framework:** Flutter 3.10+
- **Architecture:** BLoC/Cubit Pattern
- **Authentification:** Firebase Auth (Google, Apple)
- **Base de données locale:** Hive
- **API Client:** HTTP avec gestion d'erreurs

#### 2.2.2 Panel d'Administration (CodeIgniter)
- **Framework:** CodeIgniter 3.x
- **Infrastructure:** Docker (MySQL, PHP, Nginx)
- **Base de données:** MySQL (`elite_quiz_237`)
- **Port:** 8080 (configurable)

#### 2.2.3 API de Génération IA (Laravel)
- **Framework:** Laravel 12
- **Authentification:** Laravel Sanctum
- **Base de données:** SQLite/MySQL
- **IA:** Ollama (local LLM)

#### 2.2.4 Processeur PDF (Python)
- **Bibliothèques:** PyPDF, Ollama
- **Interface:** Streamlit/Tkinter/CLI
- **Sortie:** JSON/YAML

### 2.3 Base de Données

#### Tables Principales Existantes (à étendre)
- `tbl_user` - Utilisateurs
- `tbl_question` - Questions
- `tbl_category` - Catégories
- `tbl_daily_quiz` - Quiz quotidiens
- `tbl_daily_quiz_user` - Suivi des quiz quotidiens par utilisateur
- `tbl_leaderboard` - Classements

#### Nouvelles Tables Requises
- `tbl_topic` - Topics (Rhapsody, Bible, etc.)
- `tbl_group` - Groupes (Worldwide, Country, Custom)
- `tbl_group_member` - Membres des groupes
- `tbl_group_topic` - Abonnements des groupes aux topics
- `tbl_daily_text` - Textes quotidiens (Rhapsody)
- `tbl_question_validation` - Workflow de validation des questions
- `tbl_battle` - Battles 1v1
- `tbl_user_points` - Points quotidiens/hebdomadaires/mensuels
- `tbl_reward` - Récompenses

---

## 3. Cas d'Usage

### 3.1 Utilisateur Final (Mobile App)

#### UC-1: Inscription et Connexion
**Acteur:** Utilisateur  
**Préconditions:** Application installée  
**Scénario principal:**
1. L'utilisateur ouvre l'application
2. Choisit "Sign in with Google" ou "Sign in with Apple"
3. Authentification Firebase
4. Création/validation du compte via API
5. Sélection du groupe par défaut (Country)
6. Accès au dashboard

**Scénarios alternatifs:**
- Échec d'authentification → Message d'erreur
- Compte existant → Connexion directe

#### UC-2: Lecture du Texte Quotidien
**Acteur:** Utilisateur  
**Préconditions:** Utilisateur connecté, jour actif  
**Scénario principal:**
1. À 00:00 (timezone locale), le texte du jour devient disponible
2. L'utilisateur ouvre la section "Daily Text"
3. Affichage du texte biblique et de la prière du jour
4. L'utilisateur lit le texte
5. Système enregistre la lecture (récompense: points de lecture)
6. Déblocage du quiz du jour

**Points:** 2 points pour la lecture

#### UC-3: Répondre au Quiz Quotidien
**Acteur:** Utilisateur  
**Préconditions:** Texte quotidien lu, questions validées par admin  
**Scénario principal:**
1. L'utilisateur accède au quiz quotidien
2. Affichage de 10 questions QCM
3. L'utilisateur répond aux questions
4. Calcul du score (1 point par bonne réponse)
5. Enregistrement des résultats
6. Affichage des réponses correctes avec explications
7. Attribution des points (max 8 points pour le quiz)

**Points totaux quotidiens:** 10 points (2 lecture + 8 quiz)

#### UC-4: Créer un Groupe Personnalisé
**Acteur:** Utilisateur (Manager)  
**Préconditions:** Utilisateur connecté  
**Scénario principal:**
1. L'utilisateur accède à "My Groups"
2. Clique sur "Create Group"
3. Saisit le nom du groupe (ex: "Church A", "Cell B")
4. Sélectionne les topics à activer pour le groupe
5. Création du groupe
6. L'utilisateur devient manager automatiquement
7. Partage du code d'invitation

#### UC-5: Rejoindre un Groupe
**Acteur:** Utilisateur  
**Préconditions:** Utilisateur connecté, code d'invitation disponible  
**Scénario principal:**
1. L'utilisateur saisit le code d'invitation
2. Demande d'adhésion envoyée au manager
3. Le manager approuve/rejette
4. Si approuvé, l'utilisateur rejoint le groupe
5. Les classements du groupe deviennent visibles

**Scénarios alternatifs:**
- Groupe public → Adhésion automatique
- Manager rejette → Notification de refus

#### UC-6: Défier un Utilisateur (Battle 1v1)
**Acteur:** Utilisateur  
**Préconditions:** Utilisateur connecté, membre d'un groupe, 2 jours écoulés depuis dernière battle  
**Scénario principal:**
1. L'utilisateur A sélectionne un membre du même groupe
2. Envoie une invitation de battle
3. L'utilisateur B reçoit la notification
4. Si B accepte:
   - Battle lancée avec questions du jour
   - Les deux répondent simultanément
   - Calcul des scores
   - Le gagnant reçoit des points bonus
5. Si B ignore (48h):
   - A gagne automatiquement
   - Points bonus attribués à A

**Points bonus:** +5 points pour le gagnant

#### UC-7: Consulter les Classements
**Acteur:** Utilisateur  
**Préconditions:** Utilisateur connecté  
**Scénario principal:**
1. L'utilisateur accède à "Leaderboard"
2. Sélectionne le filtre:
   - Période: Daily / Weekly / Monthly / Yearly
   - Groupe: Worldwide / Country / Custom Group
   - Topic: Rhapsody / Bible / etc.
3. Affichage du classement avec position de l'utilisateur
4. Possibilité de voir le profil des autres utilisateurs

### 3.2 Administrateur

#### UC-8: Uploader un PDF Mensuel
**Acteur:** Admin  
**Préconditions:** Admin connecté, PDF disponible  
**Scénario principal:**
1. Admin accède à "Content Management" → "Monthly Books"
2. Sélectionne le mois, l'année, la version (Kids/Teens/Adult)
3. Upload le PDF
4. Le système extrait le texte et crée 30 entrées (une par jour)
5. Génération automatique des QCM via l'API IA
6. Questions créées avec statut "Pending Validation"

#### UC-9: Valider/Éditer les Questions Générées
**Acteur:** Admin  
**Préconditions:** Questions générées, statut "Pending"  
**Scénario principal:**
1. Admin accède à "Question Validation"
2. Filtre par date/mois/topic
3. Visualise les questions générées pour une date spécifique
4. Pour chaque question:
   - Lit la question et les options
   - Vérifie la réponse correcte
   - Lit l'explication
   - Actions possibles:
     - ✅ Valider (statut → "Validated")
     - ✏️ Éditer (modifier question/réponses/explication)
     - ❌ Supprimer
5. Une fois toutes les questions validées pour une date:
   - Statut du quiz quotidien → "Ready"
   - Le quiz devient disponible à 00:00 du jour J

**Règles métier:**
- Minimum 10 questions validées par jour
- Maximum 15 questions par jour
- Toutes les questions doivent avoir une explication

#### UC-10: Gérer les Topics
**Acteur:** Admin  
**Scénario principal:**
1. Admin crée/édite/supprime un topic
2. Configure les paramètres:
   - Nom du topic
   - Description
   - Image/Logo
   - Actif/Inactif
3. Les groupes peuvent s'abonner aux topics actifs

#### UC-11: Gérer les Groupes
**Acteur:** Admin  
**Scénario principal:**
1. Admin visualise tous les groupes
2. Peut voir les membres de chaque groupe
3. Peut supprimer un groupe si nécessaire
4. Peut voir les statistiques par groupe

### 3.3 Manager de Groupe

#### UC-12: Gérer les Membres du Groupe
**Acteur:** Manager  
**Préconditions:** Utilisateur est manager d'un groupe  
**Scénario principal:**
1. Manager accède à "My Groups" → "Manage Members"
2. Visualise la liste des membres
3. Actions possibles:
   - Voir le profil d'un membre
   - Retirer un membre du groupe
   - Promouvoir un membre en manager (co-manager)
4. Gère les demandes d'adhésion:
   - Approuve/Rejette les demandes en attente

#### UC-13: Gérer les Topics du Groupe
**Acteur:** Manager  
**Scénario principal:**
1. Manager accède à "Group Settings" → "Topics"
2. Visualise les topics disponibles (créés par admin)
3. Active/Désactive les topics pour son groupe
4. Les membres du groupe ne voient que les quiz des topics actifs

---

## 4. Modèles de Données

### 4.1 Topic

```sql
CREATE TABLE tbl_topic (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,              -- "Rhapsody of Realities", "Bible", etc.
    description TEXT,
    image VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### 4.2 Group

```sql
CREATE TABLE tbl_group (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,              -- "Worldwide", "Cameroon", "Church A"
    type ENUM('worldwide', 'country', 'custom') NOT NULL,
    country_code VARCHAR(3),                 -- NULL pour worldwide, ISO code pour country
    manager_id INT,                          -- NULL pour worldwide/country (géré par système)
    code VARCHAR(20) UNIQUE,                 -- Code d'invitation (NULL pour worldwide/country)
    is_public BOOLEAN DEFAULT FALSE,         -- Adhésion automatique si TRUE
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (manager_id) REFERENCES tbl_user(id) ON DELETE SET NULL,
    INDEX idx_type (type),
    INDEX idx_country (country_code)
);
```

### 4.3 Group Member

```sql
CREATE TABLE tbl_group_member (
    id INT PRIMARY KEY AUTO_INCREMENT,
    group_id INT NOT NULL,
    user_id INT NOT NULL,
    role ENUM('member', 'manager', 'co_manager') DEFAULT 'member',
    status ENUM('pending', 'active', 'removed') DEFAULT 'pending',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES tbl_group(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES tbl_user(id) ON DELETE CASCADE,
    UNIQUE KEY unique_member (group_id, user_id),
    INDEX idx_user (user_id),
    INDEX idx_status (status)
);
```

### 4.4 Group Topic Subscription

```sql
CREATE TABLE tbl_group_topic (
    id INT PRIMARY KEY AUTO_INCREMENT,
    group_id INT NOT NULL,
    topic_id INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    subscribed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES tbl_group(id) ON DELETE CASCADE,
    FOREIGN KEY (topic_id) REFERENCES tbl_topic(id) ON DELETE CASCADE,
    UNIQUE KEY unique_subscription (group_id, topic_id)
);
```

### 4.5 Daily Text (Rhapsody)

```sql
CREATE TABLE tbl_daily_text (
    id INT PRIMARY KEY AUTO_INCREMENT,
    topic_id INT NOT NULL,                   -- Rhapsody topic
    version ENUM('kids', 'teens', 'adult') NOT NULL,
    month INT NOT NULL,                      -- 1-12
    year INT NOT NULL,
    day INT NOT NULL,                        -- 1-31
    date DATE NOT NULL,                      -- Date réelle (2025-12-21)
    title VARCHAR(255),
    bible_text TEXT NOT NULL,
    prayer_text TEXT NOT NULL,
    pdf_path VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES tbl_topic(id),
    UNIQUE KEY unique_daily_text (topic_id, version, date),
    INDEX idx_date (date)
);
```

### 4.6 Question Validation Workflow

```sql
CREATE TABLE tbl_question_validation (
    id INT PRIMARY KEY AUTO_INCREMENT,
    question_id INT NOT NULL,
    daily_text_id INT,                       -- NULL si question non-daily
    date DATE NOT NULL,                      -- Date d'utilisation prévue
    status ENUM('pending', 'validated', 'rejected', 'edited') DEFAULT 'pending',
    validated_by INT,                        -- Admin ID
    validated_at TIMESTAMP NULL,
    notes TEXT,                              -- Notes de l'admin
    FOREIGN KEY (question_id) REFERENCES tbl_question(id) ON DELETE CASCADE,
    FOREIGN KEY (daily_text_id) REFERENCES tbl_daily_text(id) ON DELETE SET NULL,
    FOREIGN KEY (validated_by) REFERENCES tbl_user(id) ON DELETE SET NULL,
    INDEX idx_status (status),
    INDEX idx_date (date)
);
```

### 4.7 Daily Quiz (Étendu)

```sql
-- Table existante à étendre
ALTER TABLE tbl_daily_quiz ADD COLUMN topic_id INT;
ALTER TABLE tbl_daily_quiz ADD COLUMN daily_text_id INT;
ALTER TABLE tbl_daily_quiz ADD COLUMN validation_status ENUM('pending', 'ready', 'active', 'completed') DEFAULT 'pending';
ALTER TABLE tbl_daily_quiz ADD FOREIGN KEY (topic_id) REFERENCES tbl_topic(id);
ALTER TABLE tbl_daily_quiz ADD FOREIGN KEY (daily_text_id) REFERENCES tbl_daily_text(id);
```

### 4.8 User Points (Scores Quotidiens)

```sql
CREATE TABLE tbl_user_points (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    group_id INT NOT NULL,
    topic_id INT NOT NULL,
    date DATE NOT NULL,
    reading_points INT DEFAULT 0,            -- Points pour lecture (2)
    quiz_points INT DEFAULT 0,               -- Points pour quiz (0-8)
    battle_points INT DEFAULT 0,            -- Points bonus battle (0 ou 5)
    total_points INT DEFAULT 0,              -- Total du jour (max 10 + 5 = 15)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES tbl_user(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES tbl_group(id) ON DELETE CASCADE,
    FOREIGN KEY (topic_id) REFERENCES tbl_topic(id) ON DELETE CASCADE,
    UNIQUE KEY unique_daily_points (user_id, group_id, topic_id, date),
    INDEX idx_user_date (user_id, date),
    INDEX idx_group_date (group_id, date),
    INDEX idx_topic_date (topic_id, date)
);
```

### 4.9 Battle (1v1)

```sql
CREATE TABLE tbl_battle (
    id INT PRIMARY KEY AUTO_INCREMENT,
    challenger_id INT NOT NULL,               -- Utilisateur qui défie
    opponent_id INT NOT NULL,                -- Utilisateur défié
    group_id INT NOT NULL,
    topic_id INT NOT NULL,
    date DATE NOT NULL,                      -- Date du quiz utilisé
    status ENUM('pending', 'accepted', 'completed', 'expired', 'ignored') DEFAULT 'pending',
    challenger_score INT DEFAULT 0,
    opponent_score INT DEFAULT 0,
    winner_id INT,                          -- NULL si égalité
    questions_id TEXT,                       -- IDs des questions utilisées
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    FOREIGN KEY (challenger_id) REFERENCES tbl_user(id) ON DELETE CASCADE,
    FOREIGN KEY (opponent_id) REFERENCES tbl_user(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES tbl_group(id) ON DELETE CASCADE,
    FOREIGN KEY (topic_id) REFERENCES tbl_topic(id) ON DELETE CASCADE,
    FOREIGN KEY (winner_id) REFERENCES tbl_user(id) ON DELETE SET NULL,
    INDEX idx_challenger (challenger_id),
    INDEX idx_opponent (opponent_id),
    INDEX idx_status (status),
    INDEX idx_date (date)
);
```

### 4.10 Leaderboard (Vues Matérialisées)

```sql
-- Vue pour classement quotidien par groupe/topic
CREATE VIEW vw_daily_leaderboard AS
SELECT 
    up.group_id,
    up.topic_id,
    up.date,
    up.user_id,
    u.name,
    u.profile,
    up.total_points,
    ROW_NUMBER() OVER (PARTITION BY up.group_id, up.topic_id, up.date ORDER BY up.total_points DESC) as rank
FROM tbl_user_points up
JOIN tbl_user u ON up.user_id = u.id;

-- Vue pour classement hebdomadaire
CREATE VIEW vw_weekly_leaderboard AS
SELECT 
    up.group_id,
    up.topic_id,
    YEARWEEK(up.date) as week,
    up.user_id,
    u.name,
    u.profile,
    SUM(up.total_points) as total_points,
    ROW_NUMBER() OVER (PARTITION BY up.group_id, up.topic_id, YEARWEEK(up.date) ORDER BY SUM(up.total_points) DESC) as rank
FROM tbl_user_points up
JOIN tbl_user u ON up.user_id = u.id
GROUP BY up.group_id, up.topic_id, YEARWEEK(up.date), up.user_id;

-- Vue pour classement mensuel
CREATE VIEW vw_monthly_leaderboard AS
SELECT 
    up.group_id,
    up.topic_id,
    YEAR(up.date) as year,
    MONTH(up.date) as month,
    up.user_id,
    u.name,
    u.profile,
    SUM(up.total_points) as total_points,
    ROW_NUMBER() OVER (PARTITION BY up.group_id, up.topic_id, YEAR(up.date), MONTH(up.date) ORDER BY SUM(up.total_points) DESC) as rank
FROM tbl_user_points up
JOIN tbl_user u ON up.user_id = u.id
GROUP BY up.group_id, up.topic_id, YEAR(up.date), MONTH(up.date), up.user_id;
```

---

## 5. Fonctionnalités Détaillées

### 5.1 Système de Points

#### Points Quotidiens (10 points max)
- **Lecture du texte:** 2 points (automatique après lecture)
- **Quiz:** 8 points (1 point par bonne réponse sur 10 questions)
- **Battle gagnée:** +5 points bonus (ajoutés au total quotidien)

#### Calcul des Points
```
Points quotidiens = reading_points + quiz_points + battle_points
Max quotidien = 10 + 5 = 15 points (si battle gagnée)
```

#### Agrégation
- **Hebdomadaire:** Somme des points quotidiens de la semaine
- **Mensuel:** Somme des points quotidiens du mois
- **Annuel:** Somme des points quotidiens de l'année

### 5.2 Système de Groupes Hiérarchiques

#### Groupes Par Défaut (Automatiques)
1. **Worldwide** (`type='worldwide'`)
   - Tous les utilisateurs y appartiennent automatiquement
   - Pas de manager (géré par système)
   - Classement global

2. **Country** (`type='country'`)
   - Un groupe par pays (détecté via IP ou sélection utilisateur)
   - Tous les utilisateurs d'un pays y appartiennent automatiquement
   - Pas de manager (géré par système)
   - Classement par pays

#### Groupes Personnalisés (`type='custom'`)
- Créés par les utilisateurs
- Manager désigné (créateur)
- Code d'invitation unique
- Gestion des membres par le manager
- Abonnement aux topics configurable

### 5.3 Workflow de Validation des Questions

#### États des Questions
1. **Pending** - Générées par IA, en attente de validation
2. **Validated** - Validées par admin, prêtes à être utilisées
3. **Rejected** - Rejetées par admin, à supprimer ou régénérer
4. **Edited** - Modifiées par admin, puis validées

#### Processus de Validation
```
PDF Upload → Text Extraction → QCM Generation → Questions Created (Pending)
                                                      ↓
                                            Admin Reviews
                                                      ↓
                                    Validate / Edit / Delete
                                                      ↓
                                          Questions Validated
                                                      ↓
                                    Daily Quiz Status → Ready
                                                      ↓
                                    Available at 00:00 on Date
```

### 5.4 Système de Battles 1v1

#### Règles
- Un utilisateur peut défier un autre membre du même groupe
- Maximum 1 battle tous les 2 jours
- Questions utilisées: Quiz du jour actuel
- Durée: 48h pour répondre à l'invitation
- Si ignoré après 48h: Le challenger gagne automatiquement

#### Scoring Battle
- Chaque joueur répond aux mêmes questions
- Score = Nombre de bonnes réponses
- Gagnant = Plus haut score (ou challenger si ignoré)
- Points bonus: +5 pour le gagnant

### 5.5 Classements Multi-Dimensionnels

#### Dimensions
- **Période:** Daily / Weekly / Monthly / Yearly / All-Time
- **Groupe:** Worldwide / Country / Custom Group
- **Topic:** Rhapsody / Bible / Love World News / etc.
- **Version:** Kids / Teens / Adult (pour Rhapsody)

#### Calcul des Classements
- Basé sur `tbl_user_points`
- Agrégation par période (SUM des points)
- Ranking avec ROW_NUMBER() ou DENSE_RANK()
- Mise à jour quotidienne (cron job)

---

## 6. Workflows Principaux

### 6.1 Workflow Mensuel: Préparation du Contenu

```
1. Début du mois (ex: 1er Décembre)
   ↓
2. Admin upload le PDF du mois (Décembre 2025 - Adult)
   ↓
3. Système extrait 30 textes quotidiens (1-31 Décembre)
   ↓
4. Pour chaque jour:
   - Extraction du texte biblique
   - Extraction de la prière
   - Création de l'entrée tbl_daily_text
   ↓
5. Génération automatique des QCM (10-15 questions par jour)
   ↓
6. Questions créées avec status='pending'
   ↓
7. Admin valide/édite les questions (avant le jour J)
   ↓
8. Une fois validées, daily_quiz.status='ready'
   ↓
9. À 00:00 du jour J, daily_quiz.status='active'
   ↓
10. Les utilisateurs peuvent lire le texte et répondre au quiz
```

### 6.2 Workflow Quotidien: Expérience Utilisateur

```
00:00 - Nouveau jour commence
   ↓
Texte quotidien disponible
   ↓
Utilisateur lit le texte → +2 points (reading_points)
   ↓
Quiz débloqué
   ↓
Utilisateur répond aux 10 questions → Score calculé (0-8 points)
   ↓
Points enregistrés dans tbl_user_points
   ↓
Classements mis à jour (Daily, Weekly, Monthly)
   ↓
Utilisateur peut défier quelqu'un (si 2 jours écoulés)
   ↓
Battle acceptée → Questions du jour utilisées
   ↓
Gagnant reçoit +5 points bonus
```

### 6.3 Workflow de Génération IA

```
PDF Upload (via Admin Panel)
   ↓
API Call → Laravel API → Python Processor
   ↓
PDF Text Extraction (PyPDF)
   ↓
Text Chunking (1400 words per chunk)
   ↓
For each chunk:
   - Call Ollama API
   - Generate QCM questions (with retries if invalid JSON)
   - Extract: question, options, correct_answer, explanation
   ↓
Questions stored in database (status='pending')
   ↓
Admin notified (new questions to validate)
```

### 6.4 Workflow de Gestion de Groupe

```
Utilisateur crée un groupe
   ↓
Groupe créé (type='custom', manager_id=user_id)
   ↓
Code d'invitation généré
   ↓
Manager sélectionne les topics pour le groupe
   ↓
Autres utilisateurs rejoignent (via code ou demande)
   ↓
Manager approuve/rejette les demandes
   ↓
Membres actifs voient les classements du groupe
   ↓
Membres peuvent défier d'autres membres du groupe
```

---

## 7. Exigences Techniques

### 7.1 Performance

- **Temps de réponse API:** < 500ms (95th percentile)
- **Génération de questions:** < 30s par jour (10-15 questions)
- **Mise à jour des classements:** < 5s (cron job quotidien)
- **Chargement de l'app mobile:** < 2s (écran principal)

### 7.2 Scalabilité

- **Utilisateurs simultanés:** 10,000+
- **Questions par mois:** 30 jours × 3 versions × 15 questions = 1,350 questions
- **Groupes:** Illimité (avec indexation appropriée)
- **Battles simultanées:** 1,000+

### 7.3 Sécurité

- **Authentification:** Firebase Auth (JWT tokens)
- **API Security:** Laravel Sanctum (mobile), API keys (admin)
- **Validation des données:** Côté serveur obligatoire
- **Permissions:** RBAC pour admins (full/partial access)
- **Rate Limiting:** Protection contre abus (battles, quiz)

### 7.4 Disponibilité

- **Uptime cible:** 99.5%
- **Backup base de données:** Quotidien (rétention 30 jours)
- **Monitoring:** Logs d'erreurs, métriques de performance
- **Alertes:** Notification en cas d'échec critique

### 7.5 Compatibilité

- **Mobile:** iOS 13+, Android 8+
- **Navigateurs admin:** Chrome, Firefox, Safari (dernières versions)
- **PDF:** Format PDF 1.4+ (texte extractible)

---

## 8. Plan de Développement

### Phase 1: Fondations (Semaines 1-4)

#### Sprint 1: Modèles de Données
- [ ] Créer les nouvelles tables (Topic, Group, GroupMember, etc.)
- [ ] Migrations de base de données
- [ ] Seeders pour données de test
- [ ] Documentation des modèles

#### Sprint 2: API Backend - Groupes
- [ ] Endpoints CRUD pour Groupes
- [ ] Gestion des membres (join, leave, remove)
- [ ] Gestion des topics par groupe
- [ ] Tests unitaires

#### Sprint 3: API Backend - Topics
- [ ] Endpoints CRUD pour Topics
- [ ] Intégration avec groupes
- [ ] Tests unitaires

#### Sprint 4: API Backend - Daily Texts
- [ ] Endpoints pour Daily Texts
- [ ] Upload manuel des textes quotidiens (sans extraction PDF pour l'instant)
- [ ] Association texte → questions (questions manuelles)
- [ ] Tests unitaires

**Note sur les données factices:**
- Pour le développement initial, les questions seront créées manuellement via l'interface admin
- Les textes quotidiens peuvent être saisis manuellement ou uploadés comme texte brut
- Un système de templates de questions peut être créé pour faciliter la création manuelle
- Les données de test incluront des questions factices pour tous les jours du mois

### Phase 2: Mobile App - Groupes et Topics (Semaines 5-8)

**Note:** La génération IA de QCM est repoussée à la Phase 5. Pour le développement initial, nous utiliserons des questions factices/manuelles.

#### Sprint 5: UI Mobile - Groupes
- [ ] Écran "My Groups"
- [ ] Création de groupe
- [ ] Rejoindre un groupe (code/demande)
- [ ] Gestion des membres (manager)

#### Sprint 6: UI Mobile - Topics
- [ ] Sélection de topics par groupe
- [ ] Filtrage des quiz par topic
- [ ] Affichage des topics actifs

#### Sprint 7: UI Mobile - Daily Text
- [ ] Écran de lecture du texte quotidien
- [ ] Tracking de la lecture
- [ ] Attribution des points de lecture
- [ ] Déblocage du quiz

### Phase 3: Système de Points et Classements (Semaines 9-12)

#### Sprint 8: UI Mobile - Groupes
- [ ] Écran "My Groups"
- [ ] Création de groupe
- [ ] Rejoindre un groupe (code/demande)
- [ ] Gestion des membres (manager)

#### Sprint 9: UI Mobile - Topics
- [ ] Sélection de topics par groupe
- [ ] Filtrage des quiz par topic
- [ ] Affichage des topics actifs

#### Sprint 10: UI Mobile - Daily Text
- [ ] Écran de lecture du texte quotidien
- [ ] Tracking de la lecture
- [ ] Attribution des points de lecture
- [ ] Déblocage du quiz

#### Sprint 8: Calcul des Points
- [ ] Enregistrement des points quotidiens
- [ ] Calcul automatique (lecture + quiz + battle)
- [ ] Agrégation hebdomadaire/mensuelle/annuelle
- [ ] Tests de calcul

#### Sprint 9: Classements
- [ ] Vues matérialisées pour classements
- [ ] API endpoints pour classements (multi-filtres)
- [ ] UI Mobile - Leaderboards
- [ ] Mise à jour quotidienne (cron)

#### Sprint 10: Battles 1v1
- [ ] Modèle de données Battle
- [ ] API endpoints (challenge, accept, complete)
- [ ] UI Mobile - Invitation et réponse
- [ ] Calcul des scores et attribution des points bonus
- [ ] Expiration automatique (48h)

### Phase 4: Workflow de Validation Admin (Semaines 13-16)

**Note:** Utilisation de questions manuelles/factices pour le développement initial.

#### Sprint 11: Interface Admin - Gestion Questions
- [ ] Interface admin pour créer/éditer des questions manuellement
- [ ] Association questions → Daily Text
- [ ] Édition des questions
- [ ] Suppression
- [ ] Bulk operations
- [ ] Filtres et recherche

#### Sprint 12: Workflow de Validation
- [ ] Statut des questions (draft, pending, validated, active)
- [ ] Logique de validation complète
- [ ] Passage à "ready" quand toutes validées
- [ ] Activation automatique à 00:00
- [ ] Tests end-to-end

### Phase 5: Optimisation et Tests (Semaines 17-18)

#### Sprint 13: Performance
- [ ] Optimisation des requêtes SQL
- [ ] Cache des classements
- [ ] Indexation des tables
- [ ] Load testing

#### Sprint 14: Tests et Documentation
- [ ] Tests d'intégration complets
- [ ] Tests de charge
- [ ] Documentation utilisateur
- [ ] Documentation technique

### Phase 6: Génération IA de QCM (Semaines 19-24) - OPTIONNEL

**Note:** Cette phase peut être développée en parallèle ou après les phases précédentes. Pour le développement initial, utiliser des questions manuelles.

#### Sprint 15: Intégration PDF → QCM (IA)
- [ ] Améliorer le processeur PDF Python
- [ ] API Laravel pour recevoir les questions générées
- [ ] Intégration Ollama
- [ ] Stockage dans la base de données
- [ ] Statut "pending" par défaut

#### Sprint 16: Workflow IA - Validation
- [ ] Interface admin pour valider les questions générées par IA
- [ ] Édition des questions IA
- [ ] Rejet/Suppression avec régénération optionnelle
- [ ] Bulk validation
- [ ] Comparaison questions IA vs manuelles

#### Sprint 14: Performance
- [ ] Optimisation des requêtes SQL
- [ ] Cache des classements
- [ ] Indexation des tables
- [ ] Load testing

#### Sprint 15: Tests et Documentation
- [ ] Tests d'intégration complets
- [ ] Tests de charge
- [ ] Documentation utilisateur
- [ ] Documentation technique

#### Sprint 17: Déploiement et Monitoring
- [ ] Configuration production
- [ ] Monitoring et alertes
- [ ] Backup automatique
- [ ] Documentation de déploiement

---

## 8.1 Données Factices pour le Développement Initial

### 8.1.1 Stratégie de Développement

**Approche:** Utiliser des questions manuelles/factices pour permettre le développement et les tests sans dépendre de la génération IA.

### 8.1.2 Création Manuelle de Questions

**Via Interface Admin:**
1. Admin accède à "Questions" → "Add Question"
2. Sélectionne le Daily Text associé
3. Crée manuellement:
   - Question (texte)
   - 4 options de réponse
   - Réponse correcte
   - Explication
4. Associe la question à une date spécifique
5. Statut initial: "draft" ou "pending"

**Templates de Questions:**
- Créer des templates réutilisables pour accélérer la création
- Exemples de structures de questions par type de texte

### 8.1.3 Données de Test

**Seeders à créer:**
- 30 Daily Texts (un par jour) pour un mois de test
- 10-15 questions par jour (300-450 questions totales)
- 3-5 groupes de test (Worldwide, Country, Custom)
- 10-20 utilisateurs de test
- Points et classements de test

**Format des données factices:**
```json
{
  "daily_text": {
    "date": "2024-12-21",
    "bible_text": "Sample bible text...",
    "prayer_text": "Sample prayer text...",
    "version": "adult"
  },
  "questions": [
    {
      "question": "What is the main theme of today's text?",
      "options": [
        "Option A",
        "Option B",
        "Option C",
        "Option D"
      ],
      "correct_answer": 0,
      "explanation": "Explanation of the correct answer..."
    }
    // ... 9 more questions
  ]
}
```

### 8.1.4 Migration vers IA (Phase 6)

**Quand l'IA sera implémentée:**
- Les questions manuelles existantes resteront dans la base de données
- Les nouvelles questions générées par IA auront un flag `source: 'ai'` vs `source: 'manual'`
- Possibilité de remplacer progressivement les questions manuelles par des questions IA
- Workflow de validation permettra de comparer questions manuelles vs IA

### 8.1.5 Avantages de cette Approche

✅ **Développement parallèle:** L'équipe peut développer les autres fonctionnalités sans attendre l'IA  
✅ **Tests complets:** Permet de tester tous les workflows avec des données réalistes  
✅ **Flexibilité:** Les admins peuvent toujours créer des questions manuelles même après l'implémentation IA  
✅ **Fallback:** Si l'IA échoue, possibilité de créer des questions manuelles rapidement  

---

## 9. Glossaire

- **QCM:** Question à Choix Multiples
- **Topic:** Thème de quiz (Rhapsody, Bible, etc.)
- **Group:** Groupe d'utilisateurs (Worldwide, Country, Custom)
- **Manager:** Gestionnaire d'un groupe personnalisé
- **Daily Text:** Texte biblique quotidien du livre Rhapsody
- **Battle:** Défi 1v1 entre deux utilisateurs
- **Points:** Système de récompense basé sur l'assiduité et la performance

---

## 10. Annexes

### 10.1 Schémas de Base de Données

Voir section 4 pour les schémas SQL complets.

### 10.2 API Endpoints

**À documenter:**
- `/api/groups` - Gestion des groupes
- `/api/topics` - Gestion des topics
- `/api/daily-texts` - Textes quotidiens
- `/api/questions/validate` - Validation des questions
- `/api/battles` - Battles 1v1
- `/api/leaderboard` - Classements
- `/api/user-points` - Points utilisateur

### 10.3 Diagrammes de Séquence

**À créer:**
- Workflow de validation des questions
- Workflow de battle 1v1
- Workflow quotidien utilisateur

---

**Document créé le:** Décembre 2024  
**Dernière mise à jour:** Décembre 2024  
**Version:** 1.0

