# Cahier de Charges - Plateforme Rhapsodie Quiz IA

**Version:** 2.0  
**Date:** Décembre 2024  
**Projet:** Plateforme de Quiz Mobile - Rhapsody of Realities & Foundation School

---

## Table des Matières

1. [Vue d'ensemble du Projet](#1-vue-densemble-du-projet)
2. [Topics Principaux](#2-topics-principaux)
3. [Architecture du Système](#3-architecture-du-système)
4. [Cas d'Usage](#4-cas-dusage)
5. [Modèles de Données](#5-modèles-de-données)
6. [Fonctionnalités Détaillées](#6-fonctionnalités-détaillées)
7. [Workflows Principaux](#7-workflows-principaux)
8. [Exigences Techniques](#8-exigences-techniques)
9. [Plan de Développement](#9-plan-de-développement)

---

## 1. Vue d'ensemble du Projet

### 1.1 Objectif

Créer une plateforme mobile de quiz/gaming éducative centrée sur deux piliers principaux :
1. **Rhapsody of Realities** - Contenu dévotionnel quotidien
2. **Foundation School** - Programme de formation ministérielle

La plateforme offre des quiz interactifs, un système de récompenses, des classements hiérarchiques et la gestion de groupes (églises, cellules, régions).

### 1.2 Contexte Métier

#### 1.2.1 Rhapsody of Realities (Rhapsodie des Réalités)

Livre dévotionnel mensuel publié en trois versions :
- **Kids** (Enfants) - 5-12 ans
- **Teens** (Adolescents) - 13-19 ans  
- **Adult** (Adultes) - 20+ ans

Chaque édition mensuelle contient :
- Un texte biblique quotidien avec méditation
- Une confession de foi quotidienne
- Une prière quotidienne
- 30-31 jours de contenu (un par jour du mois)

#### 1.2.2 Foundation School

Programme de **formation/training** pour les nouveaux membres de l'église. C'est un parcours d'apprentissage **auto-rythmé** (self-paced), sans contrainte de temps.

**Niveaux de Foundation School :**
- **Foundation Class 1** - Introduction à la foi chrétienne
- **Foundation Class 2** - Fondements bibliques approfondis
- **Foundation Class 3** - Ministère et service
- **Foundation Class 4** - Leadership et multiplication

**Caractéristiques du Training :**
- Progression **auto-rythmée** (pas de notion de semaine/temps)
- Leçons vidéo/audio du pasteur
- Manuel d'étude avec questions de compréhension
- Quiz de validation des connaissances (pas d'examen chronométré)
- Certificat de complétion par niveau (optionnel)

### 1.3 Portée du Projet

**Phase 1 (Focus Initial) - Rhapsody Quiz:**
- Topic "Rhapsody of Realities" (Kids, Teens, Adult)
- Quiz quotidiens basés sur les textes du jour
- Système de points et récompenses
- Classements par groupe (Worldwide, Country, Custom)
- Battles 1v1 entre membres du même groupe

**Phase 2 (Extension) - Foundation School:**
- Topic "Foundation School" (Classes 1-4)
- Quiz par module/chapitre
- Progression par niveau (débloquage séquentiel)
- Examens de certification
- Suivi de progression pour les pasteurs/leaders

**Phase 3 (Gamification Avancée):**
- Badges et récompenses visuelles
- Défis hebdomadaires/mensuels
- Tournois inter-groupes
- Récompenses réelles (optionnel)

**Phase 4 (IA - Optionnel):**
- Génération automatique de QCM via IA (Ollama)
- Traitement PDF/vidéo automatique
- Questions adaptatives selon le niveau de l'utilisateur

---

## 2. Topics Principaux

### 2.1 Structure Hiérarchique

```
TOPICS
├── Foundation School
│   └── Categories (Modules)
│       ├── Module 1: Contenu + Quiz
│       ├── Module 2: Contenu + Quiz
│       ├── Module 3: Contenu + Quiz
│       └── ...
│
└── Rhapsody
    └── Categories (Années)
        └── Year (2024, 2025, ...)
            └── Month (January, February, ...)
                └── Day (1, 2, 3, ... 31)
                    └── Texte + Quiz

FEATURE GLOBALE
└── Contest (Daily Text + Quiz)
    └── Disponible pour TOUS les utilisateurs
```

### 2.2 Rhapsody of Realities

| Attribut | Valeur |
|----------|--------|
| **ID Topic** | `rhapsody` |
| **Nom** | Rhapsody of Realities |
| **Type** | Quotidien |
| **Versions** | Kids, Teens, Adult |
| **Structure** | Year → Month → Day |
| **Contenu/Jour** | Texte + Quiz |
| **Questions/Quiz** | 10 questions |
| **Points Max/Jour** | 10 pts (2 lecture + 8 quiz) |

**Hiérarchie des Catégories Rhapsody :**
```
Rhapsody (Topic)
├── 2024 (Year)
│   ├── January
│   │   ├── Day 1: Texte + Quiz
│   │   ├── Day 2: Texte + Quiz
│   │   └── ...
│   ├── February
│   └── ...
├── 2025 (Year)
│   ├── January
│   └── ...
└── ...
```

### 2.3 Foundation School

| Attribut | Valeur |
|----------|--------|
| **ID Topic** | `foundation_school` |
| **Nom** | Foundation School |
| **Type** | Training / Formation auto-rythmée |
| **Structure** | Modules (= Categories) |
| **Contenu/Module** | Texte/Vidéo/Audio + Quiz |
| **Questions/Module** | 10-15 questions de compréhension |
| **Contrainte temps** | ❌ Aucune (self-paced) |

**Hiérarchie des Catégories Foundation School :**
```
Foundation School (Topic)
├── Module 1: L'assurance du salut
│   └── Contenu + Quiz
├── Module 2: La nouvelle création
│   └── Contenu + Quiz
├── Module 3: La vie de prière
│   └── Contenu + Quiz
├── Module 4: L'étude de la Parole
│   └── Contenu + Quiz
├── Module 5: Le Saint-Esprit
│   └── Contenu + Quiz
├── Module 6: L'eau du baptême
│   └── Contenu + Quiz
├── Module 7: La communion fraternelle
│   └── Contenu + Quiz
├── Module 8: Donner et recevoir
│   └── Contenu + Quiz
├── Module 9: Le témoignage
│   └── Contenu + Quiz
└── ... (autres modules)
```

**Note:** 
- Chaque Module = 1 Category dans le système
- L'utilisateur progresse à son rythme (self-paced)
- Pas de notion de "classe" ou "niveau" - juste des modules séquentiels

### 2.4 Modes de Jeu

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           MODES DE JEU                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. SOLO MODE                                                           │
│     └── Utilisateur joue seul                                           │
│         ├── Choisit Topic: Foundation School OU Rhapsody                │
│         ├── Choisit Category:                                           │
│         │   ├── FS: Module 1, Module 2, ...                            │
│         │   └── Rhapsody: Year → Month → Day                           │
│         └── Répond au quiz                                              │
│                                                                          │
│  2. 1v1 MODE                                                            │
│     └── Défi entre 2 utilisateurs                                       │
│         ├── Challenger choisit Topic + Category                        │
│         ├── Envoie invitation à l'adversaire                           │
│         ├── Les deux répondent aux mêmes questions                     │
│         └── Le meilleur score gagne                                     │
│                                                                          │
│  3. MULTIPLAYER MODE (Group Battle)                                     │
│     └── Battle en groupe                                                │
│         ├── Group Owner crée le groupe                                 │
│         ├── Invite des utilisateurs à rejoindre                        │
│         ├── Choisit Topic + Category pour la battle                    │
│         ├── Tous les membres répondent aux mêmes questions             │
│         └── Classement du groupe                                        │
│                                                                          │
│  4. CONTEST (Daily Challenge)                                           │
│     └── Challenge quotidien pour TOUS                                   │
│         ├── Basé sur Rhapsody du jour                                  │
│         ├── Disponible pour tous les utilisateurs                      │
│         └── Classement global                                           │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

#### Solo Mode (Practice Mode)

**Concept:** Mode d'entraînement où l'utilisateur pratique sur un topic avec des questions aléatoires.

| Attribut | Valeur |
|----------|--------|
| **Joueurs** | 1 |
| **Sélection** | Topic uniquement (pas de category) |
| **Topics** | Rhapsody, Foundation School (+ futurs: Evangelism, Teaching, Apologetics) |
| **Questions** | Sélection aléatoire parmi TOUTES les categories du topic |
| **Nombre de questions** | Choix utilisateur: 5, 10, 15, ou 20 |
| **Temps par question** | Choix utilisateur: 10s, 15s, 30s, etc. |
| **Récompense** | +1 coin si 100% ET nombre de questions > 5 |

**Flux Solo Mode:**
```
┌──────────────────────────────────────────────────────────────────────┐
│  1. Sélection Topic                                                  │
│     ┌─────────────┐ ┌─────────────┐                                 │
│     │  Rhapsody   │ │ Foundation  │  (+ futurs topics)              │
│     └─────────────┘ └─────────────┘                                 │
│                                                                       │
│  2. Configuration                                                    │
│     • Nombre de questions: [5] [10] [15] [20]                       │
│     • Temps par question:  [10s] [15s] [30s] [60s]                  │
│                                                                       │
│  3. Quiz                                                             │
│     • Questions aléatoires de TOUTES les categories du topic        │
│     • Rhapsody: toutes les années/mois/jours                        │
│     • Foundation: tous les modules (sans contenu, quiz direct)      │
│                                                                       │
│  4. Résultat                                                         │
│     • Score affiché                                                  │
│     • +1 coin si 100% ET questions > 5                              │
│     • [Rejouer] [Changer Topic]                                      │
└──────────────────────────────────────────────────────────────────────┘
```

**Notes importantes:**
- Solo Mode est SÉPARÉ des quiz spécifiques (Rhapsody Day, Foundation Module)
- Pour Rhapsody: accès à TOUTES les questions (toutes années/mois)
- Pour Foundation: SKIP le contenu pédagogique, quiz direct
- 5 questions = entraînement léger, pas de coin reward
- 10+ questions = pratique sérieuse, coin reward possible

#### 1v1 Mode

| Attribut | Valeur |
|----------|--------|
| **Joueurs** | 2 |
| **Initiation** | Challenger envoie invitation |
| **Questions** | Mêmes questions pour les 2 |
| **Gagnant** | Meilleur score |
| **Reward** | Points bonus pour le gagnant |

#### Multiplayer Mode (Group Battle)

| Attribut | Valeur |
|----------|--------|
| **Joueurs** | 2+ (groupe) |
| **Création** | Group Owner crée le groupe |
| **Invitation** | Owner invite des membres |
| **Battle** | Tous répondent aux mêmes questions |
| **Classement** | Ranking dans le groupe |

#### Contest (Daily Challenge)

| Attribut | Valeur |
|----------|--------|
| **Joueurs** | Tous les utilisateurs |
| **Fréquence** | Quotidien |
| **Contenu** | Rhapsody du jour |
| **Classement** | Global |

### 2.5 Comparaison des Topics

| Caractéristique | Rhapsody | Foundation School |
|----------------|----------|-------------------|
| **Type** | Quiz quotidien | Training / Formation |
| **Structure Categories** | Year → Month → Day | Modules |
| **Contenu** | Texte + Quiz par jour | Contenu + Quiz par module |
| **Progression** | Quotidienne | Auto-rythmée (self-paced) |
| **Accès** | Tous les utilisateurs | Tous les utilisateurs |
| **Répétition** | Non (1 quiz/jour) | Oui (réviser les modules) |
| **Contrainte temps** | Oui (quotidien) | ❌ Non |
| **Objectif** | Engagement quotidien | Apprentissage |

### 2.6 Topics Futurs (Post-MVP)

Les topics suivants seront ajoutés dans les versions ultérieures :
- **Bible** - Quiz sur les livres bibliques
- **Heroes of Faith** - Personnages bibliques et historiques
- **Love World News** - Actualités du ministère
- **History** - Histoire de l'église

---

## 3. Architecture du Système

### 3.1 Architecture Générale

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

### 3.2 Composants Principaux

#### 3.2.1 Application Mobile (Flutter)
- **Framework:** Flutter 3.10+
- **Architecture:** BLoC/Cubit Pattern
- **Authentification:** Firebase Auth (Google, Apple)
- **Base de données locale:** Hive
- **API Client:** HTTP avec gestion d'erreurs

#### 3.2.2 Panel d'Administration (CodeIgniter)
- **Framework:** CodeIgniter 3.x
- **Infrastructure:** Docker (MySQL, PHP, Nginx)
- **Base de données:** MySQL (`elite_quiz_237`)
- **Port:** 8080 (configurable)

#### 3.2.3 API de Génération IA (Laravel) - Phase 4
- **Framework:** Laravel 12
- **Authentification:** Laravel Sanctum
- **Base de données:** SQLite/MySQL
- **IA:** Ollama (local LLM)

#### 3.2.4 Processeur PDF (Python) - Phase 4
- **Bibliothèques:** PyPDF, Ollama
- **Interface:** Streamlit/Tkinter/CLI
- **Sortie:** JSON/YAML

### 3.3 Base de Données

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

## 4. Cas d'Usage

### 4.1 Utilisateur Final (Mobile App) - Rhapsody

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

**Points:** 5 points pour la lecture

#### UC-3: Répondre au Quiz Quotidien
**Acteur:** Utilisateur  
**Préconditions:** Texte quotidien lu, questions validées par admin  
**Scénario principal:**
1. L'utilisateur accède au quiz quotidien
2. Affichage de 5 questions QCM
3. L'utilisateur répond aux questions
4. Calcul du score (1 point par bonne réponse)
5. Enregistrement des résultats
6. Affichage des réponses correctes avec explications
7. Attribution des points (max 5 points pour le quiz)

**Points totaux quotidiens:** 10 points (5 lecture + 5 quiz)

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

### 4.2 Utilisateur Final (Mobile App) - Foundation School

#### UC-7: Accéder à Foundation School
**Acteur:** Utilisateur inscrit à Foundation School  
**Préconditions:** Utilisateur connecté, inscrit par son pasteur/leader  
**Scénario principal:**
1. L'utilisateur accède à l'onglet "Foundation School"
2. Affichage de sa classe actuelle (ex: Foundation Class 1)
3. Liste des modules visibles:
   - Modules complétés (vert, badge checkmark)
   - Module actuel (jaune, accessible)
   - Modules verrouillés (gris, cadenas)
4. L'utilisateur sélectionne le module actuel
5. Affichage du contenu pédagogique (texte, vidéo, audio)

#### UC-8: Compléter un Module Foundation School
**Acteur:** Utilisateur  
**Préconditions:** Module débloqué  
**Scénario principal:**
1. L'utilisateur accède au module (contenu: texte, vidéo, audio)
2. L'utilisateur étudie le contenu à son rythme
3. Une fois le contenu étudié, le quiz de compréhension est disponible
4. L'utilisateur répond aux 10-15 questions
5. Si réponses correctes suffisantes:
   - Module marqué comme "Complété"
   - Module suivant débloqué
   - Points attribués
6. Sinon:
   - Affichage des réponses correctes avec explications
   - Possibilité de réessayer immédiatement
   - Possibilité de revoir le contenu

**Caractéristiques:**
- ❌ Pas de limite de tentatives
- ❌ Pas de contrainte de temps
- ✅ L'utilisateur avance à son propre rythme
- ✅ Peut réviser les modules déjà complétés

#### UC-9: Terminer une Classe Foundation School
**Acteur:** Utilisateur  
**Préconditions:** Tous les modules de la classe complétés  
**Scénario principal:**
1. L'utilisateur complète le dernier module
2. Notification de félicitations "Classe terminée!"
3. Classe suivante automatiquement débloquée
4. Certificat de complétion disponible (optionnel, téléchargeable)
5. Notification au pasteur/leader (optionnel)

**Note:** Pas d'examen final chronométré. La validation se fait par la complétion de tous les modules.

#### UC-10: Consulter sa Progression Foundation School
**Acteur:** Utilisateur  
**Scénario principal:**
1. L'utilisateur accède à "Ma Progression"
2. Vue d'ensemble:
   - Classe actuelle et progression (ex: FC1 - 70%)
   - Modules complétés vs restants
   - Temps total d'apprentissage (optionnel)
3. Historique des modules complétés
4. Certificats obtenus

### 4.3 Administrateur (Admin Panel)

#### UC-11: Uploader un PDF Rhapsody Mensuel
**Acteur:** Admin  
**Préconditions:** Admin connecté, PDF disponible  
**Scénario principal:**
1. Admin accède à "Content Management" → "Monthly Books"
2. Sélectionne le mois, l'année, la version (Kids/Teens/Adult)
3. Upload le PDF
4. Le système extrait le texte et crée 30 entrées (une par jour)
5. Génération automatique des QCM via l'API IA
6. Questions créées avec statut "Pending Validation"

#### UC-12: Valider/Éditer les Questions Générées
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

#### UC-13: Gérer les Topics (Rhapsody & Foundation School)
**Acteur:** Admin  
**Scénario principal:**
1. Admin crée/édite/supprime un topic
2. Configure les paramètres:
   - Nom du topic
   - Description
   - Image/Logo
   - Actif/Inactif
3. Les groupes peuvent s'abonner aux topics actifs

#### UC-14: Gérer les Groupes
**Acteur:** Admin  
**Scénario principal:**
1. Admin visualise tous les groupes
2. Peut voir les membres de chaque groupe
3. Peut supprimer un groupe si nécessaire
4. Peut voir les statistiques par groupe

#### UC-15: Gérer le Contenu Foundation School
**Acteur:** Admin  
**Scénario principal:**
1. Admin accède à "Foundation School" → "Manage Classes"
2. Pour chaque classe (FC1, FC2, FC3, FC4):
   - Créer/éditer les modules
   - Ajouter le contenu pédagogique (texte, liens vidéo, audio)
   - Créer les questions du quiz du module
   - Définir le seuil de réussite
3. Créer l'examen final de la classe:
   - Sélectionner les questions parmi les modules
   - Définir le temps limite
   - Définir le seuil de réussite (75% par défaut)
4. Publier la classe (active/inactive)

#### UC-16: Inscrire des Utilisateurs à Foundation School
**Acteur:** Admin ou Pasteur/Leader  
**Scénario principal:**
1. Admin/Pasteur accède à "Foundation School" → "Inscriptions"
2. Recherche un utilisateur (nom, email, téléphone)
3. Inscrit l'utilisateur à Foundation School:
   - Sélectionne la classe de départ (généralement FC1)
   - Assigne un groupe/église
4. L'utilisateur reçoit une notification
5. L'accès Foundation School est activé sur son compte

### 4.4 Pasteur/Leader de Groupe

#### UC-17: Gérer les Membres du Groupe
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

#### UC-18: Gérer les Topics du Groupe
**Acteur:** Manager  
**Scénario principal:**
1. Manager accède à "Group Settings" → "Topics"
2. Visualise les topics disponibles (créés par admin)
3. Active/Désactive les topics pour son groupe
4. Les membres du groupe ne voient que les quiz des topics actifs

#### UC-19: Suivre la Progression Foundation School du Groupe
**Acteur:** Pasteur/Leader  
**Préconditions:** Pasteur assigné à un groupe  
**Scénario principal:**
1. Pasteur accède à "Foundation School" → "Suivi Groupe"
2. Vue tableau de bord:
   - Nombre d'inscrits par classe (FC1, FC2, FC3, FC4)
   - Progression moyenne par classe
   - Membres en retard (pas d'activité depuis X jours)
   - Membres prêts pour l'examen final
3. Sélectionne un membre pour voir son détail
4. Actions possibles:
   - Envoyer un rappel/encouragement
   - Autoriser une nouvelle tentative d'examen
   - Valider manuellement un module (cas exceptionnel)

#### UC-20: Générer un Rapport Foundation School
**Acteur:** Pasteur/Leader ou Admin  
**Scénario principal:**
1. Accède à "Foundation School" → "Rapports"
2. Sélectionne les filtres:
   - Période (mois, trimestre, année)
   - Groupe/Église
   - Classe (FC1-FC4)
3. Génère le rapport avec:
   - Nombre de diplômés
   - Taux de complétion par module
   - Score moyen par module
   - Temps moyen de complétion
   - Liste des diplômés avec dates
4. Export en PDF ou Excel

---

## 5. Modèles de Données

### 5.1 Topics

```sql
CREATE TABLE tbl_topic (
    id INT PRIMARY KEY AUTO_INCREMENT,
    slug VARCHAR(50) UNIQUE NOT NULL,        -- "rhapsody", "foundation_school"
    name VARCHAR(255) NOT NULL,              -- "Rhapsody of Realities", "Foundation School"
    description TEXT,
    image VARCHAR(255),
    topic_type ENUM('daily', 'training') NOT NULL,
    -- 'daily' = Rhapsody (Year → Month → Day structure)
    -- 'training' = Foundation School (Modules séquentiels)
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Seed data
INSERT INTO tbl_topic (slug, name, topic_type, description) VALUES
('rhapsody', 'Rhapsody of Realities', 'daily', 'Quiz quotidiens basés sur Rhapsody'),
('foundation_school', 'Foundation School', 'training', 'Formation ministérielle');
```

### 5.2 Categories (Structure Unifiée)

```sql
-- Categories = Modules pour Foundation School, Year/Month pour Rhapsody
CREATE TABLE tbl_category (
    id INT PRIMARY KEY AUTO_INCREMENT,
    topic_id INT NOT NULL,
    parent_id INT NULL,                      -- Pour hiérarchie (Year → Month → Day)
    slug VARCHAR(100) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    image VARCHAR(255),
    order_index INT DEFAULT 0,               -- Ordre d'affichage
    
    -- Pour Foundation School (Training)
    content_text TEXT,                       -- Contenu pédagogique
    content_video_url VARCHAR(500),          -- Lien vidéo
    content_audio_url VARCHAR(500),          -- Lien audio
    
    -- Pour Rhapsody (Daily)
    year INT NULL,                           -- 2024, 2025, ...
    month INT NULL,                          -- 1-12
    day INT NULL,                            -- 1-31
    daily_text TEXT,                         -- Texte du jour
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (topic_id) REFERENCES tbl_topic(id),
    FOREIGN KEY (parent_id) REFERENCES tbl_category(id),
    INDEX idx_topic (topic_id),
    INDEX idx_parent (parent_id),
    INDEX idx_date (year, month, day)
);

-- Exemples Foundation School (Modules = Categories)
INSERT INTO tbl_category (topic_id, slug, name, order_index) VALUES
(2, 'module-1', 'L''assurance du salut', 1),
(2, 'module-2', 'La nouvelle création', 2),
(2, 'module-3', 'La vie de prière', 3);

-- Exemples Rhapsody (Year → Month → Day)
-- Year
INSERT INTO tbl_category (topic_id, slug, name, year) VALUES
(1, '2025', '2025', 2025);
-- Month (parent = Year)
INSERT INTO tbl_category (topic_id, parent_id, slug, name, year, month) VALUES
(1, 1, '2025-01', 'January 2025', 2025, 1);
-- Day (parent = Month)
INSERT INTO tbl_category (topic_id, parent_id, slug, name, year, month, day, daily_text) VALUES
(1, 2, '2025-01-01', 'January 1, 2025', 2025, 1, 1, 'Texte du jour...');
```

### 5.3 Questions (Unifiées pour tous les Topics)

```sql
-- Questions liées à une Category (Module ou Day)
CREATE TABLE tbl_question (
    id INT PRIMARY KEY AUTO_INCREMENT,
    category_id INT NOT NULL,                -- Lien vers tbl_category
    question TEXT NOT NULL,
    option_a VARCHAR(500) NOT NULL,
    option_b VARCHAR(500) NOT NULL,
    option_c VARCHAR(500),
    option_d VARCHAR(500),
    correct_answer ENUM('a', 'b', 'c', 'd') NOT NULL,
    explanation TEXT,                        -- Explication de la réponse
    order_index INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (category_id) REFERENCES tbl_category(id) ON DELETE CASCADE,
    INDEX idx_category (category_id)
);
```

### 5.4 Modes de Jeu - Tables

```sql
-- =====================================================
-- SOLO MODE (pas de table spécifique, utilise tbl_user_progress)
-- =====================================================

-- =====================================================
-- 1v1 MODE
-- =====================================================
CREATE TABLE tbl_battle_1v1 (
    id INT PRIMARY KEY AUTO_INCREMENT,
    challenger_id INT NOT NULL,              -- Utilisateur qui défie
    opponent_id INT NOT NULL,                -- Utilisateur défié
    topic_id INT NOT NULL,                   -- Topic choisi
    category_id INT NOT NULL,                -- Category choisie
    status ENUM('pending', 'accepted', 'in_progress', 'completed', 'declined', 'expired') DEFAULT 'pending',
    challenger_score INT NULL,
    opponent_score INT NULL,
    winner_id INT NULL,                      -- NULL si égalité
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    expires_at TIMESTAMP NULL,               -- Expiration de l'invitation
    
    FOREIGN KEY (challenger_id) REFERENCES tbl_user(id) ON DELETE CASCADE,
    FOREIGN KEY (opponent_id) REFERENCES tbl_user(id) ON DELETE CASCADE,
    FOREIGN KEY (topic_id) REFERENCES tbl_topic(id),
    FOREIGN KEY (category_id) REFERENCES tbl_category(id),
    FOREIGN KEY (winner_id) REFERENCES tbl_user(id) ON DELETE SET NULL,
    INDEX idx_challenger (challenger_id),
    INDEX idx_opponent (opponent_id),
    INDEX idx_status (status)
);

-- =====================================================
-- MULTIPLAYER MODE (Group Battle)
-- =====================================================
CREATE TABLE tbl_group (
    id INT PRIMARY KEY AUTO_INCREMENT,
    owner_id INT NOT NULL,                   -- Créateur du groupe
    name VARCHAR(255) NOT NULL,
    description TEXT,
    code VARCHAR(20) UNIQUE,                 -- Code d'invitation
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (owner_id) REFERENCES tbl_user(id) ON DELETE CASCADE
);

CREATE TABLE tbl_group_member (
    id INT PRIMARY KEY AUTO_INCREMENT,
    group_id INT NOT NULL,
    user_id INT NOT NULL,
    role ENUM('owner', 'admin', 'member') DEFAULT 'member',
    status ENUM('invited', 'active', 'left') DEFAULT 'invited',
    joined_at TIMESTAMP NULL,
    
    FOREIGN KEY (group_id) REFERENCES tbl_group(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES tbl_user(id) ON DELETE CASCADE,
    UNIQUE KEY unique_member (group_id, user_id)
);

CREATE TABLE tbl_group_battle (
    id INT PRIMARY KEY AUTO_INCREMENT,
    group_id INT NOT NULL,
    topic_id INT NOT NULL,
    category_id INT NOT NULL,
    status ENUM('scheduled', 'in_progress', 'completed') DEFAULT 'scheduled',
    start_time TIMESTAMP NULL,
    end_time TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (group_id) REFERENCES tbl_group(id) ON DELETE CASCADE,
    FOREIGN KEY (topic_id) REFERENCES tbl_topic(id),
    FOREIGN KEY (category_id) REFERENCES tbl_category(id)
);

CREATE TABLE tbl_group_battle_entry (
    id INT PRIMARY KEY AUTO_INCREMENT,
    battle_id INT NOT NULL,
    user_id INT NOT NULL,
    score INT NOT NULL,
    correct_answers INT NOT NULL,
    total_questions INT NOT NULL,
    rank INT NULL,                           -- Classement dans la battle
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (battle_id) REFERENCES tbl_group_battle(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES tbl_user(id) ON DELETE CASCADE,
    UNIQUE KEY unique_entry (battle_id, user_id)
);

-- =====================================================
-- CONTEST (Daily Challenge)
-- =====================================================
CREATE TABLE tbl_contest (
    id INT PRIMARY KEY AUTO_INCREMENT,
    date DATE UNIQUE NOT NULL,               -- Date du contest
    category_id INT NOT NULL,                -- Référence vers le Day Rhapsody
    title VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (category_id) REFERENCES tbl_category(id),
    INDEX idx_date (date)
);

CREATE TABLE tbl_contest_entry (
    id INT PRIMARY KEY AUTO_INCREMENT,
    contest_id INT NOT NULL,
    user_id INT NOT NULL,
    score INT NOT NULL,
    correct_answers INT NOT NULL,
    total_questions INT NOT NULL,
    rank INT NULL,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (contest_id) REFERENCES tbl_contest(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES tbl_user(id) ON DELETE CASCADE,
    UNIQUE KEY unique_entry (contest_id, user_id),
    INDEX idx_contest_score (contest_id, score DESC)
);
```

### 5.5 Progression Utilisateur

```sql
-- Progression par Category (Module FS ou Day Rhapsody)
CREATE TABLE tbl_user_progress (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    category_id INT NOT NULL,
    
    -- Pour Foundation School (Training)
    content_viewed BOOLEAN DEFAULT FALSE,
    content_viewed_at TIMESTAMP NULL,
    
    -- Pour tous
    quiz_completed BOOLEAN DEFAULT FALSE,
    quiz_score INT NULL,
    quiz_completed_at TIMESTAMP NULL,
    quiz_attempts INT DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES tbl_user(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES tbl_category(id) ON DELETE CASCADE,
    UNIQUE KEY unique_progress (user_id, category_id),
    INDEX idx_user (user_id)
);

-- Points utilisateur (pour Rhapsody et Contest)
CREATE TABLE tbl_user_points (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    date DATE NOT NULL,
    reading_points INT DEFAULT 0,            -- Points lecture texte
    quiz_points INT DEFAULT 0,               -- Points quiz
    contest_points INT DEFAULT 0,            -- Points contest
    total_points INT DEFAULT 0,
    
    FOREIGN KEY (user_id) REFERENCES tbl_user(id) ON DELETE CASCADE,
    UNIQUE KEY unique_daily_points (user_id, date),
    INDEX idx_user_date (user_id, date)
);
```

### 5.4 Group

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

### 5.5 Group Member

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

### 5.6 Group Topic Subscription

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

### 5.7 Daily Text (Rhapsody)

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

### 5.8 Question Validation Workflow

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

### 5.9 Daily Quiz (Étendu)

```sql
-- Table existante à étendre
ALTER TABLE tbl_daily_quiz ADD COLUMN topic_id INT;
ALTER TABLE tbl_daily_quiz ADD COLUMN daily_text_id INT;
ALTER TABLE tbl_daily_quiz ADD COLUMN validation_status ENUM('pending', 'ready', 'active', 'completed') DEFAULT 'pending';
ALTER TABLE tbl_daily_quiz ADD FOREIGN KEY (topic_id) REFERENCES tbl_topic(id);
ALTER TABLE tbl_daily_quiz ADD FOREIGN KEY (daily_text_id) REFERENCES tbl_daily_text(id);
```

### 5.10 User Points (Scores Quotidiens)

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

### 5.11 Battle (1v1)

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

### 5.12 Leaderboard (Vues Matérialisées)

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

## 6. Fonctionnalités Détaillées

### 6.0 Points vs Coins - Distinction Importante

Le système utilise deux mécanismes distincts:

#### Points (pour le Classement)
- **Usage:** Classement/Ranking uniquement
- **Source:** Daily Contest (voir 6.1.2)
- **Persistance:** Agrégés par période (jour/semaine/mois/année)
- **Status:** Non-implémenté - sera développé ultérieurement

#### Coins (Monnaie Virtuelle)
- **Usage:** 
  - Achat de lifelines (50/50, Skip, etc.)
  - Récompense pour quiz parfait
- **Source:**
  - **Quiz 100% correct:** +1 coin (replays autorisés)
  - Achat in-app (à venir)
  - Bonus de parrainage
- **Persistance:** Sauvegardés dans le profil utilisateur (`tbl_users.coins`)
- **Exception:** Foundation School n'attribue PAS de coins

### 6.1 Rhapsody - Deux Concepts

#### 6.1.1 Rhapsody of Realities (Implémenté ✅)

Contenu dévotionnel quotidien basé sur "Rhapsody of Realities".

**Structure:**
- Texte du jour (lecture dévotionnelle)
- Quiz de compréhension (10 questions)
- Prière du jour

**Récompense Coin:**
- **Quiz 100% correct:** +1 coin
- **Quiz avec erreurs:** 0 coin
- **Replays:** Autorisés, chaque 100% donne 1 coin

**Navigation:** Année → Mois → Jour → Contenu + Quiz

#### 6.1.2 Daily Contest (Non implémenté ❌)

Compétition quotidienne basée sur le Rhapsody du jour courant.

**Concept:**
- Chaque jour, le système sélectionne automatiquement le Rhapsody du jour
- Tous les utilisateurs sont invités à compléter le quiz du jour
- Classement basé sur les points (pas les coins)

**Disponibilité:**
- **Durée:** Disponible jusqu'à 23:59:59 du jour de création
- **Participation:** 1 seule tentative par jour par utilisateur

**Création (contrôlée par ENV: `DAILY_CONTEST_AUTO_CREATE`):**
| Valeur | Environnement | Comportement |
|--------|---------------|--------------|
| `true` | PRODUCTION | Création automatique à **00:00 AM** (cron job) |
| `false` | DEV/TEST | Création manuelle via script: `php artisan contest:create-daily` |

**UI - Badge de Notification:**
- Sur la carte "Contest" de l'écran d'accueil, un badge rouge apparaît si le Daily Contest du jour n'est pas complété
- Le badge disparaît une fois le quiz terminé

**UI - Écran Contest (liste des contests):**
| Onglet | Description |
|--------|-------------|
| **Ongoing** | Contest du jour en cours (non complété) |
| **Finished** | Contests complétés par l'utilisateur |
| **Upcoming** | Contests futurs (implémentation ultérieure) |

**Notifications Push (jusqu'à complétion):**
| Heure | Message |
|-------|---------|
| **08:00 AM** | "🌅 Bonjour! Le Rhapsody du jour est disponible. Gagnez vos 10 points!" |
| **13:00 PM** | "☀️ N'oubliez pas votre Rhapsody quotidien! Il vous reste quelques heures." |
| **22:00 PM** | "🌙 Dernière chance! Complétez votre Rhapsody avant minuit." |

**Note:** Les notifications cessent une fois que l'utilisateur a complété le quiz du jour.

**Points Quotidiens (10 points max):**
- **Lecture du texte:** 5 points (automatique après lecture)
- **Quiz:** 5 points (1 point par bonne réponse sur 5 questions)
- **Battle gagnée:** +5 points bonus

**Calcul des Points:**
```
Points quotidiens = reading_points + quiz_points + battle_points
Max quotidien = 10 + 5 = 15 points (si battle gagnée)
```

**Agrégation:**
- **Hebdomadaire:** Somme des points quotidiens de la semaine
- **Mensuel:** Somme des points quotidiens du mois
- **Annuel:** Somme des points quotidiens de l'année

### 6.2 Système de Coins - Quizzes Généraux

#### Récompense Coin
- **Quiz parfait (100%):** +1 coin
- **Quiz avec erreurs:** 0 coin
- **Replays:** Autorisés, chaque 100% récompense 1 coin

#### Exception: Foundation School
**Note:** Foundation School est axé sur l'apprentissage, pas la compétition.
- **Pas de coins attribués** pour les quiz Foundation School
- L'accent est mis sur la progression personnelle, pas la gamification

### 6.3 Système de Groupes et Multiplayer Mode

#### Relation Group ↔ Multiplayer Mode

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│   GROUP (Entité Persistante)        MULTIPLAYER MODE (Activité)         │
│   ──────────────────────────        ───────────────────────────         │
│                                                                          │
│   • Communauté permanente           • Bataille temporaire               │
│   • Membres stables                 • Participants par bataille         │
│   • Créé une fois                   • Créé à chaque compétition         │
│                                                                          │
│   RELATION: 1 Group → N Group Battles                                   │
│                                                                          │
│   ┌──────────────────────┐          ┌──────────────────────┐            │
│   │   "Mon Église"       │          │  Group Battle #1     │            │
│   │   ───────────────    │─────────▶│  📅 15 Jan 2025      │            │
│   │  👤 Owner: Jean      │  crée    │  📚 Rhapsody Day 1   │            │
│   │  👥 Membres: 25      │  des     │  🎮 Terminée         │            │
│   │  📅 Créé: 2024       │  battles │  🏆 Gagnant: Marie   │            │
│   └──────────────────────┘          └──────────────────────┘            │
│              │                                                           │
│              │                      ┌──────────────────────┐            │
│              └─────────────────────▶│  Group Battle #2     │            │
│                                     │  📅 16 Jan 2025      │            │
│                                     │  📚 Foundation M1    │            │
│                                     │  🎮 En cours         │            │
│                                     └──────────────────────┘            │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

#### Concepts Clés

| Concept | Group | Group Battle (Multiplayer) |
|---------|-------|----------------------------|
| **Nature** | Entité (nom) | Activité (verbe) |
| **Durée** | Permanente | Temporaire |
| **Membres** | Stables dans le temps | Varient par bataille |
| **Objectif** | Communauté | Compétition |
| **Prérequis** | - | Appartenir à un Group |

#### Flux Utilisateur

1. **Créer/Rejoindre un Group** (une fois)
   ```
   Utilisateur → Crée Group "Mon Église" → Obtient code "ABC123"
   Autres utilisateurs → Entrent code "ABC123" → Rejoignent le group
   ```

2. **Lancer des Battles** (à répétition)
   ```
   Owner/Admin → Sélectionne Topic + Category → Crée Battle
   Tous les membres → Reçoivent notification → Participent
   Tous → Répondent aux mêmes questions → Classement calculé
   ```

#### Types de Groupes

1. **Worldwide** (`type='worldwide'`) - FUTUR
   - Tous les utilisateurs y appartiennent automatiquement
   - Pas de manager (géré par système)
   - Classement global

2. **Country** (`type='country'`) - FUTUR
   - Un groupe par pays (détecté via IP ou sélection utilisateur)
   - Tous les utilisateurs d'un pays y appartiennent automatiquement
   - Pas de manager (géré par système)
   - Classement par pays

3. **Custom** (`type='custom'`) - IMPLÉMENTÉ ✅
- Créés par les utilisateurs
   - Owner désigné (créateur)
   - Code d'invitation unique (8 caractères)
   - Gestion des membres par l'owner/admin
   - Peut lancer des Group Battles

### 6.4 Workflow de Validation des Questions

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

### 6.5 Système de Battles 1v1

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

### 6.6 Classements Multi-Dimensionnels

#### Dimensions
- **Période:** Daily / Weekly / Monthly / Yearly / All-Time
- **Groupe:** Worldwide / Country / Custom Group
- **Topic:** Rhapsody / Bible / Love World News / etc.
- **Version:** Kids / Teens / Adult (pour Rhapsody)

#### Calcul des Classements - Rhapsody
- Basé sur `tbl_user_points`
- Agrégation par période (SUM des points)
- Ranking avec ROW_NUMBER() ou DENSE_RANK()
- Mise à jour quotidienne (cron job)

#### Suivi Foundation School (Pas de classement compétitif)
- **Progression individuelle:** % de modules complétés
- **Vue groupe (pour pasteurs):** Membres actifs, progression moyenne
- **Certificats:** Liste des membres ayant complété chaque classe

**Note:** Foundation School n'a pas de classement compétitif. C'est un parcours d'apprentissage personnel.

---

## 7. Workflows Principaux

### 7.1 Workflow Mensuel: Préparation du Contenu Rhapsody

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

### 7.2 Workflow Quotidien: Expérience Utilisateur Rhapsody

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

### 7.3 Workflow Foundation School: Progression Utilisateur (Self-Paced)

```
1. Utilisateur s'inscrit ou est inscrit à Foundation School
   ↓
2. Foundation Class 1 (FC1) débloquée
   ↓
3. Module 1 disponible (statut: available)
   ↓
4. Utilisateur étudie le contenu à son rythme:
   - Lit le texte
   - Regarde la vidéo
   - Écoute l'audio
   (Pas de contrainte de temps!)
   ↓
5. Contenu complété → Quiz de compréhension disponible
   ↓
6. Utilisateur passe le quiz (10-15 questions)
   ↓
7. Résultat:
   - Réponses correctes affichées
   - Explications pour chaque question
   - Si quiz réussi → Module complété, suivant débloqué
   - Sinon → Peut réessayer immédiatement (pas de limite)
   ↓
8. Répéter pour tous les modules de FC1
   ↓
9. Tous modules complétés:
   - Notification "Félicitations!"
   - Certificat FC1 disponible (optionnel)
   - FC2 automatiquement débloquée
   ↓
10. Progression vers FC2, FC3, FC4 (même processus)

Note: L'utilisateur peut:
- Revenir sur les modules déjà complétés
- Prendre le temps qu'il veut
- Pas de deadline, pas de pression
```

### 7.4 Workflow de Génération IA (Phase 4)

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

### 7.5 Workflow de Gestion de Groupe

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

## 8. Exigences Techniques

### 8.1 Performance

- **Temps de réponse API:** < 500ms (95th percentile)
- **Génération de questions:** < 30s par jour (10-15 questions)
- **Mise à jour des classements:** < 5s (cron job quotidien)
- **Chargement de l'app mobile:** < 2s (écran principal)

### 8.2 Scalabilité

- **Utilisateurs simultanés:** 10,000+
- **Questions par mois:** 30 jours × 3 versions × 15 questions = 1,350 questions
- **Groupes:** Illimité (avec indexation appropriée)
- **Battles simultanées:** 1,000+

### 8.3 Sécurité

- **Authentification:** Firebase Auth (JWT tokens)
- **API Security:** Laravel Sanctum (mobile), API keys (admin)
- **Validation des données:** Côté serveur obligatoire
- **Permissions:** RBAC pour admins (full/partial access)
- **Rate Limiting:** Protection contre abus (battles, quiz)

### 8.4 Disponibilité

- **Uptime cible:** 99.5%
- **Backup base de données:** Quotidien (rétention 30 jours)
- **Monitoring:** Logs d'erreurs, métriques de performance
- **Alertes:** Notification en cas d'échec critique

### 8.5 Compatibilité

- **Mobile:** iOS 13+, Android 8+
- **Navigateurs admin:** Chrome, Firefox, Safari (dernières versions)
- **PDF:** Format PDF 1.4+ (texte extractible)

---

## 9. Plan de Développement

### Phase 1: Rhapsody Quiz - MVP (Semaines 1-6)

**Objectif:** Lancer une version fonctionnelle du quiz Rhapsody.

#### Sprint 1-2: Backend Rhapsody
- [ ] Créer les tables de base (Topic, DailyText, Questions)
- [ ] API pour récupérer le texte du jour
- [ ] API pour récupérer et soumettre les quiz
- [ ] Système de points quotidiens

#### Sprint 3-4: Mobile App Rhapsody
- [ ] Écran d'accueil avec le texte du jour
- [ ] Écran de quiz (10 questions)
- [ ] Écran de résultats avec score
- [ ] Profil utilisateur avec points

#### Sprint 5-6: Groupes et Classements
- [ ] Système de groupes (Worldwide, Country, Custom)
- [ ] Classements quotidiens/hebdomadaires/mensuels
- [ ] Rejoindre un groupe via code

### Phase 2: Foundation School - MVP (Semaines 7-12)

**Objectif:** Ajouter le topic Foundation School avec progression par modules.

#### Sprint 7-8: Backend Foundation School
- [ ] Créer les tables Foundation School
- [ ] API pour les classes et modules
- [ ] API pour la progression utilisateur
- [ ] API pour les quiz de modules

#### Sprint 9-10: Mobile App Foundation School
- [ ] Onglet/Section Foundation School
- [ ] Liste des modules par classe
- [ ] Lecteur de contenu (texte, vidéo, audio)
- [ ] Quiz de module avec progression

#### Sprint 11-12: Examens et Certificats
- [ ] Examen final par classe
- [ ] Génération de certificats (PDF)
- [ ] Tableau de bord progression

### Phase 3: Fonctionnalités Avancées (Semaines 13-18)

#### Sprint 13-14: Battles 1v1
- [ ] Système de challenges entre utilisateurs
- [ ] Notifications de bataille
- [ ] Résultats et points bonus

#### Sprint 15-16: Admin Panel Amélioré
- [ ] Gestion des questions (CRUD)
- [ ] Tableau de bord statistiques
- [ ] Gestion des utilisateurs

#### Sprint 17-18: Suivi Pastoral Foundation School
- [ ] Dashboard pasteur pour suivre les membres
- [ ] Autorisation de retry examen
- [ ] Rapports de progression groupe

### Phase 4: Génération IA de QCM (Optionnel - Semaines 19+)

**Note:** Cette phase peut être développée après les fonctionnalités principales.

#### Sprint 19-20: Intégration IA
- [ ] Processeur PDF pour extraction de texte
- [ ] Intégration Ollama pour génération de questions
- [ ] Workflow de validation des questions générées

#### Sprint 21-22: Optimisation et Déploiement
- [ ] Optimisation des performances
- [ ] Tests de charge
- [ ] Déploiement production
- [ ] Monitoring et alertes

---

## 10. Données de Test pour le Développement

### 10.1 Données Rhapsody

**Seeders à créer:**
- 30 Daily Texts (un par jour) pour un mois de test
- 10 questions par jour (300 questions totales)
- 3 versions: Kids, Teens, Adult

**Format des données:**
```json
{
  "daily_text": {
    "date": "2024-12-21",
    "version": "adult",
    "title": "Living by Faith",
    "bible_text": "For we walk by faith, not by sight. - 2 Corinthians 5:7",
    "meditation": "Faith is the foundation of our Christian walk...",
    "confession": "I declare that I walk by faith and not by sight...",
    "prayer": "Dear Father, thank you for the gift of faith..."
  },
  "questions": [
    {
      "question": "According to today's text, how should we walk?",
      "options": ["By sight", "By faith", "By feelings", "By logic"],
      "correct_answer": 1,
      "explanation": "2 Corinthians 5:7 tells us to walk by faith, not by sight."
    }
  ]
}
```

### 10.2 Données Foundation School

**Seeders à créer:**
- 4 classes (FC1, FC2, FC3, FC4)
- 10 modules par classe (40 modules totaux)
- 15 questions par module (600 questions totales)
- Examens finaux (50 questions par classe)

**Format des données:**
```json
{
  "class": {
    "code": "FC1",
    "name": "Foundation Class 1",
    "modules": [
      {
        "code": "FC1-M01",
        "name": "L'assurance du salut",
        "content": "Le salut est le don gratuit de Dieu...",
        "video_url": "https://youtube.com/...",
        "questions": [
          {
            "question": "Qu'est-ce que le salut selon la Bible?",
            "options": ["Une récompense", "Un don gratuit", "Un mérite", "Une obligation"],
            "correct_answer": 1
          }
        ]
      }
    ]
  }
}
```

---

## 11. Glossaire

- **QCM:** Question à Choix Multiples
- **Topic:** Thème de quiz (Rhapsody, Foundation School)
- **Group:** Groupe d'utilisateurs (Worldwide, Country, Custom/Église)
- **Manager/Pasteur:** Gestionnaire d'un groupe personnalisé
- **Daily Text:** Texte dévotionnel quotidien Rhapsody
- **Module:** Unité de formation dans Foundation School
- **Classe:** Niveau dans Foundation School (FC1, FC2, FC3, FC4)
- **Battle:** Défi 1v1 entre deux utilisateurs
- **Points:** Système de récompense basé sur l'assiduité et la performance
- **Certificat:** Document attestant la complétion d'une classe Foundation School

---

## 12. Annexes

### 12.1 Schémas de Base de Données

Voir section 5 pour les schémas SQL complets.

### 12.2 API Endpoints - Rhapsody

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/api/daily-text/{date}` | GET | Récupérer le texte du jour |
| `/api/daily-text/{date}/read` | POST | Marquer le texte comme lu |
| `/api/daily-quiz/{date}` | GET | Récupérer le quiz du jour |
| `/api/daily-quiz/{date}/submit` | POST | Soumettre les réponses |
| `/api/leaderboard/{period}` | GET | Classements (daily/weekly/monthly) |
| `/api/battles/challenge` | POST | Défier un utilisateur |
| `/api/battles/{id}/accept` | POST | Accepter un défi |

### 12.3 API Endpoints - Foundation School

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/api/fs/classes` | GET | Liste des classes |
| `/api/fs/classes/{id}/modules` | GET | Modules d'une classe |
| `/api/fs/modules/{id}` | GET | Détail d'un module |
| `/api/fs/modules/{id}/quiz` | GET | Quiz du module |
| `/api/fs/modules/{id}/submit` | POST | Soumettre le quiz |
| `/api/fs/classes/{id}/exam` | GET | Examen final |
| `/api/fs/classes/{id}/exam/submit` | POST | Soumettre l'examen |
| `/api/fs/progress` | GET | Progression utilisateur |
| `/api/fs/certificates` | GET | Certificats obtenus |

### 12.4 Diagrammes de Séquence

**Inclus dans ARCHITECTURE.md:**
- Workflow Rhapsody quotidien
- Workflow Foundation School progression
- Workflow Battle 1v1

---

**Document créé le:** Décembre 2024  
**Dernière mise à jour:** Décembre 2024  
**Version:** 2.0  
**Focus:** Rhapsody of Realities & Foundation School

