import 'package:hive_flutter/hive_flutter.dart';
import 'package:musea/features/discover/data/models/topic_model.dart';

abstract class TopicLocalDataSource {
  Future<void> cacheTopics(List<TopicModel> topics);
  Future<List<TopicModel>> getCachedTopics();
  Future<void> clearCache();
}

class TopicLocalDataSourceImpl implements TopicLocalDataSource {
  static const String _boxName = 'topics_cache';
  static const String _topicsKey = 'topics_json';
  Box<dynamic>? _box;

  Future<Box<dynamic>> get box async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  @override
  Future<void> cacheTopics(List<TopicModel> topics) async {
    final topicBox = await box;
    // Cache as JSON strings instead of objects to avoid Hive serialization issues
    final jsonList = topics.map((topic) => topic.toJson()).toList();
    await topicBox.put(_topicsKey, jsonList);
  }

  @override
  Future<List<TopicModel>> getCachedTopics() async {
    final topicBox = await box;
    final jsonList = topicBox.get(_topicsKey);
    if (jsonList == null || jsonList is! List) return [];
    
    try {
      return jsonList
          .map((json) => TopicModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If deserialization fails, return empty list
      return [];
    }
  }

  @override
  Future<void> clearCache() async {
    final topicBox = await box;
    await topicBox.clear();
  }
}
