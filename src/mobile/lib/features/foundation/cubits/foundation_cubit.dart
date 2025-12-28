import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/foundation/foundation_remote_data_source.dart';
import 'package:flutterquiz/features/foundation/models/foundation_models.dart';

/// States for Foundation Cubit
abstract class FoundationState {}

class FoundationInitial extends FoundationState {}

class FoundationLoading extends FoundationState {}

class FoundationClassesLoaded extends FoundationState {
  final List<FoundationClass> classes;

  FoundationClassesLoaded(this.classes);
}

class FoundationClassDetailLoaded extends FoundationState {
  final FoundationClass classDetail;

  FoundationClassDetailLoaded(this.classDetail);
}

class FoundationError extends FoundationState {
  final String message;

  FoundationError(this.message);
}

/// Cubit for managing Foundation School state
class FoundationCubit extends Cubit<FoundationState> {
  final FoundationRemoteDataSource _dataSource;

  FoundationCubit(this._dataSource) : super(FoundationInitial());

  List<FoundationClass>? _cachedClasses;

  /// Load all Foundation School classes
  Future<void> loadClasses({bool forceRefresh = false}) async {
    if (_cachedClasses != null && !forceRefresh) {
      emit(FoundationClassesLoaded(_cachedClasses!));
      return;
    }

    emit(FoundationLoading());
    try {
      final classes = await _dataSource.getFoundationClasses();
      _cachedClasses = classes;
      emit(FoundationClassesLoaded(classes));
    } catch (e) {
      emit(FoundationError(e.toString()));
    }
  }

  /// Load a specific class detail
  Future<void> loadClassDetail(String classId) async {
    emit(FoundationLoading());
    try {
      final classDetail = await _dataSource.getFoundationClassDetail(classId);
      emit(FoundationClassDetailLoaded(classDetail));
    } catch (e) {
      emit(FoundationError(e.toString()));
    }
  }

  /// Get cached classes (if available)
  List<FoundationClass>? get cachedClasses => _cachedClasses;
}

