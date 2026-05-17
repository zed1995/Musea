class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.unsplash.com';
  
  static const String photos = '/photos';
  static const String searchPhotos = '/search/photos';
  static const String topics = '/topics';
  static const String users = '/users';
  static const String collections = '/collections';
  
  static const String clientId = 'YOUR_UNSPLASH_CLIENT_ID';
  
  static const int defaultPerPage = 20;
  static const int searchPerPage = 30;
  
  static Map<String, String> get headers => {
    'Authorization': 'Client-ID $clientId',
    'Accept-Version': 'v1',
  };
  
  static String photoUrl(String photoId) => '$photos/$photoId';
  static String photoStatistics(String photoId) => '$photos/$photoId/statistics';
  static String photoDownload(String photoId) => '$photos/$photoId/download';
  static String topicPhotos(String topicSlug) => '$topics/$topicSlug/photos';
  static String userPhotos(String username) => '$users/$username/photos';
}
