# 📴 Offline-First Implementation Plan

## Overview

Implement offline-first architecture to allow the app to function without internet connectivity, with automatic sync when online.

---

## 🎯 Goals

1. **Load Once, Work Offline** - Content is cached after first load
2. **Automatic Sync** - Background sync when connectivity is restored
3. **Queue Operations** - Offline writes are queued and synced later
4. **No Expiration** - Cached data stays valid until refreshed
5. **Seamless UX** - Users shouldn't notice online/offline transitions

---

## 📊 Priority Matrix

| Priority | Feature | Effort | Impact | Status |
|----------|---------|--------|--------|--------|
| **P1** | Rhapsody Content | 3 days | 🔴 Critical | ⏳ Pending |
| **P2** | Quiz Questions | 3 days | 🔴 Critical | ⏳ Pending |
| **P3** | Daily Contest | 2 days | 🔴 Critical | ⏳ Pending |
| **P4** | User Profile | 1 day | 🟡 High | ⏳ Pending |
| **P5** | System Config | 1 day | 🟡 High | ⏳ Pending |
| **P6** | Topics/Categories | 1 day | 🟢 Medium | ⏳ Pending |
| **P7** | Foundation | 2 days | 🟢 Medium | ⏳ Pending |
| **P8** | Statistics/Badges | 1 day | 🟢 Medium | ⏳ Pending |

**Total Estimated Effort:** 14 days

---

## 🏗️ Phase 0: Core Infrastructure

### Task 0.1: Create Offline Core Module
**File:** `lib/core/offline/offline.dart`

```dart
// Barrel export for offline module
export 'cache_manager.dart';
export 'connectivity_cubit.dart';
export 'sync_service.dart';
export 'pending_operations.dart';
```

### Task 0.2: Cache Manager
**File:** `lib/core/offline/cache_manager.dart`

```dart
class CacheManager {
  static const String _cacheBox = 'cache';
  
  // Generic cache with metadata
  Future<void> cache<T>(String key, T data);
  Future<T?> get<T>(String key);
  Future<void> clear(String key);
  Future<DateTime?> getLastUpdated(String key);
}
```

### Task 0.3: Connectivity Cubit
**File:** `lib/core/offline/connectivity_cubit.dart`

```dart
class ConnectivityCubit extends Cubit<ConnectivityState> {
  // Monitor network state
  // Emit online/offline events
  // Trigger sync when back online
}
```

### Task 0.4: Sync Service
**File:** `lib/core/offline/sync_service.dart`

```dart
class SyncService {
  // Background sync when online
  Future<void> syncAll();
  Future<void> syncPendingOperations();
  Future<void> refreshCache(String feature);
}
```

### Task 0.5: Pending Operations Queue
**File:** `lib/core/offline/pending_operations.dart`

```dart
class PendingOperations {
  // Queue offline writes
  Future<void> queue(PendingOperation op);
  Future<List<PendingOperation>> getAll();
  Future<void> markComplete(String id);
}
```

---

## 📖 Phase 1: Rhapsody Content (Priority 1)

### Task 1.1: Create Local Data Source
**File:** `lib/features/rhapsody/rhapsody_local_data_source.dart`

```dart
class RhapsodyLocalDataSource {
  // Cache operations
  Future<void> cacheYears(List<RhapsodyYear> years);
  Future<void> cacheMonths(int year, List<RhapsodyMonth> months);
  Future<void> cacheDays(int year, int month, List<RhapsodyDay> days);
  Future<void> cacheDayDetail(RhapsodyDayDetail detail);
  
  // Retrieve operations
  Future<List<RhapsodyYear>?> getCachedYears();
  Future<List<RhapsodyMonth>?> getCachedMonths(int year);
  Future<List<RhapsodyDay>?> getCachedDays(int year, int month);
  Future<RhapsodyDayDetail?> getCachedDayDetail(int year, int month, int day);
  
  // Cache status
  Future<bool> hasCachedContent(int year, int month, int day);
}
```

### Task 1.2: Create Repository
**File:** `lib/features/rhapsody/rhapsody_repository.dart`

```dart
class RhapsodyRepository {
  final RhapsodyRemoteDataSource _remote;
  final RhapsodyLocalDataSource _local;
  
  Future<List<RhapsodyYear>> getYears() async {
    // 1. Return cache immediately
    final cached = await _local.getCachedYears();
    if (cached != null) yield cached;
    
    // 2. If online, fetch fresh
    if (await isOnline()) {
      final fresh = await _remote.getRhapsodyYears();
      await _local.cacheYears(fresh);
      yield fresh;
    }
  }
}
```

### Task 1.3: Update Cubit
Modify `RhapsodyCubit` to use repository instead of direct remote calls.

### Task 1.4: Add Hive Box
**File:** `lib/core/constants/hive_constants.dart`

```dart
const rhapsodyBox = 'rhapsody';
const rhapsodyYearsKey = 'years';
const rhapsodyMonthsPrefix = 'months_';    // months_2025
const rhapsodyDaysPrefix = 'days_';        // days_2025_1
const rhapsodyDetailPrefix = 'detail_';    // detail_2025_1_1
```

---

## ❓ Phase 2: Quiz Questions (Priority 2)

### Task 2.1: Create Quiz Local Data Source
**File:** `lib/features/quiz/quiz_local_data_source.dart`

```dart
class QuizLocalDataSource {
  // Cache by category
  Future<void> cacheQuestions(String categoryId, List<Question> questions);
  Future<List<Question>?> getCachedQuestions(String categoryId);
  
  // Cache categories
  Future<void> cacheCategories(List<QuizCategory> categories);
  Future<List<QuizCategory>?> getCachedCategories();
  
  // Cache subcategories
  Future<void> cacheSubCategories(String categoryId, List<SubCategory> subs);
  Future<List<SubCategory>?> getCachedSubCategories(String categoryId);
}
```

### Task 2.2: Update Quiz Repository
Add offline-first logic to existing `quiz_repository.dart`.

### Task 2.3: Cache Question Types
- Regular questions
- Audio questions
- Guess the word
- Fun and learn
- Self challenge

---

## 🏆 Phase 3: Daily Contest (Priority 3)

### Task 3.1: Create Contest Local Data Source
**File:** `lib/features/quiz/daily_contest_local_data_source.dart`

```dart
class DailyContestLocalDataSource {
  // Cache today's contest
  Future<void> cacheTodayContest(Map<String, dynamic> contest);
  Future<Map<String, dynamic>?> getCachedTodayContest();
  
  // Queue submission for sync
  Future<void> queueSubmission(DailyContestSubmission submission);
  Future<List<DailyContestSubmission>> getPendingSubmissions();
}
```

### Task 3.2: Update Daily Contest Cubit
Handle offline quiz taking and queued submissions.

### Task 3.3: Sync Submissions
When back online, submit queued quiz results.

---

## 👤 Phase 4: User Profile (Priority 4)

### Task 4.1: Extend Profile Local Data Source
Already exists, add sync capabilities.

```dart
// Add to profile_management_local_data_source.dart
Future<void> queueProfileUpdate(Map<String, dynamic> updates);
Future<void> syncProfile();
```

### Task 4.2: Update Profile Repository
Add offline-first pattern to `profile_management_repository.dart`.

---

## 🔧 Phase 5: System Config (Priority 5)

### Task 5.1: Create System Config Local Data Source
**File:** `lib/features/system_config/system_config_local_data_source.dart`

```dart
class SystemConfigLocalDataSource {
  Future<void> cacheConfig(SystemConfig config);
  Future<SystemConfig?> getCachedConfig();
  
  Future<void> cacheLanguages(List<SupportedLanguage> languages);
  Future<List<SupportedLanguage>?> getCachedLanguages();
}
```

### Task 5.2: Update System Config Repository
Ensure app can start with cached config when offline.

---

## 📚 Phase 6: Topics/Categories (Priority 6)

### Task 6.1: Create Topics Local Data Source
**File:** `lib/features/topics/topics_local_data_source.dart`

```dart
class TopicsLocalDataSource {
  Future<void> cacheTopics(List<Topic> topics);
  Future<List<Topic>?> getCachedTopics();
  
  Future<void> cacheTopicCategories(String topicId, List<TopicCategory> cats);
  Future<List<TopicCategory>?> getCachedTopicCategories(String topicId);
}
```

---

## 🎓 Phase 7: Foundation (Priority 7)

### Task 7.1: Create Foundation Local Data Source
**File:** `lib/features/foundation/foundation_local_data_source.dart`

```dart
class FoundationLocalDataSource {
  Future<void> cacheModules(List<FoundationModule> modules);
  Future<List<FoundationModule>?> getCachedModules();
  
  Future<void> cacheClasses(String moduleId, List<FoundationClass> classes);
  Future<List<FoundationClass>?> getCachedClasses(String moduleId);
  
  Future<void> cacheClassDetail(FoundationClassDetail detail);
  Future<FoundationClassDetail?> getCachedClassDetail(String classId);
}
```

---

## 🎖️ Phase 8: Statistics/Badges (Priority 8)

### Task 8.1: Create Stats Local Data Source
**File:** `lib/features/statistic/statistic_local_data_source.dart`

### Task 8.2: Create Badges Local Data Source
**File:** `lib/features/badges/badges_local_data_source.dart`

---

## 📋 Implementation Checklist

### Phase 0: Core Infrastructure
- [ ] Create `lib/core/offline/` directory
- [ ] Implement `CacheManager`
- [ ] Implement `ConnectivityCubit`
- [ ] Implement `SyncService`
- [ ] Implement `PendingOperations`
- [ ] Add connectivity listener in `main.dart`
- [ ] Add offline indicator widget

### Phase 1: Rhapsody
- [ ] Create `RhapsodyLocalDataSource`
- [ ] Create `RhapsodyRepository`
- [ ] Update `RhapsodyCubit` to use repository
- [ ] Add Hive box constants
- [ ] Test offline reading

### Phase 2: Quiz
- [ ] Create `QuizLocalDataSource`
- [ ] Update `QuizRepository`
- [ ] Update question cubits
- [ ] Test offline quiz taking

### Phase 3: Daily Contest
- [ ] Create `DailyContestLocalDataSource`
- [ ] Update `DailyContestCubit`
- [ ] Implement submission queue
- [ ] Test offline contest + sync

### Phase 4: User Profile
- [ ] Extend `ProfileLocalDataSource`
- [ ] Update `ProfileRepository`
- [ ] Test profile sync

### Phase 5: System Config
- [ ] Create `SystemConfigLocalDataSource`
- [ ] Update `SystemConfigRepository`
- [ ] Test app startup offline

### Phase 6: Topics
- [ ] Create `TopicsLocalDataSource`
- [ ] Update topics repository
- [ ] Test navigation offline

### Phase 7: Foundation
- [ ] Create `FoundationLocalDataSource`
- [ ] Update foundation repository
- [ ] Test learning content offline

### Phase 8: Stats/Badges
- [ ] Create local data sources
- [ ] Update repositories
- [ ] Test achievement display

---

## 🧪 Testing Strategy

1. **Unit Tests:** Test each local data source
2. **Integration Tests:** Test repository offline/online logic
3. **Manual Tests:**
   - Enable airplane mode
   - Verify cached content loads
   - Take quiz offline
   - Go online, verify sync

---

## 📅 Timeline

| Week | Phases | Deliverables |
|------|--------|--------------|
| Week 1 | Phase 0, 1 | Core infra, Rhapsody offline |
| Week 2 | Phase 2, 3 | Quiz + Daily Contest offline |
| Week 3 | Phase 4, 5, 6 | Profile, Config, Topics |
| Week 4 | Phase 7, 8 | Foundation, Stats, Testing |

---

## 📝 Notes

- Hive is used for local storage (already in project)
- No cache expiration - data stays until manually refreshed
- Automatic refresh happens when app goes online
- Pending operations are persisted and survive app restart

---

## 📅 Last Updated

December 31, 2025

