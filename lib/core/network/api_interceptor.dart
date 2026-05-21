import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:musea/core/constants/api_constants.dart';
import 'package:musea/core/network/auth_token_store.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent('Accept-Version', () => 'v1');
    final accessToken = AuthTokenStore.instance.accessToken;
    if (!options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = accessToken != null
          ? 'Bearer $accessToken'
          : ApiConstants.publicHeaders['Authorization']!;
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      'HTTP url=${_fullUrl(response.requestOptions)} '
      'resp=${response.data} '
      'rate_limit_remaining=${_rateLimitRemaining(response.headers)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      'HTTP_ERROR url=${_fullUrl(err.requestOptions)} '
      'status=${err.response?.statusCode ?? 'unknown'} '
      'resp=${err.response?.data} '
      'rate_limit_remaining=${_rateLimitRemaining(err.response?.headers)} '
      'error=${err.message ?? err.error}',
    );
    handler.next(err);
  }

  String _fullUrl(RequestOptions options) {
    final uri = options.uri;
    if (uri.hasScheme) return uri.toString();
    return '${options.baseUrl}${options.path}';
  }

  String _rateLimitRemaining(Headers? headers) {
    final remaining = headers?.value('x-ratelimit-remaining');
    return remaining ?? 'unknown';
  }
}
