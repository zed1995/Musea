import 'package:dartz/dartz.dart';
import 'package:musea/core/errors/exceptions.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/discover/domain/repositories/photo_repository.dart';
import 'package:musea/features/discover/data/datasources/photo_remote_datasource.dart';
import 'package:musea/features/discover/data/datasources/photo_local_datasource.dart';
import 'package:musea/features/discover/data/datasources/topic_local_datasource.dart';
import 'package:musea/features/search/domain/entities/search_result.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  PhotoRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.topicLocalDataSource,
  });

  final PhotoRemoteDataSource remoteDataSource;
  final PhotoLocalDataSource localDataSource;
  final TopicLocalDataSource topicLocalDataSource;

  @override
  Future<Either<Failure, List<Photo>>> getPhotos(
      {int page = 1, int perPage = 20}) async {
    try {
      final photos =
          await remoteDataSource.getPhotos(page: page, perPage: perPage);
      return Right(photos.map((p) => p.toEntity()).toList());
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
  Future<Either<Failure, Photo>> getPhotoById(String id) async {
    try {
      final photo = await remoteDataSource.getPhotoById(id);
      return Right(photo.toEntity());
    } on ServerException catch (e) {
      if (e.statusCode == 404) {
        return const Left(Failure.notFound(message: 'Photo not found'));
      }
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Photo>> getRandomPhoto() async {
    try {
      final photo = await remoteDataSource.getRandomPhoto();
      return Right(photo.toEntity());
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SearchPhotosResult>> searchPhotos(
    String query, {
    int page = 1,
    int perPage = 20,
    String orderBy = 'relevant',
    String? color,
    String? orientation,
    String contentFilter = 'high',
  }) async {
    try {
      final response = await remoteDataSource.searchPhotos(
        query,
        page: page,
        perPage: perPage,
        orderBy: orderBy,
        color: color,
        orientation: orientation,
        contentFilter: contentFilter,
      );
      return Right(
        SearchPhotosResult(
          total: response.total,
          totalPages: response.totalPages,
          results: response.results.map((photo) => photo.toEntity()).toList(),
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
  Future<Either<Failure, List<Topic>>> getTopics(
      {int page = 1, int perPage = 10}) async {
    try {
      final topics =
          await remoteDataSource.getTopics(page: page, perPage: perPage);
      await topicLocalDataSource.saveTopics(topics);
      return Right(topics.map((t) => t.toEntity()).toList());
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
  Future<Either<Failure, List<Photo>>> getTopicPhotos(String topicSlug,
      {int page = 1, int perPage = 20}) async {
    try {
      final photos = await remoteDataSource.getTopicPhotos(topicSlug,
          page: page, perPage: perPage);
      return Right(photos.map((p) => p.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> trackDownload(String photoId) async {
    try {
      await remoteDataSource.trackDownload(photoId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Photo>> likePhoto(String photoId) async {
    try {
      final photo = await remoteDataSource.likePhoto(photoId);
      return Right(photo.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(Failure.unauthorized(message: e.message));
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
  Future<Either<Failure, Photo>> unlikePhoto(String photoId) async {
    try {
      final photo = await remoteDataSource.unlikePhoto(photoId);
      return Right(photo.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(Failure.unauthorized(message: e.message));
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
