import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/network/dio_client.dart';
import 'package:musea/features/discover/data/datasources/photo_local_datasource.dart';
import 'package:musea/features/discover/data/datasources/photo_remote_datasource.dart';
import 'package:musea/features/discover/data/datasources/topic_local_datasource.dart';
import 'package:musea/features/discover/data/repositories/photo_repository_impl.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/repositories/photo_repository.dart';
import 'package:musea/core/errors/failures.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final photoRemoteDataSourceProvider = Provider<PhotoRemoteDataSource>((ref) {
  return PhotoRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final photoLocalDataSourceProvider = Provider<PhotoLocalDataSource>((ref) {
  return PhotoLocalDataSourceImpl();
});

final topicLocalDataSourceProvider = Provider<TopicLocalDataSource>((ref) {
  return TopicLocalDataSourceImpl();
});

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepositoryImpl(
    remoteDataSource: ref.watch(photoRemoteDataSourceProvider),
    localDataSource: ref.watch(photoLocalDataSourceProvider),
    topicLocalDataSource: ref.watch(topicLocalDataSourceProvider),
  );
});

final photosProvider = FutureProvider.family<List<Photo>, int>((ref, page) async {
  final repository = ref.watch(photoRepositoryProvider);
  final result = await repository.getPhotos(page: page);
  
  return result.fold(
    (failure) => throw _mapFailureToException(failure),
    (photos) => photos,
  );
});

final photoDetailProvider = FutureProvider.family<Photo, String>((ref, id) async {
  final repository = ref.watch(photoRepositoryProvider);
  final result = await repository.getPhotoById(id);
  
  return result.fold(
    (failure) => throw _mapFailureToException(failure),
    (photo) => photo,
  );
});

final randomPhotoProvider = FutureProvider<Photo>((ref) async {
  final repository = ref.watch(photoRepositoryProvider);
  final result = await repository.getRandomPhoto();
  
  return result.fold(
    (failure) => throw _mapFailureToException(failure),
    (photo) => photo,
  );
});

Exception _mapFailureToException(Failure failure) {
  return failure.when(
    network: (message) => Exception('Network error: $message'),
    server: (statusCode, message) => Exception('Server error ($statusCode): $message'),
    cache: (message) => Exception('Cache error: $message'),
    notFound: (message) => Exception('Not found: $message'),
    unauthorized: (message) => Exception('Unauthorized: $message'),
    rateLimit: (message) => Exception('Rate limit: $message'),
    unknown: (message) => Exception('Error: $message'),
  );
}
