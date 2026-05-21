import 'package:dartz/dartz.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/search/domain/entities/search_result.dart';

abstract class CollectionRepository {
  Future<Either<Failure, List<Collection>>> getCollections({int page = 1, int perPage = 20});
  Future<Either<Failure, List<Collection>>> getUserCollections(
    String username, {
    int page = 1,
    int perPage = 20,
  });
  Future<Either<Failure, Collection>> getCollection(String id);
  Future<Either<Failure, List<Photo>>> getCollectionPhotos(String id, {int page = 1, int perPage = 20});
  Future<Either<Failure, SearchCollectionsResult>> searchCollections(
    String query, {
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, Collection>> createCollection({
    required String title,
    String? description,
    bool? private,
  });

  Future<Either<Failure, void>> addPhotoToCollection({
    required String collectionId,
    required String photoId,
  });
}
