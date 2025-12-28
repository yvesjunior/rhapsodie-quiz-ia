/// Foundation School data models

class FoundationClass {
  final String id;
  final String name;
  final String title;
  final String contentText;
  final int rowOrder;
  final int questionsCount;
  final FoundationProgress? userProgress;

  FoundationClass({
    required this.id,
    required this.name,
    required this.title,
    required this.contentText,
    required this.rowOrder,
    this.questionsCount = 0,
    this.userProgress,
  });

  factory FoundationClass.fromJson(Map<String, dynamic> json) {
    return FoundationClass(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      contentText: json['content_text']?.toString() ?? '',
      rowOrder: int.tryParse(json['row_order']?.toString() ?? '0') ?? 0,
      questionsCount:
          int.tryParse(json['questions_count']?.toString() ?? '0') ?? 0,
      userProgress: json['user_progress'] != null
          ? FoundationProgress.fromJson(
              json['user_progress'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Get the class number (e.g., "1" from "Class 1" or "4a" from "Class 4a")
  String get classNumber {
    final match = RegExp(r'Class\s*(\d+[ab]?)').firstMatch(name);
    return match?.group(1) ?? rowOrder.toString();
  }

  /// Check if this class has been completed
  bool get isCompleted => userProgress?.status == 'completed';

  /// Check if this class is in progress
  bool get isInProgress => userProgress?.status == 'in_progress';
}

class FoundationProgress {
  final String status;
  final double progressPercent;
  final int score;
  final String? completedAt;

  FoundationProgress({
    required this.status,
    required this.progressPercent,
    required this.score,
    this.completedAt,
  });

  factory FoundationProgress.fromJson(Map<String, dynamic> json) {
    return FoundationProgress(
      status: json['status']?.toString() ?? 'not_started',
      progressPercent:
          double.tryParse(json['progress_percent']?.toString() ?? '0') ?? 0.0,
      score: int.tryParse(json['score']?.toString() ?? '0') ?? 0,
      completedAt: json['completed_at']?.toString(),
    );
  }
}

