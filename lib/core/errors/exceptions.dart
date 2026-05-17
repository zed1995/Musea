class ServerException implements Exception {
  final int statusCode;
  final String message;
  
  ServerException({
    required this.statusCode,
    required this.message,
  });
  
  @override
  String toString() => 'ServerException: $statusCode - $message';
}

class NetworkException implements Exception {
  final String message;
  
  NetworkException({required this.message});
  
  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;
  
  CacheException({required this.message});
  
  @override
  String toString() => 'CacheException: $message';
}

class UnauthorizedException implements Exception {
  final String message;
  
  UnauthorizedException({required this.message});
  
  @override
  String toString() => 'UnauthorizedException: $message';
}

class RateLimitException implements Exception {
  final String message;
  
  RateLimitException({required this.message});
  
  @override
  String toString() => 'RateLimitException: $message';
}
