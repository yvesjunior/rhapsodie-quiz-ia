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
- [ ] Contest quotidien automatique
- [ ] Basé sur Rhapsody du jour
- [ ] Accessible à TOUS
- [ ] Classement global
- [ ] Récompenses

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

- [ ] Notifications push
- [ ] Animations
- [ ] Tests
- [ ] Bug fixes

---

## 🔮 Topics Futurs (Post-MVP)

- Bible
- Heroes of Faith
- Love World News
- History

---

**Dernière mise à jour:** Décembre 2024
