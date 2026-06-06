import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class CacheSummaryService {
  const CacheSummaryService();

  static const List<String> hiveBoxes = <String>[
    'photos_cache',
    'topics_cache',
  ];

  Future<int> getTotalCacheBytes() async {
    var total = 0;

    for (final boxName in hiveBoxes) {
      final box = await Hive.openBox(boxName);
      final path = box.path;
      if (path == null) continue;

      final file = File(path);
      if (await file.exists()) {
        total += await file.length();
      }
    }

    final tempDirectory = await getTemporaryDirectory();
    final imageCacheDirectory = Directory(
      '${tempDirectory.path}/${DefaultCacheManager.key}',
    );
    if (await imageCacheDirectory.exists()) {
      total += await directorySize(imageCacheDirectory);
    }

    return total;
  }

  Future<void> clearAll() async {
    for (final boxName in hiveBoxes) {
      final box = await Hive.openBox(boxName);
      await box.clear();
    }

    await DefaultCacheManager().emptyCache();
  }

  static Future<int> directorySize(Directory directory) async {
    var total = 0;

    await for (final entity
        in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }

    return total;
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).round()} MB';
  }
}
