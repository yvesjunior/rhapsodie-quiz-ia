import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/core/constants/error_message_keys.dart';
import 'package:flutterquiz/features/rhapsody/models/rhapsody_models.dart';
import 'package:flutterquiz/features/rhapsody/rhapsody_repository.dart';
import 'package:flutterquiz/core/constants/api_exception.dart';

// States
abstract class RhapsodyState {}

class RhapsodyInitial extends RhapsodyState {}

class RhapsodyLoading extends RhapsodyState {}

class RhapsodyYearsLoaded extends RhapsodyState {
  final List<RhapsodyYear> years;
  final List<RhapsodyMonth>? months;
  final int? selectedYear;
  final bool isOffline;

  RhapsodyYearsLoaded({
    required this.years,
    this.months,
    this.selectedYear,
    this.isOffline = false,
  });
}

class RhapsodyDaysLoaded extends RhapsodyState {
  final int year;
  final int month;
  final String monthName;
  final List<RhapsodyDay> days;
  final bool isOffline;

  RhapsodyDaysLoaded({
    required this.year,
    required this.month,
    required this.monthName,
    required this.days,
    this.isOffline = false,
  });
}

class RhapsodyDayDetailLoaded extends RhapsodyState {
  final RhapsodyDayDetail detail;
  final bool isOffline;

  RhapsodyDayDetailLoaded(this.detail, {this.isOffline = false});
}

class RhapsodyError extends RhapsodyState {
  final String message;
  final bool isOffline;
  
  RhapsodyError(this.message, {this.isOffline = false});
}

// Cubit
class RhapsodyCubit extends Cubit<RhapsodyState> {
  final RhapsodyRepository _repository;
  
  // In-memory cache for quick access
  List<RhapsodyYear>? _cachedYears;
  Map<int, List<RhapsodyMonth>> _cachedMonths = {};

  RhapsodyCubit(this._repository) : super(RhapsodyInitial());

  /// Load all years and optionally months for a year
  Future<void> loadYearsAndMonths({int? year, bool forceRefresh = false}) async {
    emit(RhapsodyLoading());
    try {
      // Load years (repository handles offline-first logic)
      if (_cachedYears == null || forceRefresh) {
        _cachedYears = await _repository.getYears(forceRefresh: forceRefresh);
      }

      List<RhapsodyMonth>? months;
      int? selectedYear = year;

      // If no year specified, use the first/latest year
      if (selectedYear == null && _cachedYears!.isNotEmpty) {
        selectedYear = _cachedYears!.first.year;
      }

      // Load months for the selected year
      if (selectedYear != null) {
        if (!_cachedMonths.containsKey(selectedYear) || forceRefresh) {
          _cachedMonths[selectedYear] = await _repository.getMonths(
            selectedYear, 
            forceRefresh: forceRefresh,
          );
        }
        months = _cachedMonths[selectedYear];
      }

      emit(RhapsodyYearsLoaded(
        years: _cachedYears!,
        months: months,
        selectedYear: selectedYear,
      ));
    } on ApiException catch (e) {
      emit(RhapsodyError(e.error, isOffline: e.error == errorCodeNoInternet));
    } catch (e) {
      emit(RhapsodyError(noInternetKey, isOffline: true));
    }
  }

  /// Load months for a specific year
  Future<void> loadMonths(int year, {bool forceRefresh = false}) async {
    if (state is RhapsodyYearsLoaded) {
      final currentState = state as RhapsodyYearsLoaded;
      
      // Check cache first (repository handles offline-first)
      if (!_cachedMonths.containsKey(year) || forceRefresh) {
        _cachedMonths[year] = await _repository.getMonths(
          year, 
          forceRefresh: forceRefresh,
        );
      }

      emit(RhapsodyYearsLoaded(
        years: currentState.years,
        months: _cachedMonths[year],
        selectedYear: year,
      ));
    } else {
      await loadYearsAndMonths(year: year, forceRefresh: forceRefresh);
    }
  }

  /// Load days for a specific month
  Future<void> loadDays(
    int year, 
    int month, 
    String monthName, 
    {bool forceRefresh = false}
  ) async {
    emit(RhapsodyLoading());
    try {
      final days = await _repository.getDays(
        year, 
        month, 
        forceRefresh: forceRefresh,
      );
      emit(RhapsodyDaysLoaded(
        year: year,
        month: month,
        monthName: monthName,
        days: days,
      ));
    } on ApiException catch (e) {
      emit(RhapsodyError(e.error, isOffline: e.error == errorCodeNoInternet));
    } catch (e) {
      emit(RhapsodyError(noInternetKey, isOffline: true));
    }
  }

  /// Load full detail for a day
  Future<void> loadDayDetail(
    int year, 
    int month, 
    int day, 
    {bool forceRefresh = false}
  ) async {
    emit(RhapsodyLoading());
    try {
      final detail = await _repository.getDayDetail(
        year, 
        month, 
        day, 
        forceRefresh: forceRefresh,
      );
      if (detail != null) {
        emit(RhapsodyDayDetailLoaded(detail));
      } else {
        emit(RhapsodyError(dataNotFoundKey));
      }
    } on ApiException catch (e) {
      emit(RhapsodyError(e.error, isOffline: e.error == errorCodeNoInternet));
    } catch (e) {
      emit(RhapsodyError(noInternetKey, isOffline: true));
    }
  }

  /// Prefetch content for offline use
  Future<void> prefetchForOffline() async {
    await _repository.prefetchForOffline();
  }

  /// Check if specific content is available offline
  Future<bool> isAvailableOffline(int year, int month, int day) {
    return _repository.isAvailableOffline(year, month, day);
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() {
    return _repository.getCacheStats();
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    _cachedYears = null;
    _cachedMonths.clear();
    await _repository.clearCache();
  }
}
