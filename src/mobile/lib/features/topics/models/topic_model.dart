/// Topic Model
/// Represents a topic (Rhapsody, Foundation School)
class Topic {
  final String id;
  final String slug;
  final String name;
  final String? description;
  final String? image;
  final String topicType; // 'daily' or 'training'
  final bool isActive;
  final int rowOrder;

  Topic({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.image,
    required this.topicType,
    this.isActive = true,
    this.rowOrder = 0,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id']?.toString() ?? '',
      slug: (json['slug'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      image: json['image'] as String?,
      topicType: (json['topic_type'] as String?) ?? 'daily',
      isActive: json['is_active'] == '1' || json['is_active'] == true,
      rowOrder: int.tryParse(json['row_order']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'description': description,
      'image': image,
      'topic_type': topicType,
      'is_active': isActive ? '1' : '0',
      'row_order': rowOrder.toString(),
    };
  }

  bool get isDaily => topicType == 'daily';
  bool get isTraining => topicType == 'training';
  bool get isRhapsody => slug == 'rhapsody';
  bool get isFoundationSchool => slug == 'foundation_school';
}

