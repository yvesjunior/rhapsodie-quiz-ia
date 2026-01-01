import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/core/constants/error_message_keys.dart';
import 'package:flutterquiz/features/foundation/foundation_repository.dart';
import 'package:flutterquiz/features/foundation/models/foundation_models.dart';
import 'package:flutterquiz/core/constants/api_exception.dart';

/// States for Foundation Cubit
abstract class FoundationState {}

class FoundationInitial extends FoundationState {}

class FoundationLoading extends FoundationState {}

class FoundationClassesLoaded extends FoundationState {
  final List<FoundationClass> classes;
  final bool isOffline;

  FoundationClassesLoaded(this.classes, {this.isOffline = false});
}

class FoundationClassDetailLoaded extends FoundationState {
  final FoundationClass classDetail;
  final bool isOffline;

  FoundationClassDetailLoaded(this.classDetail, {this.isOffline = false});
}

class FoundationError extends FoundationState {
  final String message;
  final bool isOffline;

  FoundationError(this.message, {this.isOffline = false});
}

/// Cubit for managing Foundation School state (uses repository with offline support)
class FoundationCubit extends Cubit<FoundationState> {
  final FoundationRepository _repository;

  FoundationCubit(this._repository) : super(FoundationInitial());

  List<FoundationClass>? _cachedClasses;

  /// Load all Foundation School classes (offline-first via repository)
  Future<void> loadClasses({bool forceRefresh = false}) async {
    if (_cachedClasses != null && !forceRefresh) {
      emit(FoundationClassesLoaded(_cachedClasses!));
      return;
    }

    emit(FoundationLoading());
    try {
      final classes = await _repository.getClasses(forceRefresh: forceRefresh);
      _cachedClasses = classes;
      emit(FoundationClassesLoaded(classes));
    } on ApiException catch (e) {
      emit(FoundationError(e.error, isOffline: e.error == errorCodeNoInternet));
    } catch (e) {
      emit(FoundationError(noInternetKey, isOffline: true));
    }
  }

  /// Load a specific class detail (offline-first via repository)
  Future<void> loadClassDetail(String classId, {bool forceRefresh = false}) async {
    emit(FoundationLoading());
    try {
      final classDetail = await _repository.getClassDetail(
        classId,
        forceRefresh: forceRefresh,
      );
      emit(FoundationClassDetailLoaded(classDetail));
    } on ApiException catch (e) {
      emit(FoundationError(e.error, isOffline: e.error == errorCodeNoInternet));
    } catch (e) {
      emit(FoundationError(noInternetKey, isOffline: true));
    }
  }

  /// Get cached classes (if available)
  List<FoundationClass>? get cachedClasses => _cachedClasses;
}

