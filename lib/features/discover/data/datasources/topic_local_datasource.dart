import 'dart:convert';
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
    // Convert to JSON and remove cover_photo to avoid Hive serialization issues
    final jsonList = topics.map((topic) {
      final json = topic.toJson();
      // Remove cover_photo as it contains PhotoModel which can't be serialized by Hive
      json.remove('cover_photo');
      return json;
    }).toList();
    
    // Convert to JSON string to ensure Hive can store it
    final jsonString = jsonEncode(jsonList);
    await topicBox.put(_topicsKey, jsonString);
  }

  @override
  Future<List<TopicModel>> getCachedTopics() async {
    final topicBox = await box;
    final jsonString = topicBox.get(_topicsKey);
    if (jsonString == null || jsonString is! String) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List;
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
