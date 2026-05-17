import 'package:musea/core/network/dio_client.dart';
import 'package:musea/core/constants/api_constants.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';
import 'package:musea/features/discover/data/models/user_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> getUserProfile(String username);
  Future<List<PhotoModel>> getUserPhotos(String username, {int page = 1, int perPage = 20});
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
  Future<List<PhotoModel>> getUserPhotos(String username, {int page = 1, int perPage = 20}) async {
    final response = await _dioClient.get(
      ApiConstants.userPhotos(username),
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
