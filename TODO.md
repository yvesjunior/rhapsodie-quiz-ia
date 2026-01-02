# Rhapsodie Quiz IA - TODO

**Focus MVP:** Rhapsody + Foundation School  
**Modes:** Solo, 1v1, Multiplayer, Contest

---

## 📊 Structure

```
TOPICS
├── Foundation School (Training)
│   └── Categories = Modules
│       ├── Module 1: Contenu + Quiz
│       ├── Module 2: Contenu + Quiz
│       └── ...
│
└── Rhapsody (Daily Quiz)
    └── Categories = Year → Month → Day
        └── Day: Texte + Quiz

MODES DE JEU
├── Solo Mode
│   └── Utilisateur choisit Topic → Category → Joue seul
│
├── 1v1 Mode
│   └── Challenger choisit Topic → Category → Défie un adversaire
│
├── Multiplayer Mode (Group Battle)
│   └── Group Owner invite membres → Battle sur Topic/Category
│
└── Contest (Daily Challenge)
    └── Quiz quotidien pour TOUS (basé sur Rhapsody)
```

---

## 🎮 Modes de Jeu

### 1. Solo Mode
- [ ] Sélection Topic (Foundation School OU Rhapsody)
- [ ] Sélection Category:
  - FS: Module 1, Module 2, ...
  - Rhapsody: Year → Month → Day
- [ ] Quiz interface
- [ ] Résultats et score

### 2. 1v1 Mode
- [ ] Sélection Topic + Category
- [ ] Recherche/Sélection adversaire
- [ ] Envoi invitation
- [ ] Acceptation/Refus
- [ ] Battle (mêmes questions)
- [ ] Résultats et gagnant
- [ ] Points bonus pour le gagnant

### 3. Multiplayer Mode (Group Battle)
- [ ] Création de groupe
- [ ] Invitation de membres (code ou recherche)
- [ ] Gestion des membres
- [ ] Lancement battle (Topic + Category)
- [ ] Tous les membres jouent
- [ ] Classement du groupe

### 4. Contest (Daily Challenge)
- [x] Contest quotidien automatique (cron job with ENV control)
- [x] Basé sur Rhapsody du jour
- [x] Accessible à TOUS
- [x] Classement global (tied ranking: same score = same rank)
- [x] Timer 30s per question
- [x] Bell icon notification marker with animation
- [x] Weekly Rewards (1st: 50 coins, 2nd: 30 coins, 3rd: 20 coins)

---

## 🎯 Topics

### Foundation School (Training)
- [ ] Liste des modules
- [ ] Contenu pédagogique (texte, vidéo, audio)
- [ ] Quiz de compréhension
- [ ] Progression séquentielle (self-paced)

### Rhapsody (Daily Quiz)
- [ ] Navigation Year → Month → Day
- [ ] Texte du jour
- [ ] Quiz (10 questions)
- [ ] Points quotidiens

---

## 📋 Phases de Développement

### Phase 1: Backend Core (Semaines 1-3)

**Tables:**
- [ ] `tbl_user` (utilisateurs)
- [ ] `tbl_topic` (rhapsody, foundation_school)
- [ ] `tbl_category` (modules, year/month/day)
- [ ] `tbl_question` (questions)
- [ ] `tbl_user_progress` (progression)

**API:**
- [ ] Auth: login, register, profile
- [ ] Topics: list, get
- [ ] Categories: list by topic, get
- [ ] Questions: get by category
- [ ] Progress: get, update

### Phase 2: Game Modes (Semaines 4-5)

**Tables:**
- [ ] `tbl_battle_1v1` (1v1 battles)
- [ ] `tbl_group` (groupes)
- [ ] `tbl_group_member` (membres)
- [ ] `tbl_group_battle` (battles de groupe)
- [ ] `tbl_contest` (contest quotidien)

**API:**
- [ ] Solo: submit quiz
- [ ] 1v1: create, accept, submit, results
- [ ] Group: create, invite, join, battle
- [ ] Contest: get today, submit, leaderboard

### Phase 3: Mobile App (Semaines 6-9)

**Écrans:**
- [ ] Home (modes de jeu)
- [ ] Topic Selection
- [ ] Category Selection
- [ ] Quiz Interface
- [ ] Results
- [ ] 1v1 Battle
- [ ] Group Management
- [ ] Contest
- [ ] Leaderboards
- [ ] Profile

### Phase 4: Polish (Semaine 10)

- [ ] Notifications push (see APNs setup below)
- [x] Animations (bell icon shake, contest markers)
- [ ] Tests
- [ ] Bug fixes

---

## 🔔 APNs + Firebase Push Notifications

**Status:** ✅ COMPLETED

| # | Task | Status |
|---|------|--------|
| 1 | Wait for Apple Developer account renewal activation | ✅ Done |
| 2 | Create APNs Authentication Key (.p8) in Apple Developer portal | ✅ Done |
| 3 | Upload APNs key to Firebase Console (Cloud Messaging tab) | ✅ Done |
| 4 | Rebuild iOS app and test FCM push notifications | ✅ Done |
| 5 | Verify push notifications work on real iOS device | ✅ Done |

**Note:** iOS Simulator cannot receive FCM push notifications (Apple limitation). Real devices work perfectly.

---

## 📴 Offline-First Implementation

**Status:** ✅ COMPLETED

**Goal:** App works without internet, syncs automatically when online.

| Priority | Feature | Files Created | Status |
|----------|---------|---------------|--------|
| **P0** | Core Infrastructure | `cache_manager.dart`, `connectivity_cubit.dart`, `pending_operations.dart`, `sync_service.dart` | ✅ Done |
| **P1** | Rhapsody Content | `rhapsody_local_data_source.dart`, `rhapsody_repository.dart` | ✅ Done |
| **P2** | Quiz Questions | `quiz_local_data_source.dart`, updated `quiz_repository.dart` | ✅ Done |
| **P3** | Daily Contest | `daily_contest_local_data_source.dart`, updated `quiz_repository.dart` | ✅ Done |
| **P4** | User Profile | Uses existing Hive-based local storage | ✅ Done |
| **P5** | System Config | `system_config_local_data_source.dart`, updated `system_config_repository.dart` | ✅ Done |
| **P6** | Topics/Categories | Uses Quiz cache infrastructure | ✅ Done |
| **P7** | Foundation School | `foundation_local_data_source.dart`, `foundation_repository.dart` | ✅ Done |
| **P8** | Statistics/Badges | `statistic_local_data_source.dart`, `badges_local_data_source.dart`, updated repositories | ✅ Done |

**Key Features:**
- **Automatic caching** after first load
- **Background refresh** when online (stale-while-revalidate)
- **Offline access** to all cached content
- **Queue submissions** for daily contest when offline
- **Connectivity monitoring** via `ConnectivityCubit`

**Documentation:** See `docs/OFFLINE_IMPLEMENTATION.md` for architecture details.

---

## 🚀 Next Release Features

- [ ] Enable Groups button in header (home_screen.dart)
- [ ] Enable Play Zone tab in bottom navigation (dashboard_screen.dart)
- [ ] Enable Multiplayer Mode card on home screen

---

## ✅ Completed

### Push Notifications
- [x] Update FCM to use v1 API with service account
- [x] FCM topic-based delivery (daily_quiz topic)
- [x] APNs key created and uploaded to Firebase
- [x] Push notifications working on real iOS device
- [x] Notification scheduler (cron jobs at 8AM, 1PM, 10PM)

### Daily Contest
- [x] Daily Contest API endpoints (today, submit, leaderboard)
- [x] Link Rhapsody Day to Daily Contest creation
- [x] Contest scheduler command with ENV control (DAILY_CONTEST_AUTO_CREATE)
- [x] Daily Contest screen UI (text + 5 questions)
- [x] Contest API and leaderboard integration
- [x] Question timer (30s) for Daily Contest
- [x] Bell icon notification marker with shake animation
- [x] Expiration check for daily contests
- [x] Tied ranking for leaderboards (same score = same rank)
- [x] Weekly rewards system (1st: 50, 2nd: 30, 3rd: 20 gold coins)
- [x] Weekly rewards cron job (Sunday 11:59 PM)

### App Configuration
- [x] Update bundle ID to com.rhapsodyquizz.app
- [x] Register new apps in Firebase Console
- [x] Timezone sync (America/Montreal)
- [x] Split Profile into Profile and Settings tabs

### Documentation
- [x] Architecture documentation (docs/ARCHITECTURE.md)
- [x] Offline implementation plan (docs/OFFLINE_IMPLEMENTATION.md)

---

## 🔮 Topics Futurs (Post-MVP)

- Bible
- Heroes of Faith
- Love World News
- History

---

**Dernière mise à jour:** 31 Décembre 2025
