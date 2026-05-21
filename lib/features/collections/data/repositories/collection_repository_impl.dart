import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:musea/core/errors/exceptions.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/collections/data/datasources/collection_remote_datasource.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/domain/repositories/collection_repository.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/search/domain/entities/search_result.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  CollectionRepositoryImpl({required this.remoteDataSource});

  final CollectionRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<Collection>>> getCollections(
      {int page = 1, int perPage = 20}) async {
    try {
      final collections =
          await remoteDataSource.getCollections(page: page, perPage: perPage);
      return Right(collections.map((c) => c.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } on RateLimitException catch (e) {
      return Left(Failure.rateLimit(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Collection>> getCollection(String id) async {
    try {
      final collection = await remoteDataSource.getCollection(id);
      return Right(collection.toEntity());
    } on ServerException catch (e) {
      if (e.statusCode == 404) {
        return const Left(Failure.notFound(message: 'Collection not found'));
      }
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } on RateLimitException catch (e) {
      return Left(Failure.rateLimit(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Photo>>> getCollectionPhotos(String id,
      {int page = 1, int perPage = 20}) async {
    try {
      debugPrint(
        '[CollectionRepository] getCollectionPhotos request id=$id page=$page perPage=$perPage',
      );
      final photos = await remoteDataSource.getCollectionPhotos(id,
          page: page, perPage: perPage);
      debugPrint(
        '[CollectionRepository] getCollectionPhotos response id=$id rawCount=${photos.length}',
      );
      return Right(photos.map((p) => p.toEntity()).toList());
    } on ServerException catch (e) {
      debugPrint(
        '[CollectionRepository] getCollectionPhotos serverError id=$id status=${e.statusCode} message=${e.message}',
      );
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      debugPrint(
        '[CollectionRepository] getCollectionPhotos networkError id=$id message=${e.message}',
      );
      return Left(Failure.network(message: e.message));
    } on RateLimitException catch (e) {
      debugPrint(
        '[CollectionRepository] getCollectionPhotos rateLimit id=$id message=${e.message}',
      );
      return Left(Failure.rateLimit(message: e.message));
    } catch (e) {
      debugPrint(
        '[CollectionRepository] getCollectionPhotos unknownError id=$id error=$e',
      );
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SearchCollectionsResult>> searchCollections(
    String query, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await remoteDataSource.searchCollections(
        query,
        page: page,
        perPage: perPage,
      );
      return Right(
        SearchCollectionsResult(
          total: response.total,
          totalPages: response.totalPages,
          results: response.results
              .map((collection) => collection.toEntity())
              .toList(),
        ),
      );
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } on RateLimitException catch (e) {
      return Left(Failure.rateLimit(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Collection>> createCollection({
    required String title,
    String? description,
    bool? private,
  }) async {
    try {
      final collection = await remoteDataSource.createCollection(
        title: title,
        description: description,
        private: private,
      );
      return Right(collection.toEntity());
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } on RateLimitException catch (e) {
      return Left(Failure.rateLimit(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }
}
