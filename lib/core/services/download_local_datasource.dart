import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musea/core/services/download_notifier.dart';

abstract class DownloadLocalDataSource {
  Future<List<DownloadTask>> loadTasks();
  Future<void> saveTasks(List<DownloadTask> tasks);
  Future<void> clearTasks();
}

class DownloadLocalDataSourceImpl implements DownloadLocalDataSource {
  static const String _boxName = 'downloads_cache';
  static const String _key = 'download_tasks';
  Box<dynamic>? _box;

  Future<Box<dynamic>?> get box async {
    if (_box != null) return _box;
    try {
      _box = await Hive.openBox(_boxName);
      return _box;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<DownloadTask>> loadTasks() async {
    final b = await box;
    if (b == null) return [];
    final raw = b.get(_key);
    if (raw == null || raw is! String) return [];

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final tasksJson = data['tasks'] as List<dynamic>;
      return tasksJson
          .map((json) => DownloadTask.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> saveTasks(List<DownloadTask> tasks) async {
    final b = await box;
    if (b == null) return;
    final jsonList = tasks.map((task) => task.toJson()).toList();
    final payload = jsonEncode({'tasks': jsonList});
    await b.put(_key, payload);
  }

  @override
  Future<void> clearTasks() async {
    final b = await box;
    if (b == null) return;
    await b.delete(_key);
  }
}
