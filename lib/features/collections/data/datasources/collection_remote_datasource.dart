import 'package:musea/core/network/dio_client.dart';
import 'package:musea/core/constants/api_constants.dart';
import 'package:musea/features/collections/data/models/collection_model.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';

abstract class CollectionRemoteDataSource {
  Future<List<CollectionModel>> getCollections({int page = 1, int perPage = 20});
  Future<CollectionModel> getCollection(String id);
  Future<List<PhotoModel>> getCollectionPhotos(String id, {int page = 1, int perPage = 20});
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
}
