import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// Connectivity state
enum ConnectivityStatus {
  /// Device is connected to the internet
  online,
  
  /// Device is offline
  offline,
  
  /// Connectivity status is being checked
  checking,
}

/// Cubit to manage and monitor network connectivity
/// 
/// Emits [ConnectivityStatus] changes and provides utility methods
/// to check current connectivity state.
class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  ConnectivityCubit() : super(ConnectivityStatus.checking) {
    _init();
  }

  StreamSubscription<InternetConnectionStatus>? _subscription;
  final InternetConnectionChecker _checker = InternetConnectionChecker.instance;

  /// Callbacks to execute when connectivity is restored
  final List<Future<void> Function()> _onReconnectCallbacks = [];

  Future<void> _init() async {
    // Check initial status
    final hasConnection = await _checker.hasConnection;
    emit(hasConnection ? ConnectivityStatus.online : ConnectivityStatus.offline);
    log('Initial connectivity: ${state.name}');

    // Listen to changes
    _subscription = _checker.onStatusChange.listen((status) {
      final newState = status == InternetConnectionStatus.connected
          ? ConnectivityStatus.online
          : ConnectivityStatus.offline;

      if (state != newState) {
        log('Connectivity changed: ${newState.name}');
        emit(newState);

        // Execute reconnect callbacks when coming back online
        if (newState == ConnectivityStatus.online) {
          _executeReconnectCallbacks();
        }
      }
    });
  }

  /// Check if currently online
  bool get isOnline => state == ConnectivityStatus.online;

  /// Check if currently offline
  bool get isOffline => state == ConnectivityStatus.offline;

  /// Force a connectivity check
  Future<bool> checkConnectivity() async {
    emit(ConnectivityStatus.checking);
    final hasConnection = await _checker.hasConnection;
    emit(hasConnection ? ConnectivityStatus.online : ConnectivityStatus.offline);
    return hasConnection;
  }

  /// Register a callback to execute when connectivity is restored
  /// 
  /// Useful for triggering sync operations when coming back online
  void onReconnect(Future<void> Function() callback) {
    _onReconnectCallbacks.add(callback);
  }

  /// Remove a reconnect callback
  void removeReconnectCallback(Future<void> Function() callback) {
    _onReconnectCallbacks.remove(callback);
  }

  Future<void> _executeReconnectCallbacks() async {
    log('Executing ${_onReconnectCallbacks.length} reconnect callbacks');
    for (final callback in _onReconnectCallbacks) {
      try {
        await callback();
      } catch (e) {
        log('Reconnect callback error: $e');
      }
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _onReconnectCallbacks.clear();
    return super.close();
  }
}

