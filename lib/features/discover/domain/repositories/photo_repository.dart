import 'package:dartz/dartz.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/search/domain/entities/search_result.dart';

abstract class PhotoRepository {
  Future<Either<Failure, List<Photo>>> getPhotos({int page = 1, int perPage = 20});
  Future<Either<Failure, Photo>> getPhotoById(String id);
  Future<Either<Failure, Photo>> getRandomPhoto();
  Future<Either<Failure, SearchPhotosResult>> searchPhotos(
    String query, {
    int page = 1,
    int perPage = 20,
    String orderBy = 'relevant',
    String? color,
    String? orientation,
    String contentFilter = 'high',
  });
  Future<Either<Failure, List<Topic>>> getTopics({int page = 1, int perPage = 10});
  Future<Either<Failure, List<Photo>>> getTopicPhotos(String topicSlug, {int page = 1, int perPage = 20});
  Future<Either<Failure, void>> trackDownload(String photoId);
}
