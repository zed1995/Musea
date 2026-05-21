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

    debugPrint('REQUEST[${options.method}] => PATH: ${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    );
    super.onError(err, handler);
  }
}
