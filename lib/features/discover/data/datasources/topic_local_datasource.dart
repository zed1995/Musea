import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musea/features/discover/data/models/topic_model.dart';

abstract class TopicLocalDataSource {
  Future<void> saveTopics(List<TopicModel> topics);
  Future<List<TopicModel>> getTopics();
  Future<DateTime?> getLastUpdatedAt();
  Future<void> clearCache();
}

class TopicLocalDataSourceImpl implements TopicLocalDataSource {
  static const String _boxName = 'topics_cache';
  static const String _dataKey = 'topic_data';
  Box<dynamic>? _box;

  Future<Box<dynamic>> get box async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  @override
  Future<void> saveTopics(List<TopicModel> topics) async {
    final topicBox = await box;
    final jsonList = topics.map((topic) {
      final json = topic.toJson();
      json.remove('cover_photo');
      return json;
    }).toList();

    final payload = {
      'topics': jsonList,
      'lastUpdatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    await topicBox.put(_dataKey, jsonEncode(payload));
  }

  @override
  Future<List<TopicModel>> getTopics() async {
    final topicBox = await box;
    final raw = topicBox.get(_dataKey);
    if (raw == null || raw is! String) return [];

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final jsonList = data['topics'] as List;
      return jsonList
          .map((json) => TopicModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<DateTime?> getLastUpdatedAt() async {
    final topicBox = await box;
    final raw = topicBox.get(_dataKey);
    if (raw == null || raw is! String) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp = data['lastUpdatedAt'] as String?;
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    final topicBox = await box;
    await topicBox.clear();
  }
}
