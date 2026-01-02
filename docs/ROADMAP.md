# Rhapsody Quiz - Product Roadmap

## Version 1.0 (Current Release)

### ✅ Completed Features

#### Core Quiz Features
- [x] Rhapsody daily devotional quizzes
- [x] Foundation School quizzes
- [x] Solo Mode with lifelines (50/50, Audience Poll, Reset Time, Skip)
- [x] Daily Contest with leaderboard
- [x] Offline support with data prefetching

#### Multiplayer
- [x] 1v1 Random Battle
- [x] 1v1 Play with Friends (room codes)
- [x] Group Battle (up to 4 players)
- [x] Bot opponent for practice
- [x] Topic selection (Rhapsody/Foundation) for battles

#### Leaderboard & Rewards
- [x] Daily/Monthly/All-time leaderboards
- [x] Dense ranking for ties (ex aequo)
- [x] Weekly reward distribution
- [x] Coin rewards for quiz completion

#### Notifications
- [x] FCM push notifications for new contests
- [x] Local reminder notifications
- [x] Animated notification badge

#### Offline Support
- [x] Data prefetching on app start
- [x] Hive caching for all content
- [x] Graceful offline error handling

---

## Version 1.1 (Next Release)

### 🔄 Planned Features

#### Rhapsody Audience Variants
Expand Rhapsody to serve different age groups, all following the same Year/Month/Day structure:

| Variant | Target Audience | Description |
|---------|-----------------|-------------|
| **Rhapsody Adulte** | Adults (18+) | Standard daily devotional content |
| **Rhapsody Teevo** | Teenagers (13-17) | Teen-focused devotional content |
| **Rhapsody Kid** | Children (6-12) | Kid-friendly devotional content |

- [ ] Add audience variant selector in app settings or on first launch
- [ ] Backend: Add `audience_type` field to rhapsody tables
- [ ] Filter Year/Month/Day content by selected audience
- [ ] Allow switching audience in profile settings
- [ ] UI: Age-appropriate themes/icons per variant

**Database Schema Update:**
```sql
ALTER TABLE tbl_rhapsody_years ADD COLUMN audience_type ENUM('adulte', 'teevo', 'kid') DEFAULT 'adulte';
ALTER TABLE tbl_rhapsody_months ADD COLUMN audience_type ENUM('adulte', 'teevo', 'kid') DEFAULT 'adulte';
ALTER TABLE tbl_rhapsody_days ADD COLUMN audience_type ENUM('adulte', 'teevo', 'kid') DEFAULT 'adulte';
```

#### Performance & Optimization
- [ ] Image caching optimization
- [ ] Reduce app bundle size
- [ ] Lazy loading for large lists

#### User Experience
- [ ] Haptic feedback improvements
- [ ] Sound effect toggle in settings
- [ ] Dark mode refinements

#### Analytics
- [ ] Quiz completion tracking
- [ ] User engagement metrics
- [ ] Performance monitoring

---

## Version 2.0 (Future)

### 🎯 Major Features

#### Battle Room Provider Abstraction
> See [ARCHITECTURE.md](./ARCHITECTURE.md) for details

- [ ] Create abstract `BattleRoomProvider` interface
- [ ] Refactor Firestore to implement interface
- [ ] Build WebSocket provider alternative
- [ ] Add config flag for provider selection
- [ ] Deploy self-hosted WebSocket server

**Trigger**: Firebase costs > $100/month

#### Additional Quiz Modes
- [ ] Tournament mode (bracket-style competition)
- [ ] Team battles (2v2)
- [ ] Timed challenges

#### Social Features
- [ ] Friend list
- [ ] Direct challenge invites
- [ ] Share quiz results

#### Content
- [ ] User-generated questions (moderated)
- [ ] Multiple language support
- [ ] Audio questions

---

## Version 3.0 (Long-term)

### 🚀 Vision Features

- [ ] AI-powered question generation
- [ ] Personalized learning paths
- [ ] Achievement system & badges
- [ ] Premium subscription tier
- [ ] Web app companion
- [ ] Admin dashboard improvements

---

## Technical Debt

### High Priority
- [ ] Add unit tests for cubits
- [ ] Add integration tests for battle flow
- [ ] Improve error logging

### Medium Priority
- [ ] Refactor large screen files (>500 lines)
- [ ] Standardize error handling
- [ ] Document API endpoints

### Low Priority
- [ ] Migrate to null-safety improvements
- [ ] Update deprecated dependencies
- [ ] Code documentation

---

## Infrastructure Considerations

| Current | Future Alternative | Trigger |
|---------|-------------------|---------|
| Firebase Firestore | Self-hosted WebSocket | Costs > $100/mo |
| FCM | Keep (free) | N/A |
| PHP Backend | Consider Node.js | If WebSocket needed |
| MySQL | Keep | N/A |

---

## Release Schedule

| Version | Target | Status |
|---------|--------|--------|
| 1.0 | Q1 2026 | 🚧 In Progress |
| 1.1 | Q2 2026 | 📋 Planned |
| 2.0 | Q4 2026 | 📋 Planned |

---

*Last updated: 2026-01-02*

