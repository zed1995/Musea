import 'package:musea/core/network/dio_client.dart';
import 'package:musea/core/constants/api_constants.dart';
import 'package:musea/features/collections/data/models/collection_model.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';
import 'package:musea/features/discover/data/models/user_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> getUserProfile(String username);
  Future<List<PhotoModel>> getUserPhotos(String username,
      {int page = 1, int perPage = 20});
  Future<List<CollectionModel>> getUserCollections(String username,
      {int page = 1, int perPage = 20});
  Future<List<PhotoModel>> getUserLikes(String username,
      {int page = 1, int perPage = 20});
  Future<({int total, int totalPages, List<UserModel> results})> searchUsers(
    String query, {
    int page = 1,
    int perPage = 20,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final DioClient _dioClient;

  ProfileRemoteDataSourceImpl(this._dioClient);

  @override
  Future<UserModel> getUserProfile(String username) async {
    final response = await _dioClient.get('${ApiConstants.users}/$username');
    return UserModel.fromJson(response);
  }

  @override
  Future<List<PhotoModel>> getUserPhotos(String username,
      {int page = 1, int perPage = 20}) async {
    final response = await _dioClient.get(
      ApiConstants.userPhotos(username),
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );
    return (response as List).map((json) => PhotoModel.fromJson(json)).toList();
  }

  @override
  Future<List<CollectionModel>> getUserCollections(String username,
      {int page = 1, int perPage = 20}) async {
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
  Future<List<PhotoModel>> getUserLikes(String username,
      {int page = 1, int perPage = 20}) async {
    final response = await _dioClient.get(
      ApiConstants.userLikes(username),
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );
    return (response as List).map((json) => PhotoModel.fromJson(json)).toList();
  }

  @override
  Future<({int total, int totalPages, List<UserModel> results})> searchUsers(
    String query, {
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.searchUsers,
      queryParameters: {
        'query': query,
        'page': page,
        'per_page': perPage,
      },
    );

    final results = (response['results'] as List)
        .map((json) => UserModel.fromJson(json))
        .toList();

    return (
      total: response['total'] as int? ?? 0,
      totalPages: response['total_pages'] as int? ?? 0,
      results: results,
    );
  }
}
