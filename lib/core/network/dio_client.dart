import 'package:dio/dio.dart';
import 'package:musea/core/errors/exceptions.dart';
import 'package:musea/core/network/api_interceptor.dart';
import 'package:musea/core/constants/api_constants.dart';

class DioClient {
  DioClient([Dio? dio]) : _dio = dio ?? _createDio();

  final Dio _dio;

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));

    dio.interceptors.addAll([
      ApiInterceptor(),
    ]);

    return dio;
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Never _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw NetworkException(message: 'Connection timeout');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final message = error.response?.statusMessage ?? 'Unknown error';

        if (statusCode == 401) {
          throw UnauthorizedException(message: 'Unauthorized access');
        } else if (statusCode == 403) {
          throw RateLimitException(message: 'Rate limit exceeded');
        } else if (statusCode == 404) {
          throw ServerException(
              statusCode: statusCode, message: 'Resource not found');
        } else {
          throw ServerException(statusCode: statusCode, message: message);
        }

      case DioExceptionType.cancel:
        throw NetworkException(message: 'Request cancelled');

      case DioExceptionType.connectionError:
        throw NetworkException(message: 'No internet connection');

      default:
        throw NetworkException(
            message: error.message ?? 'Unexpected error occurred');
    }
  }
}
