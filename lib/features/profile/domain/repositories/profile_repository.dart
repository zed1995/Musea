import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/search/domain/entities/search_result.dart';

abstract class ProfileRepository {
  Future<Either<Failure, User>> getUserProfile(String username);
  Future<Either<Failure, List<Photo>>> getUserPhotos(String username,
      {int page = 1, int perPage = 20});
  Future<Either<Failure, List<Collection>>> getUserCollections(String username,
      {int page = 1, int perPage = 20});
  Future<Either<Failure, List<Photo>>> getUserLikes(String username,
      {int page = 1, int perPage = 20});
  Future<Either<Failure, SearchUsersResult>> searchUsers(
    String query, {
    int page = 1,
    int perPage = 20,
  });
}
