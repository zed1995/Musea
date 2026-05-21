import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/features/discover/data/datasources/topic_local_datasource.dart';
import 'package:musea/features/discover/data/models/topic_model.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/discover/domain/repositories/photo_repository.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/discover/presentation/providers/topics_provider.dart';

class MockPhotoRepository extends Mock implements PhotoRepository {}

class MockTopicLocalDataSource extends Mock implements TopicLocalDataSource {}

void main() {
  late MockPhotoRepository mockRepo;
  late MockTopicLocalDataSource mockDS;

  setUp(() {
    mockRepo = MockPhotoRepository();
    mockDS = MockTopicLocalDataSource();
  });

  test('fetches topics from network when no cache exists', () async {
    when(() => mockDS.getTopics()).thenAnswer((_) async => <TopicModel>[]);
    when(() => mockDS.getLastUpdatedAt()).thenAnswer((_) async => null);
    when(() => mockRepo.getTopics()).thenAnswer((_) async =>
        Right([const Topic(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10)]));
    when(() => mockDS.saveTopics(any())).thenAnswer((_) async => {});

    final container = ProviderContainer(
      overrides: [
        photoRepositoryProvider.overrideWithValue(mockRepo),
        topicLocalDataSourceProvider.overrideWithValue(mockDS),
      ],
    );
    addTearDown(container.dispose);

    container.read(topicsProvider);
    await Future.delayed(Duration.zero);

    // State is populated after background fetch completes
    expect(container.read(topicsProvider).length, 1);
    verify(() => mockRepo.getTopics()).called(1);
  });

  test('returns cached topics when cache is valid', () async {
    when(() => mockDS.getTopics()).thenAnswer((_) async => [
      const TopicModel(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
    ]);
    when(() => mockDS.getLastUpdatedAt()).thenAnswer((_) async => DateTime.now());

    final container = ProviderContainer(
      overrides: [
        photoRepositoryProvider.overrideWithValue(mockRepo),
        topicLocalDataSourceProvider.overrideWithValue(mockDS),
      ],
    );
    addTearDown(container.dispose);

    container.read(topicsProvider);
    await Future.delayed(Duration.zero);

    expect(container.read(topicsProvider).length, 1);
    expect(container.read(topicsProvider)[0].title, 'Nature');
  });

  test('returns cached topics and fires refresh when stale', () async {
    when(() => mockDS.getTopics()).thenAnswer((_) async => [
      const TopicModel(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
    ]);
    when(() => mockDS.getLastUpdatedAt()).thenAnswer((_) async =>
        DateTime.now().subtract(const Duration(hours: 25)));
    when(() => mockRepo.getTopics()).thenAnswer((_) async =>
        Right([const Topic(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10)]));
    when(() => mockDS.saveTopics(any())).thenAnswer((_) async => {});

    final container = ProviderContainer(
      overrides: [
        photoRepositoryProvider.overrideWithValue(mockRepo),
        topicLocalDataSourceProvider.overrideWithValue(mockDS),
      ],
    );
    addTearDown(container.dispose);

    container.read(topicsProvider);
    await Future.delayed(Duration.zero);

    // State should be cached data
    expect(container.read(topicsProvider).length, 1);

    // Background refresh should have been triggered
    verify(() => mockRepo.getTopics()).called(1);
  });

  test('does not fire network request when cache is fresh', () async {
    when(() => mockDS.getTopics()).thenAnswer((_) async => [
      const TopicModel(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
    ]);
    when(() => mockDS.getLastUpdatedAt()).thenAnswer((_) async =>
        DateTime.now().subtract(const Duration(hours: 1)));

    final container = ProviderContainer(
      overrides: [
        photoRepositoryProvider.overrideWithValue(mockRepo),
        topicLocalDataSourceProvider.overrideWithValue(mockDS),
      ],
    );
    addTearDown(container.dispose);

    container.read(topicsProvider);
    await Future.delayed(Duration.zero);

    verifyNever(() => mockRepo.getTopics());
  });
}
