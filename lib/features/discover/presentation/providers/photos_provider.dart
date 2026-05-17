import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/network/dio_client.dart';
import 'package:musea/features/discover/data/datasources/photo_local_datasource.dart';
import 'package:musea/features/discover/data/datasources/photo_remote_datasource.dart';
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

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepositoryImpl(
    remoteDataSource: ref.watch(photoRemoteDataSourceProvider),
    localDataSource: ref.watch(photoLocalDataSourceProvider),
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
  return failure.maybeWhen(
    network: (message) => Exception(message),
    server: (statusCode, message) => Exception('$statusCode: $message'),
    rateLimit: (message) => Exception(message),
    orElse: () => Exception('Unknown error'),
  );
}
