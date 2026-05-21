import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musea/features/discover/data/datasources/topic_local_datasource.dart';
import 'package:musea/features/discover/data/models/topic_model.dart';

void main() {
  late TopicLocalDataSource dataSource;

  setUp(() async {
    Hive.init(Directory.systemTemp.path);
    dataSource = TopicLocalDataSourceImpl();
  });

  tearDown(() async {
    await dataSource.clearCache();
  });

  test('saveTopics stores topics and timestamp', () async {
    final topics = [
      const TopicModel(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
      const TopicModel(id: '2', slug: 'architecture', title: 'Architecture', totalPhotos: 5),
    ];

    await dataSource.saveTopics(topics);
    final cached = await dataSource.getTopics();
    final lastUpdated = await dataSource.getLastUpdatedAt();

    expect(cached.length, 2);
    expect(cached[0].id, '1');
    expect(cached[1].id, '2');
    expect(lastUpdated, isNotNull);
  });

  test('getTopics returns empty list when cache is empty', () async {
    final cached = await dataSource.getTopics();
    expect(cached, isEmpty);
  });

  test('getLastUpdatedAt returns null when cache is empty', () async {
    final lastUpdated = await dataSource.getLastUpdatedAt();
    expect(lastUpdated, isNull);
  });

  test('clearCache removes all data', () async {
    final topics = [
      const TopicModel(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
    ];

    await dataSource.saveTopics(topics);
    await dataSource.clearCache();

    final cached = await dataSource.getTopics();
    final lastUpdated = await dataSource.getLastUpdatedAt();

    expect(cached, isEmpty);
    expect(lastUpdated, isNull);
  });
}
