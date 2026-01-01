import 'dart:convert';
import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';

/// Hive box name for pending operations
const String _pendingOpsBoxName = 'pending_operations';

/// Types of operations that can be queued
enum OperationType {
  /// Submit daily contest results
  submitDailyContest,
  
  /// Update user profile
  updateProfile,
  
  /// Update user score/coins
  updateScoreCoins,
  
  /// Submit quiz results
  submitQuiz,
  
  /// Update bookmark
  updateBookmark,
  
  /// Report question
  reportQuestion,
}

/// Represents a pending operation to be synced when online
class PendingOperation {
  PendingOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  /// Unique identifier for this operation
  final String id;

  /// Type of operation
  final OperationType type;

  /// Operation data (JSON serializable)
  final Map<String, dynamic> data;

  /// When the operation was created
  final DateTime createdAt;

  /// Number of sync retry attempts
  int retryCount;

  /// Last error message if sync failed
  String? lastError;

  /// Create from JSON
  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'] as String,
      type: OperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OperationType.submitQuiz,
      ),
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      lastError: json['lastError'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'lastError': lastError,
      };
}

/// Manages a queue of operations to be synced when online
/// 
/// Operations are persisted to Hive and survive app restarts
class PendingOperationsQueue {
  static PendingOperationsQueue? _instance;
  Box<String>? _box;

  PendingOperationsQueue._();

  /// Singleton instance
  static PendingOperationsQueue get instance {
    _instance ??= PendingOperationsQueue._();
    return _instance!;
  }

  /// Initialize the pending operations box
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<String>(_pendingOpsBoxName);
    log('PendingOperationsQueue initialized with ${_box!.length} pending ops');
  }

  /// Get the box, initializing if needed
  Future<Box<String>> get _getBox async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
    return _box!;
  }

  /// Generate a unique ID for an operation
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Queue an operation for later sync
  Future<String> queue(OperationType type, Map<String, dynamic> data) async {
    final box = await _getBox;
    final id = _generateId();
    
    final op = PendingOperation(
      id: id,
      type: type,
      data: data,
      createdAt: DateTime.now(),
    );
    
    await box.put(id, jsonEncode(op.toJson()));
    log('Queued operation: ${type.name} (id: $id)');
    
    return id;
  }

  /// Get all pending operations
  Future<List<PendingOperation>> getAll() async {
    final box = await _getBox;
    final ops = <PendingOperation>[];
    
    for (final key in box.keys) {
      final jsonString = box.get(key);
      if (jsonString != null) {
        try {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          ops.add(PendingOperation.fromJson(json));
        } catch (e) {
          log('Error parsing pending op $key: $e');
        }
      }
    }
    
    // Sort by creation time (oldest first)
    ops.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    return ops;
  }

  /// Get pending operations by type
  Future<List<PendingOperation>> getByType(OperationType type) async {
    final all = await getAll();
    return all.where((op) => op.type == type).toList();
  }

  /// Get count of pending operations
  Future<int> count() async {
    final box = await _getBox;
    return box.length;
  }

  /// Mark an operation as complete (remove from queue)
  Future<void> complete(String id) async {
    final box = await _getBox;
    await box.delete(id);
    log('Completed operation: $id');
  }

  /// Update an operation (e.g., increment retry count)
  Future<void> update(PendingOperation op) async {
    final box = await _getBox;
    await box.put(op.id, jsonEncode(op.toJson()));
  }

  /// Mark an operation as failed
  Future<void> markFailed(String id, String error) async {
    final box = await _getBox;
    final jsonString = box.get(id);
    
    if (jsonString != null) {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final op = PendingOperation.fromJson(json);
      op.retryCount++;
      op.lastError = error;
      await box.put(id, jsonEncode(op.toJson()));
      log('Marked operation $id as failed: $error (retry: ${op.retryCount})');
    }
  }

  /// Clear all pending operations
  Future<void> clearAll() async {
    final box = await _getBox;
    await box.clear();
    log('Cleared all pending operations');
  }

  /// Clear operations older than [duration]
  Future<int> clearOlderThan(Duration duration) async {
    final all = await getAll();
    final cutoff = DateTime.now().subtract(duration);
    var cleared = 0;
    
    for (final op in all) {
      if (op.createdAt.isBefore(cutoff)) {
        await complete(op.id);
        cleared++;
      }
    }
    
    log('Cleared $cleared operations older than ${duration.inDays} days');
    return cleared;
  }
}

