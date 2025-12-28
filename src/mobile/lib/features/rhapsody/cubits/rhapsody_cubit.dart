import 'package:flutter_bloc/flutter_bloc.dart';
import '../rhapsody_remote_data_source.dart';
import '../models/rhapsody_models.dart';

// States
abstract class RhapsodyState {}

class RhapsodyInitial extends RhapsodyState {}

class RhapsodyLoading extends RhapsodyState {}

class RhapsodyYearsLoaded extends RhapsodyState {
  final List<RhapsodyYear> years;
  final List<RhapsodyMonth>? months;
  final int? selectedYear;

  RhapsodyYearsLoaded({
    required this.years,
    this.months,
    this.selectedYear,
  });
}

class RhapsodyDaysLoaded extends RhapsodyState {
  final int year;
  final int month;
  final String monthName;
  final List<RhapsodyDay> days;

  RhapsodyDaysLoaded({
    required this.year,
    required this.month,
    required this.monthName,
    required this.days,
  });
}

class RhapsodyDayDetailLoaded extends RhapsodyState {
  final RhapsodyDayDetail detail;

  RhapsodyDayDetailLoaded(this.detail);
}

class RhapsodyError extends RhapsodyState {
  final String message;
  RhapsodyError(this.message);
}

// Cubit
class RhapsodyCubit extends Cubit<RhapsodyState> {
  final RhapsodyRemoteDataSource _dataSource;
  
  List<RhapsodyYear>? _cachedYears;
  Map<int, List<RhapsodyMonth>> _cachedMonths = {};

  RhapsodyCubit(this._dataSource) : super(RhapsodyInitial());

  /// Load all years and optionally months for a year
  Future<void> loadYearsAndMonths({int? year}) async {
    emit(RhapsodyLoading());
    try {
      // Load years if not cached
      if (_cachedYears == null) {
        _cachedYears = await _dataSource.getRhapsodyYears();
      }

      List<RhapsodyMonth>? months;
      int? selectedYear = year;

      // If no year specified, use the first/latest year
      if (selectedYear == null && _cachedYears!.isNotEmpty) {
        selectedYear = _cachedYears!.first.year;
      }

      // Load months for the selected year
      if (selectedYear != null) {
        if (!_cachedMonths.containsKey(selectedYear)) {
          _cachedMonths[selectedYear] = await _dataSource.getRhapsodyMonths(selectedYear);
        }
        months = _cachedMonths[selectedYear];
      }

      emit(RhapsodyYearsLoaded(
        years: _cachedYears!,
        months: months,
        selectedYear: selectedYear,
      ));
    } catch (e) {
      emit(RhapsodyError(e.toString()));
    }
  }

  /// Load months for a specific year
  Future<void> loadMonths(int year) async {
    if (state is RhapsodyYearsLoaded) {
      final currentState = state as RhapsodyYearsLoaded;
      
      // Check cache first
      if (!_cachedMonths.containsKey(year)) {
        _cachedMonths[year] = await _dataSource.getRhapsodyMonths(year);
      }

      emit(RhapsodyYearsLoaded(
        years: currentState.years,
        months: _cachedMonths[year],
        selectedYear: year,
      ));
    } else {
      await loadYearsAndMonths(year: year);
    }
  }

  /// Load days for a specific month
  Future<void> loadDays(int year, int month, String monthName) async {
    emit(RhapsodyLoading());
    try {
      final days = await _dataSource.getRhapsodyDays(year, month);
      emit(RhapsodyDaysLoaded(
        year: year,
        month: month,
        monthName: monthName,
        days: days,
      ));
    } catch (e) {
      emit(RhapsodyError(e.toString()));
    }
  }

  /// Load full detail for a day
  Future<void> loadDayDetail(int year, int month, int day) async {
    emit(RhapsodyLoading());
    try {
      final detail = await _dataSource.getRhapsodyDayDetail(year, month, day);
      if (detail != null) {
        emit(RhapsodyDayDetailLoaded(detail));
      } else {
        emit(RhapsodyError('Content not found'));
      }
    } catch (e) {
      emit(RhapsodyError(e.toString()));
    }
  }
}

