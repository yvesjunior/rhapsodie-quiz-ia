/// Topic Category Model
/// Represents a category within a topic (Year, Month, Day, Module)
class TopicCategory {
  final String id;
  final String? topicId;
  final String? parentId;
  final String name;
  final String? slug;
  final String categoryType; // 'year', 'month', 'day', 'module', 'general'
  final String ageGroup; // 'kids', 'teens', 'adults', 'all'
  final String? image;
  final int rowOrder;

  // Date fields for Rhapsody
  final int? year;
  final int? month;
  final int? day;
  final String? dailyText;

  // Content fields for Foundation School
  final String? contentText;
  final String? contentVideoUrl;
  final String? contentAudioUrl;
  final String? contentPdfUrl;

  // Metadata
  final int questionCount;
  final bool hasChildren;
  final UserProgress? userProgress;

  TopicCategory({
    required this.id,
    this.topicId,
    this.parentId,
    required this.name,
    this.slug,
    required this.categoryType,
    this.ageGroup = 'all',
    this.image,
    this.rowOrder = 0,
    this.year,
    this.month,
    this.day,
    this.dailyText,
    this.contentText,
    this.contentVideoUrl,
    this.contentAudioUrl,
    this.contentPdfUrl,
    this.questionCount = 0,
    this.hasChildren = false,
    this.userProgress,
  });

  factory TopicCategory.fromJson(Map<String, dynamic> json) {
    return TopicCategory(
      id: json['id']?.toString() ?? '',
      topicId: json['topic_id']?.toString(),
      parentId: json['parent_id']?.toString(),
      name: (json['category_name'] as String?) ?? (json['name'] as String?) ?? '',
      slug: json['slug'] as String?,
      categoryType: (json['category_type'] as String?) ?? 'general',
      ageGroup: (json['age_group'] as String?) ?? 'all',
      image: json['image'] as String?,
      rowOrder: int.tryParse(json['row_order']?.toString() ?? '0') ?? 0,
      year: int.tryParse(json['year']?.toString() ?? ''),
      month: int.tryParse(json['month']?.toString() ?? ''),
      day: int.tryParse(json['day']?.toString() ?? ''),
      dailyText: json['daily_text'] as String?,
      contentText: json['content_text'] as String?,
      contentVideoUrl: json['content_video_url'] as String?,
      contentAudioUrl: json['content_audio_url'] as String?,
      contentPdfUrl: json['content_pdf_url'] as String?,
      questionCount:
          int.tryParse(json['question_count']?.toString() ?? '0') ?? 0,
      hasChildren: json['has_children'] == '1' || json['has_children'] == true,
      userProgress: json['user_progress'] != null
          ? UserProgress.fromJson(json['user_progress'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic_id': topicId,
      'parent_id': parentId,
      'category_name': name,
      'slug': slug,
      'category_type': categoryType,
      'age_group': ageGroup,
      'image': image,
      'row_order': rowOrder.toString(),
      'year': year?.toString(),
      'month': month?.toString(),
      'day': day?.toString(),
      'daily_text': dailyText,
      'content_text': contentText,
      'content_video_url': contentVideoUrl,
      'content_audio_url': contentAudioUrl,
      'content_pdf_url': contentPdfUrl,
      'question_count': questionCount.toString(),
      'has_children': hasChildren ? '1' : '0',
    };
  }

  bool get isYear => categoryType == 'year';
  bool get isMonth => categoryType == 'month';
  bool get isDay => categoryType == 'day';
  bool get isModule => categoryType == 'module';

  bool get hasContent =>
      contentText != null ||
      contentVideoUrl != null ||
      contentAudioUrl != null ||
      contentPdfUrl != null;

  bool get hasQuiz => questionCount > 0;

  String get formattedDate {
    if (year != null && month != null && day != null) {
      return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    }
    if (year != null && month != null) {
      return '$year-${month.toString().padLeft(2, '0')}';
    }
    if (year != null) {
      return year.toString();
    }
    return '';
  }
}

/// User Progress Model
class UserProgress {
  final String status; // 'not_started', 'in_progress', 'completed'
  final double progressPercent;
  final int score;
  final String? completedAt;

  UserProgress({
    required this.status,
    this.progressPercent = 0,
    this.score = 0,
    this.completedAt,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      status: (json['status'] as String?) ?? 'not_started',
      progressPercent:
          double.tryParse(json['progress_percent']?.toString() ?? '0') ?? 0,
      score: int.tryParse(json['score']?.toString() ?? '0') ?? 0,
      completedAt: json['completed_at'] as String?,
    );
  }

  bool get isNotStarted => status == 'not_started';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
}

