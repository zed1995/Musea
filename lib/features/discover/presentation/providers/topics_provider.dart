import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';

final topicsProvider = FutureProvider<List<Topic>>((ref) async {
  final repository = ref.watch(photoRepositoryProvider);
  final result = await repository.getTopics();
  
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (topics) => topics,
  );
});

final topicPhotosProvider = FutureProvider.family<List<Photo>, TopicPhotosParams>((ref, params) async {
  final repository = ref.watch(photoRepositoryProvider);
  final result = await repository.getTopicPhotos(params.topicSlug, page: params.page);
  
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
