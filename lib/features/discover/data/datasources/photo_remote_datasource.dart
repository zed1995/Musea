import 'package:musea/core/network/dio_client.dart';
import 'package:musea/core/constants/api_constants.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';
import 'package:musea/features/discover/data/models/topic_model.dart';

abstract class PhotoRemoteDataSource {
  Future<List<PhotoModel>> getPhotos({int page = 1, int perPage = 20});
  Future<PhotoModel> getPhotoById(String id);
  Future<PhotoModel> getRandomPhoto();
  Future<List<PhotoModel>> getRandomPhotos({int count = 1});
  Future<({int total, int totalPages, List<PhotoModel> results})> searchPhotos(
    String query, {
    int page = 1,
    int perPage = 20,
    String orderBy = 'relevant',
    String? color,
    String? orientation,
    String contentFilter = 'high',
  });
  Future<List<TopicModel>> getTopics({int page = 1, int perPage = 10});
  Future<List<PhotoModel>> getTopicPhotos(String topicSlug, {int page = 1, int perPage = 20});
  Future<void> trackDownload(String photoId);
}

class PhotoRemoteDataSourceImpl implements PhotoRemoteDataSource {
  final DioClient _dioClient;

  PhotoRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<PhotoModel>> getPhotos({int page = 1, int perPage = 20}) async {
    final response = await _dioClient.get(
      ApiConstants.photos,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        'order_by': 'popular',
      },
    );

    return (response as List)
        .map((json) => PhotoModel.fromJson(json))
        .toList();
  }

  @override
  Future<PhotoModel> getPhotoById(String id) async {
    final response = await _dioClient.get(ApiConstants.photoUrl(id));
    return PhotoModel.fromJson(response);
  }

  @override
  Future<PhotoModel> getRandomPhoto() async {
    final response = await _dioClient.get(
      '${ApiConstants.photos}/random',
      queryParameters: {'count': 1},
    );
    
    final photos = response as List;
    return PhotoModel.fromJson(photos.first);
  }

  @override
  Future<List<PhotoModel>> getRandomPhotos({int count = 1}) async {
    final response = await _dioClient.get(
      '${ApiConstants.photos}/random',
      queryParameters: {'count': count},
    );
    
    return (response as List)
        .map((json) => PhotoModel.fromJson(json))
        .toList();
  }

  @override
  Future<({int total, int totalPages, List<PhotoModel> results})> searchPhotos(
    String query, {
    int page = 1,
    int perPage = 20,
    String orderBy = 'relevant',
    String? color,
    String? orientation,
    String contentFilter = 'high',
  }) async {
    final response = await _dioClient.get(
      ApiConstants.searchPhotos,
      queryParameters: {
        'query': query,
        'page': page,
        'per_page': perPage,
        'order_by': orderBy,
        'content_filter': contentFilter,
        if (color != null) 'color': color,
        if (orientation != null) 'orientation': orientation,
      },
    );

    final results = (response['results'] as List)
        .map((json) => PhotoModel.fromJson(json))
        .toList();

    return (
      total: response['total'] as int? ?? 0,
      totalPages: response['total_pages'] as int? ?? 0,
      results: results,
    );
  }

  @override
  Future<List<TopicModel>> getTopics({int page = 1, int perPage = 10}) async {
    final response = await _dioClient.get(
      ApiConstants.topics,
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );

    return (response as List)
        .map((json) => TopicModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<PhotoModel>> getTopicPhotos(String topicSlug, {int page = 1, int perPage = 20}) async {
    final response = await _dioClient.get(
      ApiConstants.topicPhotos(topicSlug),
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );

    return (response as List)
        .map((json) => PhotoModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> trackDownload(String photoId) async {
    await _dioClient.get(ApiConstants.photoDownload(photoId));
  }
}
