import 'package:dio/dio.dart';
import 'package:musea/core/constants/api_constants.dart';
import 'package:musea/core/errors/exceptions.dart';
import 'package:musea/core/network/dio_client.dart';
import 'package:musea/features/auth/domain/entities/auth_session.dart';
import 'package:musea/features/auth/domain/entities/auth_user.dart';

abstract class AuthRemoteDataSource {
  Future<OAuthToken> exchangeCodeForToken(String code);
  Future<AuthUser> getCurrentUser(String accessToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dioClient, [Dio? oauthDio])
      : _oauthDio = oauthDio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.unsplashOAuthBaseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 30),
                contentType: Headers.formUrlEncodedContentType,
              ),
            );

  final DioClient _dioClient;
  final Dio _oauthDio;

  @override
  Future<OAuthToken> exchangeCodeForToken(String code) async {
    try {
      final response = await _oauthDio.post<Map<String, dynamic>>(
        ApiConstants.oauthTokenPath,
        data: {
          'client_id': ApiConstants.clientId,
          'client_secret': ApiConstants.clientSecret,
          'redirect_uri': ApiConstants.redirectUri,
          'code': code,
          'grant_type': 'authorization_code',
        },
      );

      final data = response.data ?? <String, dynamic>{};
      return OAuthToken(
        accessToken: data['access_token'] as String? ?? '',
        tokenType: data['token_type'] as String? ?? 'bearer',
        scope: data['scope'] as String? ?? '',
        createdAt: (data['created_at'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (error) {
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response?.data['error_description'] as String? ??
              error.response?.data['error'] as String? ??
              'OAuth token exchange failed')
          : (error.message ?? 'OAuth token exchange failed');
      throw ServerException(
        statusCode: error.response?.statusCode ?? 500,
        message: message,
      );
    }
  }

  @override
  Future<AuthUser> getCurrentUser(String accessToken) async {
    final response = await _dioClient.get(
      ApiConstants.me,
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept-Version': 'v1',
        },
      ),
    );

    final data = Map<String, dynamic>.from(response as Map);
    final firstName = data['first_name'] as String?;
    final lastName = data['last_name'] as String?;
    final fullName = (data['name'] as String?)?.trim();
    final fallbackName = [
      if (firstName != null && firstName.trim().isNotEmpty) firstName.trim(),
      if (lastName != null && lastName.trim().isNotEmpty) lastName.trim(),
    ].join(' ');

    final profileImage = data['profile_image'] as Map<String, dynamic>? ?? {};

    return AuthUser(
      id: data['id'] as String? ?? '',
      username: data['username'] as String? ?? '',
      displayName: fullName != null && fullName.isNotEmpty
          ? fullName
          : (fallbackName.isNotEmpty
              ? fallbackName
              : data['username'] as String? ?? ''),
      firstName: firstName,
      lastName: lastName,
      bio: data['bio'] as String?,
      location: data['location'] as String?,
      email: data['email'] as String?,
      instagramUsername: data['instagram_username'] as String?,
      twitterUsername: data['twitter_username'] as String?,
      portfolioUrl: data['portfolio_url'] as String?,
      profileImageSmall: profileImage['small'] as String?,
      profileImageMedium: profileImage['medium'] as String? ??
          profileImage['small'] as String? ??
          '',
      profileImageLarge: profileImage['large'] as String?,
      totalPhotos: (data['total_photos'] as num?)?.toInt() ?? 0,
      totalLikes: (data['total_likes'] as num?)?.toInt() ?? 0,
      totalCollections: (data['total_collections'] as num?)?.toInt() ?? 0,
      downloads: (data['downloads'] as num?)?.toInt(),
    );
  }
}
