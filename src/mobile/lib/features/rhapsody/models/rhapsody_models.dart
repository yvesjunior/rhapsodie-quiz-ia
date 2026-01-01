/// Rhapsody Year Model
class RhapsodyYear {
  final String id;
  final String name;
  final int year;

  const RhapsodyYear({
    required this.id,
    required this.name,
    required this.year,
  });

  factory RhapsodyYear.fromJson(Map<String, dynamic> json) {
    return RhapsodyYear(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String?) ?? '',
      year: int.tryParse(json['year']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Rhapsody Month Model
class RhapsodyMonth {
  final String id;
  final String name;
  final int month;
  final int year;
  final String? image;
  final int daysCount;
  final int questionsCount;

  const RhapsodyMonth({
    required this.id,
    required this.name,
    required this.month,
    required this.year,
    this.image,
    this.daysCount = 0,
    this.questionsCount = 0,
  });

  factory RhapsodyMonth.fromJson(Map<String, dynamic> json) {
    return RhapsodyMonth(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String?) ?? '',
      month: int.tryParse(json['month']?.toString() ?? '0') ?? 0,
      year: int.tryParse(json['year']?.toString() ?? '0') ?? 0,
      image: json['image'] as String?,
      daysCount: int.tryParse(json['days_count']?.toString() ?? '0') ?? 0,
      questionsCount: int.tryParse(json['questions_count']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Rhapsody Day Model (for list view)
class RhapsodyDay {
  final String id;
  final String name;
  final String title;
  final int day;
  final int month;
  final int year;
  final int questionsCount;

  const RhapsodyDay({
    required this.id,
    required this.name,
    required this.title,
    required this.day,
    required this.month,
    required this.year,
    this.questionsCount = 0,
  });

  factory RhapsodyDay.fromJson(Map<String, dynamic> json) {
    return RhapsodyDay(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      day: int.tryParse(json['day']?.toString() ?? '0') ?? 0,
      month: int.tryParse(json['month']?.toString() ?? '0') ?? 0,
      year: int.tryParse(json['year']?.toString() ?? '0') ?? 0,
      questionsCount: int.tryParse(json['questions_count']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Rhapsody Day Detail Model (full content)
class RhapsodyDayDetail {
  final String id;
  final String name;
  final String title;
  final String dailyText;
  final String scriptureRef;
  final String contentText;
  final String prayerText;
  final String furtherStudy;
  final int day;
  final int month;
  final int year;
  final int questionsCount;

  const RhapsodyDayDetail({
    required this.id,
    required this.name,
    required this.title,
    required this.dailyText,
    required this.scriptureRef,
    required this.contentText,
    required this.prayerText,
    required this.furtherStudy,
    required this.day,
    required this.month,
    required this.year,
    this.questionsCount = 0,
  });

  factory RhapsodyDayDetail.fromJson(Map<String, dynamic> json) {
    return RhapsodyDayDetail(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      dailyText: (json['daily_text'] as String?) ?? '',
      scriptureRef: (json['scripture_ref'] as String?) ?? '',
      contentText: (json['content_text'] as String?) ?? '',
      prayerText: (json['prayer_text'] as String?) ?? '',
      furtherStudy: (json['further_study'] as String?) ?? '',
      day: int.tryParse(json['day']?.toString() ?? '0') ?? 0,
      month: int.tryParse(json['month']?.toString() ?? '0') ?? 0,
      year: int.tryParse(json['year']?.toString() ?? '0') ?? 0,
      questionsCount: int.tryParse(json['questions_count']?.toString() ?? '0') ?? 0,
    );
  }
}

