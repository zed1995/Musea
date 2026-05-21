import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/discover/data/models/topic_model.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';

final topicsProvider = NotifierProvider<TopicListNotifier, List<Topic>>(
  TopicListNotifier.new,
);

class TopicListNotifier extends Notifier<List<Topic>> {
  @override
  List<Topic> build() {
    _init();
    return [];
  }

  Future<void> _init() async {
    final localDataSource = ref.read(topicLocalDataSourceProvider);

    // 1. Read cache first
    final cached = await localDataSource.getTopics();
    if (cached.isNotEmpty) {
      state = cached.map((e) => e.toEntity()).toList();
    }

    // 2. Check TTL
    final lastUpdated = await localDataSource.getLastUpdatedAt();
    if (lastUpdated != null &&
        DateTime.now().difference(lastUpdated).inHours < 24) {
      return; // cache is still fresh
    }

    // 3. Background refresh
    _refreshInBackground();
  }

  Future<void> _refreshInBackground() async {
    final repository = ref.read(photoRepositoryProvider);
    final localDataSource = ref.read(topicLocalDataSourceProvider);

    final result = await repository.getTopics();
    result.fold(
      (failure) => {/* silent */},
      (topics) async {
        final models = topics
            .map((t) => TopicModel(
                  id: t.id,
                  slug: t.slug,
                  title: t.title,
                  description: t.description,
                  totalPhotos: t.totalPhotos,
                ))
            .toList();
        await localDataSource.saveTopics(models);
        if (state.isEmpty) {
          state = topics;
        }
      },
    );
  }
}

// topicPhotosProvider and TopicPhotosParams stay the same
final topicPhotosProvider = FutureProvider.family<List<Photo>, TopicPhotosParams>(
    (ref, params) async {
  final repository = ref.watch(photoRepositoryProvider);
  final result =
      await repository.getTopicPhotos(params.topicSlug, page: params.page);

  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (photos) => photos,
  );
});

class TopicPhotosParams {
  final String topicSlug;
  final int page;

  TopicPhotosParams({
    required this.topicSlug,
    this.page = 1,
  });
}
