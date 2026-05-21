import 'package:musea/core/network/dio_client.dart';
import 'package:musea/core/constants/api_constants.dart';
import 'package:musea/features/collections/data/models/collection_model.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';

abstract class CollectionRemoteDataSource {
  Future<List<CollectionModel>> getCollections({int page = 1, int perPage = 20});
  Future<List<CollectionModel>> getUserCollections(
    String username, {
    int page = 1,
    int perPage = 20,
  });
  Future<CollectionModel> getCollection(String id);
  Future<List<PhotoModel>> getCollectionPhotos(String id, {int page = 1, int perPage = 20});
  Future<({int total, int totalPages, List<CollectionModel> results})>
      searchCollections(
    String query, {
    int page = 1,
    int perPage = 20,
  });

  Future<CollectionModel> createCollection({
    required String title,
    String? description,
    bool? private,
  });

  Future<void> addPhotoToCollection({
    required String collectionId,
    required String photoId,
  });
}

class CollectionRemoteDataSourceImpl implements CollectionRemoteDataSource {
  CollectionRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<List<CollectionModel>> getCollections({int page = 1, int perPage = 20}) async {
    final response = await _dioClient.get(
      ApiConstants.collections,
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );
    return (response as List)
        .map((json) => CollectionModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<CollectionModel>> getUserCollections(
    String username, {
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.userCollections(username),
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );
    return (response as List)
        .map((json) => CollectionModel.fromJson(json))
        .toList();
  }

  @override
  Future<CollectionModel> getCollection(String id) async {
    final response = await _dioClient.get('${ApiConstants.collections}/$id');
    return CollectionModel.fromJson(response);
  }

  @override
  Future<List<PhotoModel>> getCollectionPhotos(String id, {int page = 1, int perPage = 20}) async {
    final response = await _dioClient.get(
      '${ApiConstants.collections}/$id/photos',
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
  Future<({int total, int totalPages, List<CollectionModel> results})>
      searchCollections(
    String query, {
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.searchCollections,
      queryParameters: {
        'query': query,
        'page': page,
        'per_page': perPage,
      },
    );

    final results = (response['results'] as List)
        .map((json) => CollectionModel.fromJson(json))
        .toList();

    return (
      total: response['total'] as int? ?? 0,
      totalPages: response['total_pages'] as int? ?? 0,
      results: results,
    );
  }

  @override
  Future<CollectionModel> createCollection({
    required String title,
    String? description,
    bool? private,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.collections,
      data: {
        'title': title,
        if (description != null) 'description': description,
        if (private != null) 'private': private,
      },
    );
    return CollectionModel.fromJson(response);
  }

  @override
  Future<void> addPhotoToCollection({
    required String collectionId,
    required String photoId,
  }) async {
    await _dioClient.post(
      ApiConstants.collectionAdd(collectionId),
      data: {'photo_id': photoId},
    );
  }
}
