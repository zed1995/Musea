import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/core/constants/api_constants.dart';
import 'package:musea/core/network/api_interceptor.dart';
import 'package:musea/core/network/auth_token_store.dart';

void main() {
  final interceptor = ApiInterceptor();

  setUp(() {
    dotenv.testLoad(
      fileInput: 'UNSPLASH_CLIENT_ID=test-client-id\n',
    );
    AuthTokenStore.instance.clear();
  });

  test('logs concise success metadata without response payload or headers', () {
    final logs = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) logs.add(message);
    };
    addTearDown(() => debugPrint = previousDebugPrint);

    final response = Response(
      data: {'id': 'photo-1', 'kind': 'photo'},
      statusCode: 200,
      headers: Headers.fromMap({
        'x-ratelimit-remaining': ['42'],
      }),
      requestOptions: RequestOptions(
        path: '/photos',
        baseUrl: 'https://api.unsplash.com',
        method: 'GET',
      ),
    );

    interceptor.onResponse(response, ResponseInterceptorHandler());

    expect(logs, hasLength(1));
    expect(logs.single, contains('HTTP method=GET'));
    expect(logs.single, contains('url=https://api.unsplash.com/photos'));
    expect(logs.single, contains('status=200'));
    expect(logs.single, contains('rate_limit_remaining=42'));
    expect(logs.single, isNot(contains('resp=')));
    expect(logs.single, isNot(contains('Authorization')));
    expect(logs.single, isNot(contains('Accept-Version')));
    expect(logs.single, isNot(contains('REQUEST[')));
    expect(logs.single, isNot(contains('RESPONSE[')));
  });

  test('logs concise failure metadata without response payload or headers', () {
    final logs = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) logs.add(message);
    };
    addTearDown(() => debugPrint = previousDebugPrint);

    final requestOptions = RequestOptions(
      path: '/photos',
      baseUrl: 'https://api.unsplash.com',
      method: 'GET',
    );
    final error = DioException(
      requestOptions: requestOptions,
      response: Response(
        data: {'errors': ['rate limit exceeded']},
        statusCode: 403,
        headers: Headers.fromMap({
          'x-ratelimit-remaining': ['0'],
        }),
        requestOptions: requestOptions,
      ),
      message: 'Forbidden',
      type: DioExceptionType.badResponse,
    );

    runZonedGuarded(
      () => interceptor.onError(error, ErrorInterceptorHandler()),
      (_, __) {},
    );

    expect(logs, hasLength(1));
    expect(logs.single, contains('method=GET'));
    expect(logs.single, contains('url=https://api.unsplash.com/photos'));
    expect(logs.single, contains('status=403'));
    expect(logs.single, contains('rate_limit_remaining=0'));
    expect(logs.single, contains('error=Forbidden'));
    expect(logs.single, isNot(contains('resp=')));
    expect(logs.single, isNot(contains('Authorization')));
    expect(logs.single, isNot(contains('Accept-Version')));
  });

  test('uses bearer token when auth token store has an access token', () {
    AuthTokenStore.instance.setAccessToken('token-123');

    final options = RequestOptions(path: '/photos');
    interceptor.onRequest(options, RequestInterceptorHandler());

    expect(options.headers['Authorization'], 'Bearer token-123');
    expect(options.headers['Accept-Version'], 'v1');
  });

  test('falls back to client id when auth token store is empty', () {
    final options = RequestOptions(path: '/photos');
    interceptor.onRequest(options, RequestInterceptorHandler());

    expect(
      options.headers['Authorization'],
      ApiConstants.publicHeaders['Authorization'],
    );
    expect(options.headers['Accept-Version'], 'v1');
  });

  test('preserves explicit authorization header overrides', () {
    final options = RequestOptions(
      path: '/photos/1/like',
      headers: {'Authorization': 'Bearer explicit-token'},
    );

    interceptor.onRequest(options, RequestInterceptorHandler());

    expect(options.headers['Authorization'], 'Bearer explicit-token');
  });
}
