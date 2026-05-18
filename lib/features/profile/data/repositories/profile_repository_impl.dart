import 'package:dartz/dartz.dart';
import 'package:musea/core/errors/exceptions.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/profile/domain/repositories/profile_repository.dart';
import 'package:musea/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:musea/features/search/domain/entities/search_result.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, User>> getUserProfile(String username) async {
    try {
      final user = await remoteDataSource.getUserProfile(username);
      return Right(user.toEntity());
    } on ServerException catch (e) {
      if (e.statusCode == 404) {
        return Left(Failure.notFound(message: 'User not found'));
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
  Future<Either<Failure, List<Photo>>> getUserPhotos(String username,
      {int page = 1, int perPage = 20}) async {
    try {
      final photos = await remoteDataSource.getUserPhotos(username,
          page: page, perPage: perPage);
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
  Future<Either<Failure, List<Collection>>> getUserCollections(String username,
      {int page = 1, int perPage = 20}) async {
    try {
      final collections = await remoteDataSource.getUserCollections(
        username,
        page: page,
        perPage: perPage,
      );
      return Right(
          collections.map((collection) => collection.toEntity()).toList());
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
  Future<Either<Failure, List<Photo>>> getUserLikes(String username,
      {int page = 1, int perPage = 20}) async {
    try {
      final likes = await remoteDataSource.getUserLikes(
        username,
        page: page,
        perPage: perPage,
      );
      return Right(likes.map((photo) => photo.toEntity()).toList());
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
  Future<Either<Failure, SearchUsersResult>> searchUsers(
    String query, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await remoteDataSource.searchUsers(
        query,
        page: page,
        perPage: perPage,
      );
      return Right(
        SearchUsersResult(
          total: response.total,
          totalPages: response.totalPages,
          results: response.results.map((user) => user.toEntity()).toList(),
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
}
