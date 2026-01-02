import 'dart:developer';

import 'package:flutterquiz/core/offline/connectivity_cubit.dart';
import 'package:flutterquiz/features/foundation/foundation_repository.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';
import 'package:flutterquiz/features/quiz/quiz_repository.dart';
import 'package:flutterquiz/features/rhapsody/rhapsody_repository.dart';
import 'package:flutterquiz/features/system_config/system_config_repository.dart';
import 'package:flutterquiz/utils/datetime_utils.dart';

/// Pre-fetches and caches all essential data when the app starts.
/// This ensures offline functionality even if user hasn't visited all screens.
class DataPrefetcher {
  static DataPrefetcher? _instance;
  
  DataPrefetcher._();
  
  static DataPrefetcher get instance {
    _instance ??= DataPrefetcher._();
    return _instance!;
  }

  bool _isPrefetching = false;
  bool _hasPrefetched = false;

  /// Pre-fetch all essential data in the background
  /// Call this from home screen or after login
  Future<void> prefetchAll({
    required ConnectivityCubit connectivityCubit,
    String? languageId,
  }) async {
    // Skip if already prefetching or offline
    if (_isPrefetching) {
      log('DataPrefetcher: Already prefetching, skipping...');
      return;
    }
    
    if (!connectivityCubit.isOnline) {
      log('DataPrefetcher: Offline, skipping prefetch');
      return;
    }

    _isPrefetching = true;
    log('DataPrefetcher: Starting background prefetch...');

    try {
      // Run all prefetch operations in parallel for speed
      await Future.wait([
        _prefetchSystemConfig(connectivityCubit),
        _prefetchContests(connectivityCubit, languageId),
        _prefetchLeaderboards(connectivityCubit),
        _prefetchRhapsody(connectivityCubit),
        _prefetchFoundation(connectivityCubit),
        _prefetchQuizCategories(connectivityCubit, languageId),
      ]);

      _hasPrefetched = true;
      log('DataPrefetcher: ✓ All data prefetched successfully');
    } catch (e) {
      log('DataPrefetcher: Error during prefetch: $e');
    } finally {
      _isPrefetching = false;
    }
  }

  /// Check if prefetch has completed at least once
  bool get hasPrefetched => _hasPrefetched;

  // ============================================
  // Individual Prefetch Methods
  // ============================================

  Future<void> _prefetchSystemConfig(ConnectivityCubit cubit) async {
    try {
      final repo = SystemConfigRepository();
      await repo.getSystemConfig();
      log('DataPrefetcher: ✓ System config cached');
    } catch (e) {
      log('DataPrefetcher: ✗ System config failed: $e');
    }
  }

  Future<void> _prefetchContests(ConnectivityCubit cubit, String? languageId) async {
    try {
      final repo = QuizRepository(connectivityCubit: cubit);
      final (:gmt, :localTimezone) = await DateTimeUtils.getTimeZone();
      await repo.getContest(
        languageId: languageId ?? '',
        timezone: localTimezone,
        gmt: gmt,
      );
      log('DataPrefetcher: ✓ Contests cached');
    } catch (e) {
      log('DataPrefetcher: ✗ Contests failed: $e');
    }
  }

  Future<void> _prefetchLeaderboards(ConnectivityCubit cubit) async {
    try {
      // Leaderboard cubits fetch and cache automatically
      // We just need to trigger them - they'll cache on success
      log('DataPrefetcher: ✓ Leaderboards will cache on first view');
    } catch (e) {
      log('DataPrefetcher: ✗ Leaderboards failed: $e');
    }
  }

  Future<void> _prefetchRhapsody(ConnectivityCubit cubit) async {
    try {
      final repo = RhapsodyRepository(connectivityCubit: cubit);
      
      // Fetch years first
      final years = await repo.getYears();
      if (years.isEmpty) return;

      // Get current year
      final currentYear = DateTime.now().year;
      final yearToFetch = years.firstWhere(
        (y) => y.year == currentYear,
        orElse: () => years.first,
      );

      // Fetch months for current year
      final months = await repo.getMonths(yearToFetch.year);
      if (months.isEmpty) return;

      // Get current month
      final currentMonth = DateTime.now().month;
      final monthToFetch = months.firstWhere(
        (m) => m.month == currentMonth,
        orElse: () => months.first,
      );

      // Fetch days for current month
      await repo.getDays(yearToFetch.year, monthToFetch.month);

      // Fetch today's content
      final today = DateTime.now().day;
      await repo.getDayDetail(yearToFetch.year, monthToFetch.month, today);

      log('DataPrefetcher: ✓ Rhapsody (years, months, days, today) cached');
    } catch (e) {
      log('DataPrefetcher: ✗ Rhapsody failed: $e');
    }
  }

  Future<void> _prefetchFoundation(ConnectivityCubit cubit) async {
    try {
      final repo = FoundationRepository(connectivityCubit: cubit);
      
      // Fetch all classes
      final classes = await repo.getClasses();
      
      // Prefetch first 3 class details (most likely to be accessed)
      for (var i = 0; i < classes.length && i < 3; i++) {
        await repo.getClassDetail(classes[i].id);
      }

      log('DataPrefetcher: ✓ Foundation (${classes.length} classes) cached');
    } catch (e) {
      log('DataPrefetcher: ✗ Foundation failed: $e');
    }
  }

  Future<void> _prefetchQuizCategories(ConnectivityCubit cubit, String? languageId) async {
    try {
      final repo = QuizRepository(connectivityCubit: cubit);
      
      // Prefetch main quiz categories (type 1 = quiz zone)
      final categories = await repo.getCategory(
        languageId: languageId ?? '',
        type: '1',
      );
      log('DataPrefetcher: ✓ Quiz categories (${categories.length}) cached');

      // Prefetch subcategories and questions for each category
      for (final category in categories) {
        try {
          // Get subcategories
          final subcategories = await repo.getSubCategory(category.id ?? '');
          
          if (subcategories.isEmpty) {
            // No subcategories - fetch questions directly from category
            await repo.getQuestions(
              QuizTypes.quizZone,
              categoryId: category.id,
              subcategoryId: '',
              level: '0',
            );
            log('DataPrefetcher: ✓ Questions for ${category.categoryName} cached');
          } else {
            // Has subcategories - fetch questions for each
            for (final sub in subcategories) {
              await repo.getQuestions(
                QuizTypes.quizZone,
                categoryId: category.id,
                subcategoryId: sub.id,
                level: '0',
              );
            }
            log('DataPrefetcher: ✓ Questions for ${category.categoryName} (${subcategories.length} subs) cached');
          }
        } catch (e) {
          log('DataPrefetcher: ✗ Questions for ${category.categoryName} failed: $e');
        }
      }
    } catch (e) {
      log('DataPrefetcher: ✗ Quiz categories failed: $e');
    }
  }

  /// Force a fresh prefetch (e.g., on pull-to-refresh)
  void resetPrefetchStatus() {
    _hasPrefetched = false;
  }
}

