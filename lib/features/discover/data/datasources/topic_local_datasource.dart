import 'package:hive_flutter/hive_flutter.dart';
import 'package:musea/features/discover/data/models/topic_model.dart';

abstract class TopicLocalDataSource {
  Future<void> cacheTopics(List<TopicModel> topics);
  Future<List<TopicModel>> getCachedTopics();
  Future<void> clearCache();
}

class TopicLocalDataSourceImpl implements TopicLocalDataSource {
  static const String _boxName = 'topics_cache';
  static const String _topicsKey = 'topics';
  Box<dynamic>? _box;

  Future<Box<dynamic>> get box async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  @override
  Future<void> cacheTopics(List<TopicModel> topics) async {
    final topicBox = await box;
    final jsonList = topics.map((topic) => topic.toJson()).toList();
    await topicBox.put(_topicsKey, jsonList);
  }

  @override
  Future<List<TopicModel>> getCachedTopics() async {
    final topicBox = await box;
    final jsonList = topicBox.get(_topicsKey);
    if (jsonList == null || jsonList is! List) return [];
    
    return jsonList
        .map((json) => TopicModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> clearCache() async {
    final topicBox = await box;
    await topicBox.clear();
  }
}
