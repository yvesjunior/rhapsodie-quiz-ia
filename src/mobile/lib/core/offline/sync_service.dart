import 'dart:developer';

import 'package:flutterquiz/core/offline/cache_manager.dart';
import 'package:flutterquiz/core/offline/connectivity_cubit.dart';
import 'package:flutterquiz/core/offline/pending_operations.dart';

/// Callback type for syncing a pending operation
typedef SyncOperationCallback = Future<bool> Function(PendingOperation op);

/// Service to manage background syncing of cached data and pending operations
/// 
/// This service coordinates:
/// - Syncing pending operations when online
/// - Refreshing cached data in the background
/// - Handling sync conflicts and retries
class SyncService {
  SyncService({
    required this.connectivityCubit,
    required this.cacheManager,
    required this.pendingQueue,
  }) {
    _init();
  }

  final ConnectivityCubit connectivityCubit;
  final CacheManager cacheManager;
  final PendingOperationsQueue pendingQueue;

  /// Max retry attempts for a single operation
  static const int maxRetries = 3;

  /// Registered sync handlers for each operation type
  final Map<OperationType, SyncOperationCallback> _syncHandlers = {};

  /// Callbacks to refresh cached data
  final List<Future<void> Function()> _refreshCallbacks = [];

  bool _isSyncing = false;

  void _init() {
    // Register for reconnect events
    connectivityCubit.onReconnect(_onReconnect);
    log('SyncService initialized');
  }

  /// Register a handler for a specific operation type
  void registerSyncHandler(OperationType type, SyncOperationCallback handler) {
    _syncHandlers[type] = handler;
    log('Registered sync handler for ${type.name}');
  }

  /// Register a callback to refresh cached data when online
  void onRefresh(Future<void> Function() callback) {
    _refreshCallbacks.add(callback);
  }

  /// Called when connectivity is restored
  Future<void> _onReconnect() async {
    log('SyncService: Connectivity restored, starting sync...');
    await syncAll();
  }

  /// Sync all pending operations and refresh caches
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      log('Sync already in progress, skipping');
      return SyncResult(synced: 0, failed: 0, skipped: true);
    }

    if (!connectivityCubit.isOnline) {
      log('Cannot sync: offline');
      return SyncResult(synced: 0, failed: 0, skipped: true);
    }

    _isSyncing = true;
    var synced = 0;
    var failed = 0;

    try {
      // 1. Sync pending operations
      final result = await syncPendingOperations();
      synced = result.synced;
      failed = result.failed;

      // 2. Refresh cached data
      await _refreshCaches();

      log('Sync complete: $synced synced, $failed failed');
    } catch (e) {
      log('Sync error: $e');
    } finally {
      _isSyncing = false;
    }

    return SyncResult(synced: synced, failed: failed);
  }

  /// Sync all pending operations
  Future<SyncResult> syncPendingOperations() async {
    final operations = await pendingQueue.getAll();
    var synced = 0;
    var failed = 0;

    log('Syncing ${operations.length} pending operations...');

    for (final op in operations) {
      // Skip if too many retries
      if (op.retryCount >= maxRetries) {
        log('Skipping operation ${op.id}: max retries exceeded');
        failed++;
        continue;
      }

      // Get handler for this operation type
      final handler = _syncHandlers[op.type];
      if (handler == null) {
        log('No handler for operation type: ${op.type.name}');
        failed++;
        continue;
      }

      try {
        final success = await handler(op);
        if (success) {
          await pendingQueue.complete(op.id);
          synced++;
        } else {
          await pendingQueue.markFailed(op.id, 'Handler returned false');
          failed++;
        }
      } catch (e) {
        await pendingQueue.markFailed(op.id, e.toString());
        failed++;
      }
    }

    return SyncResult(synced: synced, failed: failed);
  }

  /// Refresh all registered caches
  Future<void> _refreshCaches() async {
    log('Refreshing ${_refreshCallbacks.length} caches...');
    
    for (final callback in _refreshCallbacks) {
      try {
        await callback();
      } catch (e) {
        log('Cache refresh error: $e');
      }
    }
  }

  /// Manually trigger a cache refresh for a specific feature
  Future<void> refreshFeature(String featureName, Future<void> Function() refresh) async {
    if (!connectivityCubit.isOnline) {
      log('Cannot refresh $featureName: offline');
      return;
    }

    try {
      log('Refreshing $featureName...');
      await refresh();
      log('$featureName refreshed');
    } catch (e) {
      log('Error refreshing $featureName: $e');
    }
  }

  /// Get sync status
  bool get isSyncing => _isSyncing;

  /// Get count of pending operations
  Future<int> getPendingCount() => pendingQueue.count();

  void dispose() {
    connectivityCubit.removeReconnectCallback(_onReconnect);
    _refreshCallbacks.clear();
    _syncHandlers.clear();
  }
}

/// Result of a sync operation
class SyncResult {
  const SyncResult({
    required this.synced,
    required this.failed,
    this.skipped = false,
  });

  /// Number of operations successfully synced
  final int synced;

  /// Number of operations that failed
  final int failed;

  /// Whether sync was skipped (already in progress or offline)
  final bool skipped;

  /// Total operations processed
  int get total => synced + failed;

  /// Whether all operations succeeded
  bool get isSuccess => failed == 0 && !skipped;

  @override
  String toString() => 'SyncResult(synced: $synced, failed: $failed, skipped: $skipped)';
}

