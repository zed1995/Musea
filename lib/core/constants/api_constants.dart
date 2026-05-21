import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.unsplash.com';
  static const String unsplashOAuthBaseUrl = 'https://unsplash.com';

  static const String photos = '/photos';
  static const String searchPhotos = '/search/photos';
  static const String searchCollections = '/search/collections';
  static const String searchUsers = '/search/users';
  static const String topics = '/topics';
  static const String users = '/users';
  static const String collections = '/collections';
  static const String me = '/me';
  static const String oauthAuthorizePath = '/oauth/authorize';
  static const String oauthTokenPath = '/oauth/token';
  static const List<String> authScopes = ['public', 'read_user', 'write_likes', 'write_collections', 'read_collections'];

  static String get clientId {
    final id = dotenv.env['UNSPLASH_CLIENT_ID'];
    if (id == null || id == 'YOUR_UNSPLASH_CLIENT_ID_HERE') {
      throw Exception(
        'UNSPLASH_CLIENT_ID not configured. Please check your .env file.\n'
        'See docs/ENV_SETUP.md for instructions.',
      );
    }
    return id;
  }

  static String get clientSecret {
    final secret = dotenv.env['UNSPLASH_CLIENT_SECRET'];
    if (secret == null || secret == 'YOUR_UNSPLASH_CLIENT_SECRET_HERE') {
      throw Exception(
        'UNSPLASH_CLIENT_SECRET not configured. Please check your .env file.\n'
        'See docs/ENV_SETUP.md for instructions.',
      );
    }
    return secret;
  }

  static String get redirectUri {
    final redirectUri = dotenv.env['UNSPLASH_REDIRECT_URI'];
    if (redirectUri == null || redirectUri.isEmpty) {
      throw Exception(
        'UNSPLASH_REDIRECT_URI not configured. Please check your .env file.\n'
        'See docs/ENV_SETUP.md for instructions.',
      );
    }
    return redirectUri;
  }

  static const int defaultPerPage = 20;
  static const int searchPerPage = 30;

  static Map<String, String> get publicHeaders => {
        'Authorization': 'Client-ID $clientId',
        'Accept-Version': 'v1',
      };

  static String photoUrl(String photoId) => '$photos/$photoId';
  static String photoStatistics(String photoId) =>
      '$photos/$photoId/statistics';
  static String photoDownload(String photoId) => '$photos/$photoId/download';
  static String photoLike(String photoId) => '$photos/$photoId/like';
  static String topicPhotos(String topicSlug) => '$topics/$topicSlug/photos';
  static String userPhotos(String username) => '$users/$username/photos';
  static String userLikes(String username) => '$users/$username/likes';
  static String userCollections(String username) =>
      '$users/$username/collections';
  static String collectionAdd(String collectionId) =>
      '$collections/$collectionId/add';
}
