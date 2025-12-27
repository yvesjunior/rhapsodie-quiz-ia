# Architecture Document - Rhapsodie Quiz IA Platform

**Version:** 1.0  
**Date:** Décembre 2024  
**Status:** Design & Recommendations

---

## Table des Matières

1. [Vue d'ensemble](#1-vue-densemble)
2. [Architecture Actuelle](#2-architecture-actuelle)
3. [Architecture Recommandée](#3-architecture-recommandée)
4. [Diagrammes d'Architecture](#4-diagrammes-darchitecture)
5. [Composants et Instances](#5-composants-et-instances)
6. [Services et APIs](#6-services-et-apis)
7. [Workflows et Flux d'Interaction](#7-workflows-et-flux-dinteraction)
8. [Patterns de Communication](#8-patterns-de-communication)
9. [Déploiement](#9-déploiement)
10. [Scalabilité](#10-scalabilité)
11. [Sécurité](#11-sécurité)
12. [Monitoring et Observabilité](#12-monitoring-et-observabilité)

---

## 1. Vue d'ensemble

### 1.1 Principes Architecturaux

- **Séparation des responsabilités:** Chaque composant a un rôle clair et bien défini
- **Microservices-ready:** Architecture modulaire permettant une évolution vers des microservices
- **API-First:** Toutes les interactions passent par des APIs REST bien définies
- **Scalabilité horizontale:** Possibilité d'ajouter des instances selon la charge
- **Résilience:** Gestion des erreurs et fallback mechanisms
- **Sécurité:** Authentification centralisée, validation des données, rate limiting

### 1.2 Stack Technologique

| Composant | Technologie | Version |
|-----------|------------|---------|
| Mobile App | Flutter | 3.10+ |
| Admin Panel | CodeIgniter | 3.x |
| AI API | Laravel | 12.x (Optionnel - Phase 6) |
| PDF Processor | Python | 3.10+ (Optionnel - Phase 6) |
| Database | MySQL | 8.0+ |
| Cache | Redis | 7.0+ |
| Queue | Laravel Queue / RabbitMQ | - |
| Search | Elasticsearch (optionnel) | 8.x |
| File Storage | Local / S3 | - |
| LLM | Ollama | Latest (Optionnel - Phase 6) |

---

## 2. Architecture Actuelle

### 2.1 Diagramme d'Architecture Actuel

```
┌─────────────────────────────────────────────────────────────┐
│                    MOBILE APP (Flutter)                     │
│  - Single Instance                                           │
│  - BLoC/Cubit State Management                              │
│  - Hive Local Storage                                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ HTTPS/REST API
                       │
┌──────────────────────┴──────────────────────────────────────┐
│         ADMIN PANEL API (CodeIgniter/PHP)                    │
│  - Single Instance                                           │
│  - Monolithic Controller (Api.php)                          │
│  - Direct DB Access                                          │
│  Port: 8080                                                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ MySQL Connection
                       │
┌──────────────────────┴──────────────────────────────────────┐
│              DATABASE (MySQL)                                │
│  - elite_quiz_237                                            │
│  - Single Instance                                           │
│  Port: 3310                                                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│         AI SERVICES (OPTIONNEL - Phase 6)                    │
│  ┌──────────────────┐         ┌──────────────────┐       │
│  │ AI QCM API       │         │ PDF Processor    │       │
│  │ (Laravel)        │◄────────┤ (Python)         │       │
│  │ Port: 8000       │  Queue  │ - Ollama         │       │
│  └──────────────────┘         └──────────────────┘       │
│                                                              │
│  Note: Pour le développement initial, utiliser des         │
│        questions manuelles créées via Admin Panel           │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Limitations de l'Architecture Actuelle

1. **Monolithique:** Admin Panel API est un monolithe avec un seul contrôleur
2. **Pas de cache:** Pas de système de cache pour les requêtes fréquentes
3. **Pas de queue:** Traitement synchrone des tâches longues
4. **Pas de load balancing:** Single point of failure
5. **Pas de séparation API/Web:** Admin Panel mélange API et interface web
6. **Pas de service de recherche:** Recherche basique en base de données
7. **Pas de monitoring:** Pas d'observabilité sur les performances

---

## 3. Architecture Recommandée

### 3.1 Architecture Cible (Phase 1 - Amélioration Progressive)

```
┌─────────────────────────────────────────────────────────────┐
│                    MOBILE APP (Flutter)                     │
│  - Multiple Instances (iOS/Android)                         │
│  - Offline Support (Hive)                                   │
│  - Push Notifications (FCM)                                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ HTTPS/REST API
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
┌──────────────────┐         ┌──────────────────┐
│   API GATEWAY    │         │   ADMIN API       │
│   (Nginx/LB)     │         │   (CodeIgniter)   │
│   - Routing      │         │   - Web UI        │
│   - Rate Limit   │         │   Port: 8080      │
│   - SSL/TLS       │         └─────────┬─────────┘
└────────┬─────────┘                   │
         │                             │
         ▼                             ▼
┌─────────────────────────────────────────────────────────────┐
│              CORE API SERVICES                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │  Quiz API    │  │  Group API   │  │  User API    │    │
│  │  Service     │  │  Service     │  │  Service     │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│         │                 │                  │              │
│  ┌──────┴─────────────────┴──────────────────┴───────┐   │
│  │         Shared Services Layer                      │   │
│  │  - Authentication Service                          │   │
│  │  - Validation Service                              │   │
│  │  - Notification Service                            │   │
│  └────────────────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   MySQL      │ │    Redis     │ │   Queue      │
│   Primary    │ │    Cache     │ │   Worker     │
│   Port:3310  │ │   Port:6379  │ │   (Laravel)  │
└──────────────┘ └──────────────┘ └──────────────┘

┌─────────────────────────────────────────────────────────────┐
│              AI SERVICES                                    │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │  Laravel AI API  │◄────────┤  Python Processor│         │
│  │  - QCM Storage   │  HTTP   │  - PDF Extract  │         │
│  │  - Validation    │         │  - Ollama Call   │         │
│  │  Port: 8000      │         │  - QCM Generate  │         │
│  └──────────────────┘         └──────────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Architecture Cible (Phase 2 - Microservices)

```
┌─────────────────────────────────────────────────────────────┐
│                    MOBILE APP (Flutter)                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ HTTPS
                       │
┌──────────────────────┴──────────────────────────────────────┐
│                    API GATEWAY                               │
│  - Kong / Traefik / Nginx                                    │
│  - Authentication                                            │
│  - Rate Limiting                                             │
│  - Request Routing                                            │
│  - Load Balancing                                            │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  Quiz        │ │  Group       │ │  User        │
│  Service     │ │  Service     │ │  Service     │
│  :3001       │ │  :3002       │ │  :3003       │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘
       │                │                │
       └────────────────┼────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   MySQL      │ │    Redis     │ │   RabbitMQ   │
│   Primary    │ │    Cache     │ │   Queue      │
│   + Replica  │ │   Cluster    │ │   Exchange   │
└──────────────┘ └──────────────┘ └──────────────┘

┌─────────────────────────────────────────────────────────────┐
│              AI SERVICES                                    │
│  ┌──────────────┐         ┌──────────────┐               │
│  │  AI API      │◄────────┤  PDF Worker  │               │
│  │  Service     │  Queue  │  (Python)     │               │
│  │  :4001       │         │  - Ollama    │               │
│  └──────────────┘         └──────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Diagrammes d'Architecture

### 4.1 Vue d'Ensemble Globale - Phase 1

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         MOBILE APPLICATION                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                │
│  │   iOS App    │  │ Android App  │  │   Web PWA    │                │
│  │  (Flutter)   │  │  (Flutter)   │  │  (Flutter)   │                │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘                │
│         │                 │                  │                          │
│         └─────────────────┼──────────────────┘                          │
│                           │                                              │
│                    HTTPS/REST API                                        │
└───────────────────────────┼──────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         API GATEWAY / LOAD BALANCER                     │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │  Nginx / Kong                                                 │    │
│  │  - SSL/TLS Termination                                        │    │
│  │  - Request Routing                                            │    │
│  │  - Rate Limiting                                              │    │
│  │  - Load Balancing                                             │    │
│  └──────────────────────────────────────────────────────────────┘    │
└───────────────────────────┬──────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  Admin API   │   │  Admin API   │   │  Admin API   │
│  Instance 1   │   │  Instance 2   │   │  Instance 3   │
│  (CodeIgniter)│   │  (CodeIgniter)│   │  (CodeIgniter)│
└──────┬───────┘   └──────┬───────┘   └──────┬───────┘
       │                  │                  │
       └──────────────────┼──────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│   MySQL      │   │    Redis     │   │   Queue      │
│   Primary    │   │    Cache     │   │   Workers    │
│   + Replica  │   │   (Cluster)  │   │   (3x)       │
└──────────────┘   └──────────────┘   └──────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         ADMIN PANEL (Web)                                │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │  CodeIgniter Web Interface                                    │    │
│  │  - Content Management                                         │    │
│  │  - Question Validation                                        │    │
│  │  - User Management                                            │    │
│  │  - Analytics                                                  │    │
│  └──────────────────────────────────────────────────────────────┘    │
└───────────────────────────┬──────────────────────────────────────────────┘
                            │
                            │ HTTP API
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         AI SERVICES                                     │
│  ┌──────────────┐              ┌──────────────┐                      │
│  │ Laravel AI   │◄─────────────┤ PDF Processor│                      │
│  │ API          │   Queue      │ (Python)     │                      │
│  │ Port: 8000   │              │ - Ollama     │                      │
│  └──────────────┘              │ - PyPDF      │                      │
│                                └──────────────┘                      │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Vue Simplifiée

```
                    ┌─────────────┐
                    │ Mobile App  │
                    └──────┬──────┘
                           │ HTTPS
                    ┌──────▼──────┐
                    │ API Gateway │
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   ┌────▼────┐        ┌────▼────┐       ┌────▼────┐
   │ Admin   │        │ Admin   │       │ Admin   │
   │ API 1  │        │ API 2   │       │ API 3   │
   └────┬────┘        └────┬────┘       └────┬────┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   ┌────▼────┐        ┌────▼────┐       ┌────▼────┐
   │ MySQL   │        │ Redis   │       │ Queue   │
   │ DB      │        │ Cache   │       │ Workers │
   └─────────┘        └─────────┘       └─────────┘

        ┌──────────────────────────────────┐
        │         AI Services              │
        │  ┌──────────┐    ┌──────────┐  │
        │  │ AI API   │◄───┤ PDF      │  │
        │  │          │    │ Worker   │  │
        │  └──────────┘    └──────────┘  │
        └──────────────────────────────────┘
```

---

## 5. Composants et Instances

### 5.1 Recommandations d'Instances par Composant

#### 5.1.1 Mobile App (Flutter)

**Instances Recommandées:**
- **iOS App:** 1 instance (distribuée via App Store)
- **Android App:** 1 instance (distribuée via Play Store)
- **Web App (optionnel):** 1 instance (PWA)

**Architecture Interne:**
```
Mobile App Structure:
├── Presentation Layer (UI)
│   ├── Screens (83 files)
│   └── Widgets (20 files)
├── Business Logic Layer
│   ├── Features (131 files)
│   │   ├── Auth (Cubits)
│   │   ├── Quiz (Cubits)
│   │   ├── Groups (Cubits) [NEW]
│   │   └── Leaderboard (Cubits)
├── Data Layer
│   ├── Remote Data Sources
│   ├── Local Data Sources (Hive)
│   └── Repositories
└── Core Layer
    ├── Config
    ├── Constants
    ├── Navigation
    └── Utils
```

**Recommandations:**
- ✅ Conserver l'architecture BLoC/Cubit actuelle
- ✅ Ajouter un service de cache local pour les données fréquentes
- ✅ Implémenter retry logic avec exponential backoff
- ✅ Ajouter offline mode avec sync automatique

#### 5.1.2 Admin Panel API (CodeIgniter)

**Instances Recommandées:**

| Phase | Instances | CPU | RAM | Port | Notes |
|-------|-----------|-----|-----|------|-------|
| **Development** | 1 | 1 core | 1GB | 8080 | Local dev |
| **Staging** | 2 | 2 cores | 2GB | 8080 | Load balanced |
| **Production** | 3-5 | 2 cores | 2GB | 8080 | Selon charge |

**Scaling Rules:**
- **Ajouter instance si:** CPU > 70% OU Response time > 500ms (p95)
- **Réduire instance si:** CPU < 30% ET Response time < 200ms (p95)

**Refactoring Recommandé:**

```
Current Structure:
Api.php (Monolithic - 3000+ lines)
├── user_signup()
├── get_questions()
├── get_daily_quiz()
└── ... (65+ methods)

Recommended Structure:
├── Controllers/
│   ├── Api/
│   │   ├── AuthController.php
│   │   ├── QuizController.php
│   │   ├── GroupController.php      [NEW]
│   │   ├── TopicController.php      [NEW]
│   │   ├── DailyTextController.php  [NEW]
│   │   ├── BattleController.php     [NEW]
│   │   ├── LeaderboardController.php
│   │   └── UserController.php
│   └── Web/
│       ├── Dashboard.php
│       ├── Questions.php
│       └── ...
├── Services/
│   ├── AuthService.php
│   ├── QuizService.php
│   ├── GroupService.php              [NEW]
│   ├── PointsService.php             [NEW]
│   └── ValidationService.php        [NEW]
├── Repositories/
│   ├── QuestionRepository.php
│   ├── GroupRepository.php            [NEW]
│   └── ...
└── Models/
    └── (Eloquent-like models)
```

**Recommandations:**
- ✅ Séparer API et Web controllers
- ✅ Créer une couche Service pour la logique métier
- ✅ Implémenter Repository pattern pour l'accès aux données
- ✅ Ajouter validation centralisée
- ✅ Implémenter rate limiting par endpoint

#### 5.1.3 Core API Services (Nouveau - Phase 2)

##### Service 1: Quiz Service

| Phase | Instances | CPU | RAM | Port |
|-------|-----------|-----|-----|------|
| Development | 1 | 1 core | 1GB | 3001 |
| Staging | 2 | 2 cores | 2GB | 3001 |
| Production | 3-5 | 2 cores | 2GB | 3001 |

**Responsibilities:**
- Gestion des questions
- Quiz quotidiens
- Validation des réponses
- Calcul des scores

**Endpoints:**
- GET /api/v1/questions
- POST /api/v1/daily-quiz/validate
- GET /api/v1/daily-quiz/{date}
- POST /api/v1/quiz/submit

##### Service 2: Group Service

| Phase | Instances | CPU | RAM | Port |
|-------|-----------|-----|-----|------|
| Development | 1 | 1 core | 1GB | 3002 |
| Staging | 2 | 2 cores | 2GB | 3002 |
| Production | 2-3 | 2 cores | 2GB | 3002 |

**Responsibilities:**
- Gestion des groupes
- Membres de groupes
- Topics par groupe
- Permissions

**Endpoints:**
- GET /api/v1/groups
- POST /api/v1/groups
- POST /api/v1/groups/{id}/members
- GET /api/v1/groups/{id}/members
- POST /api/v1/groups/{id}/topics

##### Service 3: User Service

| Phase | Instances | CPU | RAM | Port |
|-------|-----------|-----|-----|------|
| Development | 1 | 1 core | 1GB | 3003 |
| Staging | 2 | 2 cores | 2GB | 3003 |
| Production | 2-3 | 2 cores | 2GB | 3003 |

**Responsibilities:**
- Gestion des utilisateurs
- Profils
- Authentification
- Points utilisateur

**Endpoints:**
- GET /api/v1/users/{id}
- PUT /api/v1/users/{id}
- GET /api/v1/users/{id}/points
- POST /api/v1/users/{id}/points

##### Service 4: Battle Service

| Phase | Instances | CPU | RAM | Port |
|-------|-----------|-----|-----|------|
| Development | 1 | 1 core | 1GB | 3004 |
| Staging | 1 | 2 cores | 2GB | 3004 |
| Production | 2 | 2 cores | 2GB | 3004 |

**Responsibilities:**
- Battles 1v1
- Invitations
- Résultats
- Points bonus

**Endpoints:**
- POST /api/v1/battles/challenge
- POST /api/v1/battles/{id}/accept
- POST /api/v1/battles/{id}/complete
- GET /api/v1/battles/{id}/status

##### Service 5: Leaderboard Service

| Phase | Instances | CPU | RAM | Port |
|-------|-----------|-----|-----|------|
| Development | 1 | 1 core | 1GB | 3005 |
| Staging | 1 | 2 cores | 2GB | 3005 |
| Production | 2 | 2 cores | 2GB | 3005 |

**Responsibilities:**
- Calcul des classements
- Agrégation des points
- Filtres multi-dimensionnels
- Cache des résultats

**Endpoints:**
- GET /api/v1/leaderboard/daily
- GET /api/v1/leaderboard/weekly
- GET /api/v1/leaderboard/monthly
- GET /api/v1/leaderboard/yearly

**Query Params:** group_id, topic_id, version, limit, offset

##### Service 6: Notification Service

| Phase | Instances | CPU | RAM | Port |
|-------|-----------|-----|-----|------|
| Development | 1 | 1 core | 512MB | 3006 |
| Staging | 1 | 1 core | 1GB | 3006 |
| Production | 2 | 1 core | 1GB | 3006 |

**Responsibilities:**
- Push notifications
- Notifications in-app
- Emails (optionnel)
- SMS (optionnel)

**Endpoints:**
- POST /api/v1/notifications/send
- GET /api/v1/notifications/user/{id}
- POST /api/v1/notifications/mark-read

#### 5.1.4 AI Services (Optionnel - Phase 6)

**Note:** Ces services sont optionnels et peuvent être développés après les phases principales (1-5). Pour le développement initial, utiliser des questions manuelles créées via l'interface Admin Panel.

##### AI API Service (Laravel)

| Phase | Instances | CPU | RAM | Port |
|-------|-----------|-----|-----|------|
| Development | 1 | 1 core | 2GB | 4001 |
| Staging | 1 | 2 cores | 4GB | 4001 |
| Production | 2 | 2 cores | 4GB | 4001 |

**Responsibilities:**
- Réception des questions générées
- Stockage temporaire
- Workflow de validation
- Intégration avec Admin Panel

**Endpoints:**
- POST /api/v1/qcm (from Python)
- GET /api/v1/qcm/pending
- PUT /api/v1/qcm/{id}/validate
- DELETE /api/v1/qcm/{id}

##### PDF Processor Worker (Python)

| Phase | Instances | CPU | RAM | Type |
|-------|-----------|-----|-----|------|
| Development | 1 | 2 cores | 2GB | Background |
| Staging | 2 | 2 cores | 2GB | Queue Worker |
| Production | 2-3 | 2 cores | 2GB | Queue Worker |

**Responsibilities:**
- Extraction de texte PDF
- Découpage en chunks
- Appels Ollama
- Génération QCM
- Envoi vers AI API

**Configuration:**
- Workers: 2-3 instances (parallel processing)
- Queue: RabbitMQ / Laravel Queue
- Retry: 3 attempts with exponential backoff

#### 5.1.5 Infrastructure Services

##### API Gateway / Load Balancer

| Instance | Type | Ports | Configuration |
|----------|------|-------|----------------|
| nginx-lb-1 | Nginx | 80, 443 | SSL termination, routing |

**Fonctionnalités:**
- SSL/TLS termination
- Load balancing (round-robin / least-conn)
- Health checks
- Rate limiting
- Request/Response logging

**Recommandation:** 1 instance suffit (peut être mis en cluster pour HA).

##### Cache Service (Redis)

| Phase | Instances | CPU | RAM | Type |
|-------|-----------|-----|-----|------|
| Development | 1 | 1 core | 1GB | Single |
| Staging | 1 | 2 cores | 2GB | Single |
| Production | 3 | 2 cores | 4GB | Cluster |

**Responsibilities:**
- Cache des questions fréquentes
- Cache des classements
- Session storage
- Rate limiting counters
- Queue backend (optionnel)

**Configuration:**
- Memory: 2-4GB (scalable)
- Persistence: RDB + AOF
- Replication: Master-Slave (production)
- Eviction: allkeys-lru
- Max memory: 3GB (production)

**Usage:**
- Cache questions: 1h TTL
- Cache leaderboards: 1h-24h TTL
- Session storage: 24h TTL
- Rate limiting counters: 1h TTL

##### Queue Service

**Option 1: Laravel Queue (Redis/Database)**

| Phase | Workers | CPU | RAM | Type |
|-------|---------|-----|-----|------|
| Development | 1 | 1 core | 512MB | Single |
| Staging | 2 | 1 core | 1GB | Multiple |
| Production | 3-5 | 1 core | 1GB | Multiple |

**Queues:**
- `default`: Tâches générales
- `pdf-processing`: Génération QCM (high priority)
- `leaderboard-calculation`: Calcul classements (scheduled)
- `notifications`: Envoi notifications (low priority)

**Option 2: RabbitMQ (Recommandé Production)**

| Phase | Instances | CPU | RAM | Port |
|-------|-----------|-----|-----|------|
| Development | 1 | 1 core | 1GB | 5672 |
| Staging | 1 | 2 cores | 2GB | 5672 |
| Production | 1 + 1 | 2 cores | 2GB | 5672 (HA) |

**Workers:**
- PDF Processing: 2-3 workers
- Leaderboard: 1 worker (scheduled)
- Notifications: 2 workers

##### Database (MySQL)

| Phase | Instances | CPU | RAM | Storage | Type |
|-------|-----------|-----|-----|---------|------|
| Development | 1 | 2 cores | 4GB | 20GB | Single |
| Staging | 1 + 1 | 4 cores | 8GB | 50GB | Primary + Replica |
| Production | 1 + 2 | 4 cores | 8GB | 100GB+ | Primary + 2 Replicas |

**Configuration:**
- Engine: InnoDB
- Character Set: utf8mb4
- Connection Pool: 100-200
- Backup: Daily full + 6h incremental

**Scaling:**
- Vertical: Augmenter CPU/RAM si nécessaire
- Horizontal: Ajouter read replicas pour scaling reads

### 5.2 Plan de Scaling par Charge

#### Scénario 1: 1,000 Utilisateurs Actifs

```
Load Balancer: 1 instance
Admin API: 2 instances
MySQL: 1 primary
Redis: 1 instance
Queue Workers: 2 instances
AI API: 1 instance
PDF Workers: 1 instance

Total Estimated Cost: Low
```

#### Scénario 2: 10,000 Utilisateurs Actifs

```
Load Balancer: 1 instance (HA)
Admin API: 3 instances
MySQL: 1 primary + 1 replica
Redis: 1 instance (4GB)
Queue Workers: 3 instances
AI API: 2 instances
PDF Workers: 2 instances

Total Estimated Cost: Medium
```

#### Scénario 3: 100,000 Utilisateurs Actifs

```
Load Balancer: 2 instances (HA)
Admin API: 5 instances
Core Services: 2-3 instances each
MySQL: 1 primary + 2 replicas
Redis: Cluster (3 nodes)
Queue Workers: 5 instances
AI API: 3 instances
PDF Workers: 3 instances

Total Estimated Cost: High
```

---

## 6. Services et APIs

### 6.1 Structure des APIs

#### 6.1.1 Convention de Nommage

```
Base URL: https://api.rhapsodie-quiz.com/v1

Endpoints:
- Resources: /api/v1/{resource}
- Actions: /api/v1/{resource}/{id}/{action}
- Nested: /api/v1/{resource}/{id}/{nested-resource}

Examples:
GET  /api/v1/groups
POST /api/v1/groups
GET  /api/v1/groups/{id}
PUT  /api/v1/groups/{id}
DELETE /api/v1/groups/{id}
GET  /api/v1/groups/{id}/members
POST /api/v1/groups/{id}/members
```

#### 6.1.2 Format de Réponse Standard

```json
{
  "success": true,
  "data": {
    // Resource data
  },
  "meta": {
    "timestamp": "2024-12-21T10:00:00Z",
    "version": "1.0"
  }
}

Error Response:
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Email is required"
      }
    ]
  },
  "meta": {
    "timestamp": "2024-12-21T10:00:00Z"
  }
}
```

### 6.2 Services Détaillés

#### 6.2.1 Quiz Service API

**Endpoints Principaux:**

```php
// Questions
GET    /api/v1/questions
POST   /api/v1/questions
GET    /api/v1/questions/{id}
PUT    /api/v1/questions/{id}
DELETE /api/v1/questions/{id}

// Daily Quiz
GET    /api/v1/daily-quiz/{date}
POST   /api/v1/daily-quiz/{date}/submit
GET    /api/v1/daily-quiz/{date}/text

// Question Validation (Admin)
GET    /api/v1/questions/pending
POST   /api/v1/questions/{id}/validate
PUT    /api/v1/questions/{id}/edit
DELETE /api/v1/questions/{id}/reject
```

#### 6.2.2 Group Service API

**Endpoints Principaux:**

```php
// Groups
GET    /api/v1/groups
POST   /api/v1/groups
GET    /api/v1/groups/{id}
PUT    /api/v1/groups/{id}
DELETE /api/v1/groups/{id}

// Members
GET    /api/v1/groups/{id}/members
POST   /api/v1/groups/{id}/members
DELETE /api/v1/groups/{id}/members/{userId}
POST   /api/v1/groups/{id}/members/{userId}/promote

// Topics
GET    /api/v1/groups/{id}/topics
POST   /api/v1/groups/{id}/topics
DELETE /api/v1/groups/{id}/topics/{topicId}

// Invitations
POST   /api/v1/groups/{id}/invite
POST   /api/v1/groups/join/{code}
GET    /api/v1/groups/join-requests/{groupId}
POST   /api/v1/groups/join-requests/{requestId}/approve
```

#### 6.2.3 Leaderboard Service API

**Endpoints Principaux:**

```php
GET /api/v1/leaderboard/daily?group_id={id}&topic_id={id}&date={date}
GET /api/v1/leaderboard/weekly?group_id={id}&topic_id={id}&week={week}
GET /api/v1/leaderboard/monthly?group_id={id}&topic_id={id}&month={month}
GET /api/v1/leaderboard/yearly?group_id={id}&topic_id={id}&year={year}
GET /api/v1/leaderboard/all-time?group_id={id}&topic_id={id}
```

**Optimisations:**
- Cache Redis (TTL: 1 heure pour daily, 24h pour weekly/monthly)
- Calcul asynchrone via queue
- Pagination (limit: 50, offset)

---

## 7. Workflows et Flux d'Interaction

### 7.1 Flux Général - Requête Utilisateur

```
┌──────────┐
│  User    │
│ (Mobile) │
└────┬─────┘
     │
     │ 1. HTTPS Request
     │    GET /api/v1/daily-quiz/2024-12-21
     ▼
┌──────────────┐
│ API Gateway  │
│  - Auth      │
│  - Rate Limit│
└────┬─────────┘
     │
     │ 2. Route to Service
     │    Load Balance
     ▼
┌──────────────┐
│ Admin API    │
│ Instance     │
└────┬─────────┘
     │
     │ 3. Check Cache
     ▼
┌──────────────┐      ┌──────────────┐
│ Redis Cache  │      │   MySQL     │
│ (Hit/Miss)   │      │   Database   │
└────┬─────────┘      └──────┬───────┘
     │                        │
     │ 4a. Cache Hit          │ 4b. Cache Miss
     │    Return Cached       │    Query DB
     │                        │    Store in Cache
     │                        │
     └──────────┬─────────────┘
                │
                │ 5. Response
                ▼
         ┌──────────┐
         │  User    │
         │ (Mobile) │
         └──────────┘
```

### 7.2 Flux d'Authentification

```
┌──────────┐
│  User    │
│ (Mobile) │
└────┬─────┘
     │
     │ 1. Sign in with Google
     ▼
┌──────────────┐
│ Firebase Auth│
│  - Verify    │
│  - Get Token │
└────┬─────────┘
     │
     │ 2. Firebase ID Token
     ▼
┌──────────────┐
│ API Gateway  │
└────┬─────────┘
     │
     │ 3. POST /api/user_signup
     │    {firebase_id, type}
     ▼
┌──────────────┐
│ Admin API    │
│ - Verify     │
│ - Create/Get │
│   User       │
└────┬─────────┘
     │
     │ 4. Query/Create User
     ▼
┌──────────────┐
│   MySQL      │
│   Database   │
└────┬─────────┘
     │
     │ 5. User Data
     ▼
┌──────────────┐
│ Admin API    │
│ - Generate   │
│   JWT Token  │
└────┬─────────┘
     │
     │ 6. JWT Token + User Data
     ▼
┌──────────┐
│  User    │
│ (Mobile) │
│ Store    │
│ Token    │
└──────────┘
```

### 7.3 Workflow: Génération de Questions (PDF → Questions Validées)

```
┌──────────┐
│  Admin   │
│ (Web UI) │
└────┬─────┘
     │
     │ 1. Upload PDF
     │    December 2025 - Adult
     ▼
┌──────────────────┐
│  Admin Panel     │
│  - Store PDF     │
│  - Extract Dates │
└────┬─────────────┘
     │
     │ 2. POST /api/v1/pdf/process
     │    {pdf_path, month, year, version}
     ▼
┌──────────────────┐
│  Queue Service   │
│  - Add Job       │
│  Priority: High  │
└────┬─────────────┘
     │
     │ 3. Queue Job
     ▼
┌──────────────────┐
│ PDF Worker       │
│ (Python)         │
│ - Extract Text   │
│ - Chunk (1400w)  │
└────┬─────────────┘
     │
     │ 4. For each chunk
     │    Call Ollama API
     ▼
┌──────────────────┐
│  Ollama LLM      │
│  - Generate QCM  │
│  - Retry if fail │
└────┬─────────────┘
     │
     │ 5. Questions Generated
     │    {question, options, answer, explanation}
     ▼
┌──────────────────┐
│ Laravel AI API   │
│ - Store Questions│
│ - Status: Pending│
└────┬─────────────┘
     │
     │ 6. Questions in DB
     │    tbl_question_validation
     │    status = 'pending'
     ▼
┌──────────────────┐
│  Admin Panel     │
│  - Notification  │
│  - Show Pending │
└────┬─────────────┘
     │
     │ 7. Admin Reviews
     │    Validate/Edit/Delete
     ▼
┌──────────────────┐
│ Validation API   │
│ - Update Status  │
│ - Link to Date   │
└────┬─────────────┘
     │
     │ 8. All Questions Validated
     │    Daily Quiz Status → 'ready'
     ▼
┌──────────────────┐
│ Cron Job         │
│ (00:00 Daily)    │
│ - Activate Quiz  │
│ - Status → 'active'
└──────────────────┘
```

### 7.4 Workflow: Quiz Quotidien Utilisateur

```
┌──────────┐
│  User    │
│ (Mobile) │
└────┬─────┘
     │
     │ 00:00 - New Day Starts
     │
     │ 1. Open App
     │    GET /api/v1/daily-text/2024-12-21
     ▼
┌──────────────┐
│ Quiz Service │
│ - Get Text   │
│ - Check Read │
└────┬─────────┘
     │
     │ 2. Return Daily Text
     │    {bible_text, prayer_text}
     ▼
┌──────────┐
│  User    │
│ Reads    │
│ Text     │
└────┬─────┘
     │
     │ 3. Mark as Read
     │    POST /api/v1/daily-text/read
     ▼
┌──────────────┐
│ Points Service│
│ - Award 2pts  │
│ - Unlock Quiz │
└────┬─────────┘
     │
     │ 4. Quiz Unlocked
     │    GET /api/v1/daily-quiz/2024-12-21
     ▼
┌──────────────┐
│ Quiz Service │
│ - Get 10 Q    │
│ - Randomize  │
└────┬─────────┘
     │
     │ 5. Questions Displayed
     ▼
┌──────────┐
│  User    │
│ Answers  │
│ Questions│
└────┬─────┘
     │
     │ 6. Submit Answers
     │    POST /api/v1/quiz/submit
     ▼
┌──────────────┐
│ Quiz Service │
│ - Calculate  │
│   Score      │
│ - Max 8pts   │
└────┬─────────┘
     │
     │ 7. Update Points
     │    Total: 2 (read) + 8 (quiz) = 10pts
     ▼
┌──────────────┐
│ Points Service│
│ - Store      │
│ - Update LB  │
└────┬─────────┘
     │
     │ 8. Queue Leaderboard Update
     ▼
┌──────────────┐
│ Queue Worker │
│ - Calculate  │
│   Rankings   │
└────┬─────────┘
     │
     │ 9. Update Cache
     ▼
┌──────────────┐
│ Redis Cache  │
│ - Store LB   │
│ - TTL: 1h    │
└──────────────┘
```

### 7.5 Workflow: Battle 1v1

```
┌──────────┐         ┌──────────┐
│ User A   │         │ User B   │
│(Challenger)│       │(Opponent)│
└────┬─────┘         └────┬─────┘
     │                    │
     │ 1. Select User B
     │    POST /api/v1/battles/challenge
     │    {opponent_id, group_id, topic_id}
     ▼                    │
┌──────────────┐          │
│Battle Service│          │
│- Create      │          │
│  Battle      │          │
│- Status:     │          │
│  Pending     │          │
└────┬─────────┘          │
     │                    │
     │ 2. Send Notification
     │                    │
     │                    ▼
     │            ┌──────────────┐
     │            │Notification  │
     │            │Service       │
     │            │- Push Notif   │
     │            │- In-App      │
     │            └────┬─────────┘
     │                 │
     │                 │ 3. User B Sees Notification
     │                 │
     │                 ▼
     │            ┌──────────┐
     │            │ User B   │
     │            │ Opens App│
     │            └────┬─────┘
     │                 │
     │                 │ 4. Accept Challenge
     │                 │    POST /api/v1/battles/{id}/accept
     │                 │
     │                 ▼
     │            ┌──────────────┐
     │            │Battle Service│
     │            │- Status:     │
     │            │  Accepted   │
     │            │- Get Qs     │
     └────────────┼──────────────┘
                  │
                  │ 5. Both Users Get Questions
                  │    Same questions (daily quiz)
                  │
     ┌────────────┼──────────────┐
     │            │              │
     ▼            ▼              │
┌──────────┐ ┌──────────┐      │
│ User A   │ │ User B   │      │
│ Answers  │ │ Answers  │      │
└────┬─────┘ └────┬─────┘      │
     │            │              │
     │ 6. Submit  │ 6. Submit   │
     │    Answers │    Answers  │
     │            │              │
     └────────────┼──────────────┘
                  │
                  │ 7. Calculate Scores
                  ▼
         ┌──────────────┐
         │Battle Service│
         │- Compare     │
         │- Determine   │
         │  Winner      │
         └────┬─────────┘
              │
              │ 8. Award Bonus Points
              │    Winner: +5 points
              ▼
     ┌──────────────┐
     │Points Service│
     │- Add Bonus   │
     │- Update LB   │
     └──────────────┘
```

### 7.6 Workflow: Validation Admin

```
┌──────────┐
│  Admin   │
│ (Web UI) │
└────┬─────┘
     │
     │ 1. Navigate to Validation
     │    GET /admin/questions/pending
     ▼
┌──────────────┐
│ Admin Panel  │
│ - Fetch      │
│   Pending    │
└────┬─────────┘
     │
     │ 2. Query Database
     │    WHERE status = 'pending'
     │    AND date = '2024-12-21'
     ▼
┌──────────────┐
│   MySQL      │
│   Database   │
└────┬─────────┘
     │
     │ 3. Return Questions
     │    [{id, question, options, answer, explanation}]
     ▼
┌──────────┐
│  Admin   │
│ Reviews  │
│ Questions│
└────┬─────┘
     │
     │ 4. For each question:
     │    - Read question
     │    - Check options
     │    - Verify answer
     │    - Review explanation
     │
     │    Action: Validate / Edit / Delete
     │
     │ 5a. Validate
     │     POST /admin/questions/{id}/validate
     │
     │ 5b. Edit
     │     PUT /admin/questions/{id}
     │     {question, options, answer, explanation}
     │     Then validate
     │
     │ 5c. Delete
     │     DELETE /admin/questions/{id}
     ▼
┌──────────────┐
│Validation API│
│- Update      │
│  Status      │
│- Link to Date│
└────┬─────────┘
     │
     │ 6. Check if all questions validated
     │    for date 2024-12-21
     │
     │    If YES:
     │    - Update daily_quiz status → 'ready'
     │    - Notify admin
     │
     │    If NO:
     │    - Keep status 'pending'
     ▼
┌──────────────┐
│   MySQL      │
│   Database   │
└──────────────┘
```

### 7.7 Architecture de Données

#### Relations entre Entités Principales

```
┌──────────────┐
│    User      │
│  (tbl_user)  │
└──────┬───────┘
       │
       │ 1:N
       │
       ├──────────────────┬──────────────────┐
       │                  │                  │
       ▼                  ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Group Member │  │ User Points  │  │   Battle      │
│(tbl_group_   │  │(tbl_user_    │  │(tbl_battle)   │
│  member)     │  │  points)     │  │               │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                  │
       │ N:1             │ N:1               │ N:1
       │                 │                  │
       ▼                 ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│    Group     │  │    Topic     │  │    Group     │
│(tbl_group)   │  │(tbl_topic)   │  │(tbl_group)   │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                  │
       │                 │                  │
       │ N:N             │ N:N              │
       │                 │                  │
       └─────────┬───────┴──────────────────┘
                 │
                 ▼
        ┌──────────────┐
        │ Group Topic  │
        │(tbl_group_   │
        │  topic)     │
        └──────────────┘

┌──────────────┐
│ Daily Text   │
│(tbl_daily_   │
│  text)       │
└──────┬───────┘
       │
       │ 1:N
       │
       ▼
┌──────────────┐
│ Question     │
│(tbl_question)│
└──────┬───────┘
       │
       │ 1:1
       │
       ▼
┌──────────────┐
│ Validation   │
│(tbl_question_│
│  validation) │
└──────────────┘
```

#### Flux de Données: Points et Classements

```
┌──────────────┐
│ User Action  │
│ - Read Text  │
│ - Answer Quiz│
│ - Win Battle │
└──────┬───────┘
       │
       │ Calculate Points
       ▼
┌──────────────┐
│ User Points  │
│(tbl_user_    │
│  points)     │
│ - user_id    │
│ - group_id   │
│ - topic_id   │
│ - date       │
│ - points     │
└──────┬───────┘
       │
       │ Aggregate
       │
       ├──────────────┬──────────────┬──────────────┐
       │              │              │              │
       ▼              ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Daily        │ │ Weekly       │ │ Monthly      │ │ Yearly        │
│ Leaderboard  │ │ Leaderboard  │ │ Leaderboard  │ │ Leaderboard   │
│ SUM by date  │ │ SUM by week  │ │ SUM by month │ │ SUM by year   │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
       │                │                 │                │
       │                │                 │                │
       └────────────────┼─────────────────┼────────────────┘
                        │                 │
                        │ Cache Results   │
                        ▼                 ▼
                ┌──────────────┐  ┌──────────────┐
                │ Redis Cache  │  │   MySQL      │
                │ TTL: 1h      │  │   Views      │
                └──────────────┘  └──────────────┘
```

---

## 8. Patterns de Communication

### 8.1 Synchronous Communication

**Utilisé pour:**
- Requêtes utilisateur (mobile → API)
- Validation immédiate
- Lecture de données

**Pattern:**
```
Mobile App → API Gateway → Service → Database
         ←                ←         ←
```

### 8.2 Asynchronous Communication

**Utilisé pour:**
- Génération de questions (PDF → QCM)
- Calcul des classements
- Envoi de notifications
- Traitement des battles

**Pattern avec Queue:**
```
Admin Panel → Queue → Worker → Service → Database
                    ↓
              (Retry Logic)
                    ↓
              (Dead Letter Queue)
```

### 8.3 Event-Driven Communication (Phase 2)

**Utilisé pour:**
- Mise à jour des classements
- Notifications en temps réel
- Synchronisation entre services

**Pattern:**
```
Service A → Event Bus → Service B, C, D
         (RabbitMQ / Kafka)
```

### 8.4 Matrice d'Interactions

| Composant Source | Composant Destination | Type | Protocole | Fréquence |
|------------------|----------------------|------|-----------|-----------|
| Mobile App | API Gateway | Request/Response | HTTPS | Haute |
| API Gateway | Admin API | Request/Response | HTTP | Haute |
| Admin API | MySQL | Query | MySQL | Très Haute |
| Admin API | Redis | Get/Set | Redis | Très Haute |
| Admin Panel | Admin API | Request/Response | HTTP | Moyenne |
| Admin Panel | Queue | Job Submission | Queue | Basse |
| Queue | PDF Worker | Job Processing | Queue | Basse |
| PDF Worker | Ollama | API Call | HTTP | Moyenne |
| PDF Worker | AI API | Store Questions | HTTP | Basse |
| Admin API | Queue | Async Job | Queue | Moyenne |
| Queue Worker | MySQL | Update | MySQL | Moyenne |
| Queue Worker | Redis | Cache Update | Redis | Moyenne |
| Notification Service | Mobile App | Push | FCM | Basse |

---

## 9. Déploiement

### 9.1 Architecture de Déploiement (Phase 1)

```
┌─────────────────────────────────────────────────────────────┐
│                    LOAD BALANCER (Nginx)                     │
│                    SSL Certificate                           │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  Admin API   │ │  Admin API   │ │  Admin API   │
│  Instance 1  │ │  Instance 2  │ │  Instance 3  │
│  (Docker)    │ │  (Docker)    │ │  (Docker)    │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘
       │                │                │
       └────────────────┼────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   MySQL      │ │    Redis     │ │   Queue      │
│   Primary    │ │    Cache     │ │   Workers    │
│   (Docker)   │ │   (Docker)   │ │   (Docker)   │
└──────────────┘ └──────────────┘ └──────────────┘
```

### 9.2 Docker Compose Configuration

**Recommandation pour Production:**

```yaml
services:
  # Load Balancer
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - admin-api-1
      - admin-api-2

  # Admin API Instances
  admin-api-1:
    build: ./admin
    environment:
      - DB_HOST=mysql
      - REDIS_HOST=redis
    depends_on:
      - mysql
      - redis

  admin-api-2:
    build: ./admin
    environment:
      - DB_HOST=mysql
      - REDIS_HOST=redis
    depends_on:
      - mysql
      - redis

  # Database
  mysql:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=${DB_PASSWORD}
      - MYSQL_DATABASE=elite_quiz_237
    volumes:
      - mysql-data:/var/lib/mysql
      - ./backups:/backups

  # Cache
  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data

  # Queue Workers
  queue-worker:
    build: ./admin
    command: php artisan queue:work --tries=3
    depends_on:
      - mysql
      - redis
    deploy:
      replicas: 3

volumes:
  mysql-data:
  redis-data:
```

### 9.3 Déploiement Progressif

**Étape 1: Monolithique avec Load Balancer**
- 2-3 instances Admin API
- Load balancer Nginx
- MySQL + Redis

**Étape 2: Séparation API/Web**
- Admin Web Panel (séparé)
- API Services (séparés)
- Communication via API

**Étape 3: Microservices**
- Services indépendants
- API Gateway
- Service Mesh (optionnel)

### 9.4 Recommandations par Environnement

#### Development

**Minimal Setup:**
- 1 instance de chaque service
- Pas de load balancer
- Pas de replicas
- Local storage

**Docker Compose:**
```yaml
services:
  admin-api: 1 instance
  mysql: 1 instance
  redis: 1 instance
  queue-worker: 1 instance
```

#### Staging

**Production-like Setup:**
- 2 instances API (load balanced)
- 1 primary + 1 replica MySQL
- 1 Redis instance
- 2 queue workers
- Monitoring basique

#### Production

**High Availability:**
- 3+ instances API (load balanced)
- 1 primary + 2 replicas MySQL
- Redis Cluster (3 nodes)
- 3+ queue workers
- Monitoring complet
- Auto-scaling configuré

---

## 10. Scalabilité

### 10.1 Stratégies de Scaling

#### Horizontal Scaling (Recommandé)

**Admin API:**
- Ajouter des instances selon la charge
- Load balancer distribue les requêtes
- Stateless design (pas de session serveur)

**Database:**
- Read replicas pour les lectures
- Write sur primary uniquement
- Connection pooling

**Cache:**
- Redis Cluster (3+ nodes)
- Sharding par clé

#### Vertical Scaling (Temporaire)

- Augmenter CPU/RAM des instances
- Solution rapide mais limitée

### 10.2 Optimisations de Performance

#### Caching Strategy

```php
// Questions fréquentes
Cache::remember("questions:daily:{$date}", 3600, function() {
    return Question::whereDate('date', $date)->get();
});

// Classements (1h pour daily, 24h pour weekly/monthly)
Cache::remember("leaderboard:daily:{$groupId}:{$topicId}:{$date}", 3600, function() {
    return LeaderboardService::calculateDaily($groupId, $topicId, $date);
});

// User points (5 minutes)
Cache::remember("user:points:{$userId}:{$date}", 300, function() {
    return UserPoints::where('user_id', $userId)->where('date', $date)->first();
});
```

#### Database Optimizations

```sql
-- Indexes recommandés
CREATE INDEX idx_daily_quiz_date ON tbl_daily_quiz(date_published);
CREATE INDEX idx_user_points_user_date ON tbl_user_points(user_id, date);
CREATE INDEX idx_user_points_group_topic_date ON tbl_user_points(group_id, topic_id, date);
CREATE INDEX idx_battle_status_date ON tbl_battle(status, date);
CREATE INDEX idx_group_member_user ON tbl_group_member(user_id, status);
```

#### Query Optimization

- Utiliser `SELECT` spécifique (éviter `SELECT *`)
- Pagination pour grandes listes
- Eager loading pour relations
- Query caching

### 10.3 Capacity Planning

**Estimations (10,000 utilisateurs actifs):**

| Composant | Instances | CPU | RAM | Storage |
|-----------|-----------|-----|-----|---------|
| Admin API | 3 | 2 cores | 2GB | - |
| MySQL | 1 primary + 1 replica | 4 cores | 8GB | 100GB |
| Redis | 1 | 2 cores | 4GB | - |
| Queue Workers | 3 | 1 core | 1GB | - |
| AI API | 2 | 2 cores | 4GB | - |
| PDF Workers | 2 | 2 cores | 2GB | - |

### 10.4 Coûts Estimés (Cloud Providers)

#### AWS

| Service | Instance Type | Monthly Cost (USD) |
|---------|---------------|-------------------|
| EC2 (API) | t3.medium (3x) | ~$90 |
| RDS MySQL | db.t3.medium | ~$60 |
| ElastiCache Redis | cache.t3.medium | ~$30 |
| Load Balancer | ALB | ~$20 |
| **Total** | | **~$200/month** |

#### DigitalOcean

| Service | Instance Type | Monthly Cost (USD) |
|---------|---------------|-------------------|
| Droplets (API) | 2GB RAM (3x) | ~$36 |
| Managed MySQL | 2GB RAM | ~$30 |
| Managed Redis | 1GB RAM | ~$15 |
| Load Balancer | Basic | ~$12 |
| **Total** | | **~$93/month** |

#### Google Cloud

| Service | Instance Type | Monthly Cost (USD) |
|---------|---------------|-------------------|
| Compute Engine | e2-medium (3x) | ~$75 |
| Cloud SQL | db-f1-micro | ~$10 |
| Memorystore Redis | basic | ~$30 |
| Load Balancer | Standard | ~$20 |
| **Total** | | **~$135/month** |

---

## 11. Sécurité

### 11.1 Authentification et Autorisation

**Mobile App:**
- Firebase Auth (Google, Apple)
- JWT tokens pour API
- Refresh tokens avec rotation

**Admin Panel:**
- Session-based auth
- RBAC (Role-Based Access Control)
- Permissions granulaires

**API Services:**
- Laravel Sanctum pour API tokens
- Rate limiting par utilisateur/IP
- CORS configuration stricte

### 11.2 Sécurité des Données

- **Encryption:** HTTPS/TLS 1.3
- **Database:** Encryption at rest
- **Sensitive Data:** Hashing (bcrypt pour passwords)
- **API Keys:** Stockage sécurisé (env variables)

### 11.3 Protection contre les Abus

- **Rate Limiting:**
  - Mobile API: 100 req/min par utilisateur
  - Public endpoints: 20 req/min par IP
  - Admin endpoints: 1000 req/min

- **Input Validation:**
  - Validation côté serveur (obligatoire)
  - Sanitization des inputs
  - Protection SQL injection (prepared statements)

- **DDoS Protection:**
  - Cloudflare / AWS Shield
  - Rate limiting au niveau gateway

---

## 12. Monitoring et Observabilité

### 12.1 Métriques à Surveiller

**Application:**
- Response time (p50, p95, p99)
- Error rate (4xx, 5xx)
- Request rate (req/sec)
- Active users

**Infrastructure:**
- CPU usage
- Memory usage
- Disk I/O
- Network traffic
- Database connections

**Business:**
- Daily active users
- Quiz completions
- Battle participation
- Points distribution

### 12.2 Outils Recommandés

**Phase 1 (Simple):**
- Laravel Telescope (dev/staging)
- MySQL slow query log
- Nginx access logs
- Basic health checks

**Phase 2 (Production):**
- **APM:** New Relic / Datadog / Sentry
- **Logs:** ELK Stack / Loki
- **Metrics:** Prometheus + Grafana
- **Uptime:** UptimeRobot / Pingdom

### 12.3 Alertes

**Critiques:**
- Database down
- API error rate > 5%
- Response time > 2s (p95)
- Disk space < 20%

**Warnings:**
- CPU usage > 80%
- Memory usage > 85%
- Queue backlog > 1000 jobs
- Cache hit rate < 70%

---

## 13. Recommandations par Phase

### Phase 1: Amélioration Progressive (Mois 1-3)

**Priorités:**
1. ✅ Ajouter Redis pour cache
2. ✅ Implémenter queue pour tâches longues
3. ✅ Séparer API et Web controllers
4. ✅ Ajouter rate limiting
5. ✅ Monitoring basique

**Instances:**
- Admin API: 2 instances
- MySQL: 1 instance + backup
- Redis: 1 instance
- Queue Workers: 2 instances

### Phase 2: Refactoring (Mois 4-6)

**Priorités:**
1. ✅ Créer services séparés (Quiz, Group, User)
2. ✅ Implémenter Repository pattern
3. ✅ API Gateway
4. ✅ Monitoring avancé
5. ✅ Tests automatisés

**Instances:**
- API Gateway: 1 instance
- Quiz Service: 2 instances
- Group Service: 2 instances
- User Service: 2 instances
- MySQL: 1 primary + 1 replica
- Redis: Cluster (3 nodes)

### Phase 3: Microservices (Mois 7-12)

**Priorités:**
1. ✅ Services complètement indépendants
2. ✅ Event-driven architecture
3. ✅ Service mesh (optionnel)
4. ✅ Auto-scaling
5. ✅ Multi-region (optionnel)

---

## 14. Checklist d'Implémentation

### Infrastructure
- [ ] Setup Load Balancer (Nginx)
- [ ] Configure Redis Cache
- [ ] Setup Queue System (Laravel Queue / RabbitMQ)
- [ ] Database Backup Strategy
- [ ] SSL Certificates
- [ ] Monitoring Setup

### Code
- [ ] Refactor Admin API (séparer controllers)
- [ ] Create Service Layer
- [ ] Implement Repository Pattern
- [ ] Add Caching Layer
- [ ] Add Queue Jobs
- [ ] API Documentation (OpenAPI/Swagger)

### Security
- [ ] Rate Limiting
- [ ] Input Validation
- [ ] SQL Injection Protection
- [ ] XSS Protection
- [ ] CSRF Protection
- [ ] Security Headers

### Testing
- [ ] Unit Tests
- [ ] Integration Tests
- [ ] API Tests
- [ ] Load Tests
- [ ] Security Tests

---

**Document créé le:** Décembre 2024  
**Dernière mise à jour:** Décembre 2024  
**Version:** 1.0  
**Auteur:** Architecture Team
