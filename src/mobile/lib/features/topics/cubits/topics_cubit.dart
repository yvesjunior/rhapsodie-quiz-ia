import 'package:flutter_bloc/flutter_bloc.dart';
import '../topics_remote_data_source.dart';
import '../models/topic_model.dart';
import '../models/topic_category_model.dart';

/// Topics State
abstract class TopicsState {}

class TopicsInitial extends TopicsState {}

class TopicsLoading extends TopicsState {}

class TopicsLoaded extends TopicsState {
  final List<Topic> topics;
  final List<TopicCategory>? categories;
  final String? selectedTopicId;
  
  TopicsLoaded(this.topics, {this.categories, this.selectedTopicId});
}

class TopicsError extends TopicsState {
  final String message;
  TopicsError(this.message);
}

/// Topics Cubit
class TopicsCubit extends Cubit<TopicsState> {
  final TopicsRemoteDataSource _dataSource;
  List<Topic>? _cachedTopics;
  List<TopicCategory>? _cachedCategories;
  String? _selectedTopicId;

  TopicsCubit(this._dataSource) : super(TopicsInitial());

  /// Load all topics
  Future<void> loadTopics({bool forceRefresh = false}) async {
    if (_cachedTopics != null && !forceRefresh) {
      emit(TopicsLoaded(_cachedTopics!, categories: _cachedCategories, selectedTopicId: _selectedTopicId));
      return;
    }

    emit(TopicsLoading());
    try {
      final topics = await _dataSource.getTopics();
      _cachedTopics = topics;
      emit(TopicsLoaded(topics));
    } catch (e) {
      emit(TopicsError(e.toString()));
    }
  }

  /// Load categories for a topic
  Future<void> loadCategories(String topicId, {String? parentId, String ageGroup = 'all'}) async {
    _selectedTopicId = topicId;
    
    // Keep showing topics while loading categories
    if (_cachedTopics != null) {
      emit(TopicsLoaded(_cachedTopics!, selectedTopicId: topicId));
    }
    
    try {
      final categories = await _dataSource.getTopicCategories(
        topicId: topicId,
        parentId: parentId,
        ageGroup: ageGroup,
      );
      _cachedCategories = categories;
      emit(TopicsLoaded(_cachedTopics ?? [], categories: categories, selectedTopicId: topicId));
    } catch (e) {
      emit(TopicsError(e.toString()));
    }
  }

  /// Get cached topics
  List<Topic> get topics => _cachedTopics ?? [];

  /// Get cached categories
  List<TopicCategory>? get categories => _cachedCategories;

  /// Get topic by slug
  Topic? getTopicBySlug(String slug) {
    return _cachedTopics?.firstWhere(
      (t) => t.slug == slug,
      orElse: () => Topic(id: '', slug: '', name: '', topicType: 'daily'),
    );
  }
}

/// Topic Categories State
abstract class TopicCategoriesState {}

class TopicCategoriesInitial extends TopicCategoriesState {}

class TopicCategoriesLoading extends TopicCategoriesState {}

class TopicCategoriesLoaded extends TopicCategoriesState {
  final List<TopicCategory> categories;
  final String? parentId;
  final String topicSlug;

  TopicCategoriesLoaded({
    required this.categories,
    this.parentId,
    required this.topicSlug,
  });
}

class TopicCategoriesError extends TopicCategoriesState {
  final String message;
  TopicCategoriesError(this.message);
}

/// Topic Categories Cubit
class TopicCategoriesCubit extends Cubit<TopicCategoriesState> {
  final TopicsRemoteDataSource _dataSource;
  final Map<String, List<TopicCategory>> _cache = {};

  TopicCategoriesCubit(this._dataSource) : super(TopicCategoriesInitial());

  /// Load categories for a topic
  Future<void> loadCategories({
    String? topicId,
    String? topicSlug,
    String? parentId,
    String ageGroup = 'all',
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${topicSlug ?? topicId}_${parentId ?? 'root'}_$ageGroup';

    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      emit(TopicCategoriesLoaded(
        categories: _cache[cacheKey]!,
        parentId: parentId,
        topicSlug: topicSlug ?? '',
      ));
      return;
    }

    emit(TopicCategoriesLoading());
    try {
      final categories = await _dataSource.getTopicCategories(
        topicId: topicId,
        topicSlug: topicSlug,
        parentId: parentId,
        ageGroup: ageGroup,
      );
      _cache[cacheKey] = categories;
      emit(TopicCategoriesLoaded(
        categories: categories,
        parentId: parentId,
        topicSlug: topicSlug ?? '',
      ));
    } catch (e) {
      emit(TopicCategoriesError(e.toString()));
    }
  }

  /// Load Rhapsody daily content
  Future<void> loadRhapsodyDaily({
    required int year,
    int? month,
    int? day,
    String ageGroup = 'all',
  }) async {
    emit(TopicCategoriesLoading());
    try {
      final categories = await _dataSource.getRhapsodyDaily(
        year: year,
        month: month,
        day: day,
        ageGroup: ageGroup,
      );
      emit(TopicCategoriesLoaded(
        categories: categories,
        topicSlug: 'rhapsody',
      ));
    } catch (e) {
      emit(TopicCategoriesError(e.toString()));
    }
  }

  /// Load Foundation School modules
  Future<void> loadFoundationSchoolModules() async {
    emit(TopicCategoriesLoading());
    try {
      final modules = await _dataSource.getFoundationSchoolModules();
      emit(TopicCategoriesLoaded(
        categories: modules,
        topicSlug: 'foundation_school',
      ));
    } catch (e) {
      emit(TopicCategoriesError(e.toString()));
    }
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }
}

