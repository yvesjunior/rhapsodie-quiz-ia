import 'package:flutter_bloc/flutter_bloc.dart';
import '../groups_remote_data_source.dart';
import '../models/group_model.dart';

/// Groups State
abstract class GroupsState {}

class GroupsInitial extends GroupsState {}

class GroupsLoading extends GroupsState {}

class GroupsLoaded extends GroupsState {
  final List<Group> groups;
  GroupsLoaded(this.groups);
}

class GroupsError extends GroupsState {
  final String message;
  GroupsError(this.message);
}

/// Groups Cubit
class GroupsCubit extends Cubit<GroupsState> {
  final GroupsRemoteDataSource _dataSource;
  List<Group>? _cachedGroups;

  GroupsCubit(this._dataSource) : super(GroupsInitial());

  /// Load user's groups
  Future<void> loadMyGroups({bool forceRefresh = false}) async {
    if (_cachedGroups != null && !forceRefresh) {
      emit(GroupsLoaded(_cachedGroups!));
      return;
    }

    emit(GroupsLoading());
    try {
      final groups = await _dataSource.getMyGroups();
      _cachedGroups = groups;
      emit(GroupsLoaded(groups));
    } catch (e) {
      emit(GroupsError(e.toString()));
    }
  }

  /// Create a new group
  Future<Group?> createGroup({
    required String name,
    String? description,
    bool isPublic = false,
    int maxMembers = 50,
  }) async {
    try {
      final group = await _dataSource.createGroup(
        name: name,
        description: description,
        isPublic: isPublic,
        maxMembers: maxMembers,
      );
      // Refresh groups list
      await loadMyGroups(forceRefresh: true);
      return group;
    } catch (e) {
      emit(GroupsError(e.toString()));
      return null;
    }
  }

  /// Join a group
  Future<Group?> joinGroup(String inviteCode) async {
    try {
      final group = await _dataSource.joinGroup(inviteCode);
      // Refresh groups list
      await loadMyGroups(forceRefresh: true);
      return group;
    } catch (e) {
      emit(GroupsError(e.toString()));
      return null;
    }
  }

  /// Leave a group
  Future<bool> leaveGroup(String groupId) async {
    try {
      final success = await _dataSource.leaveGroup(groupId);
      if (success) {
        await loadMyGroups(forceRefresh: true);
      }
      return success;
    } catch (e) {
      emit(GroupsError(e.toString()));
      return false;
    }
  }

  /// Delete a group (owner only)
  Future<bool> deleteGroup(String groupId) async {
    try {
      final success = await _dataSource.deleteGroup(groupId);
      if (success) {
        await loadMyGroups(forceRefresh: true);
      }
      return success;
    } catch (e) {
      emit(GroupsError(e.toString()));
      return false;
    }
  }

  /// Search groups
  Future<List<Group>> searchGroups(String query) async {
    try {
      return await _dataSource.searchGroups(query);
    } catch (e) {
      return [];
    }
  }

  /// Get public groups for discovery
  Future<List<Group>> getPublicGroups({int limit = 50, int offset = 0}) async {
    try {
      return await _dataSource.getPublicGroups(limit: limit, offset: offset);
    } catch (e) {
      return [];
    }
  }

  /// Join a public group directly
  Future<Group?> joinPublicGroup(String groupId) async {
    try {
      final group = await _dataSource.joinPublicGroup(groupId);
      // Refresh groups list
      await loadMyGroups(forceRefresh: true);
      return group;
    } catch (e) {
      emit(GroupsError(e.toString()));
      return null;
    }
  }

  /// Get cached groups
  List<Group> get groups => _cachedGroups ?? [];
}

/// Group Detail State
abstract class GroupDetailState {}

class GroupDetailInitial extends GroupDetailState {}

class GroupDetailLoading extends GroupDetailState {}

class GroupDetailLoaded extends GroupDetailState {
  final Group group;
  GroupDetailLoaded(this.group);
}

class GroupDetailError extends GroupDetailState {
  final String message;
  GroupDetailError(this.message);
}

/// Group Detail Cubit
class GroupDetailCubit extends Cubit<GroupDetailState> {
  final GroupsRemoteDataSource _dataSource;

  GroupDetailCubit(this._dataSource) : super(GroupDetailInitial());

  /// Load group details
  Future<void> loadGroup(String groupId) async {
    emit(GroupDetailLoading());
    try {
      final group = await _dataSource.getGroup(groupId: groupId);
      emit(GroupDetailLoaded(group));
    } catch (e) {
      emit(GroupDetailError(e.toString()));
    }
  }

  /// Load group by invite code
  Future<void> loadGroupByCode(String inviteCode) async {
    emit(GroupDetailLoading());
    try {
      final group = await _dataSource.getGroup(inviteCode: inviteCode);
      emit(GroupDetailLoaded(group));
    } catch (e) {
      emit(GroupDetailError(e.toString()));
    }
  }
}

