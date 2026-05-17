import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/network/providers.dart';
import 'package:musea/features/collections/data/datasources/collection_remote_datasource.dart';
import 'package:musea/features/collections/data/repositories/collection_repository_impl.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/domain/repositories/collection_repository.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';

final collectionRemoteDataSourceProvider = Provider<CollectionRemoteDataSource>((ref) {
  return CollectionRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepositoryImpl(
    remoteDataSource: ref.watch(collectionRemoteDataSourceProvider),
  );
});

final collectionsProvider = FutureProvider.family<List<Collection>, int>((ref, page) async {
  final repository = ref.watch(collectionRepositoryProvider);
  final result = await repository.getCollections(page: page);
  return result.fold(
    (failure) => throw _mapFailureToException(failure),
    (collections) => collections,
  );
});

final collectionDetailProvider = FutureProvider.family<Collection, String>((ref, id) async {
  final repository = ref.watch(collectionRepositoryProvider);
  final result = await repository.getCollection(id);
  return result.fold(
    (failure) => throw _mapFailureToException(failure),
    (collection) => collection,
  );
});

final collectionPhotosProvider = FutureProvider.family<List<Photo>, String>((ref, id) async {
  final repository = ref.watch(collectionRepositoryProvider);
  final result = await repository.getCollectionPhotos(id);
  return result.fold(
    (failure) => throw _mapFailureToException(failure),
    (photos) => photos,
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
