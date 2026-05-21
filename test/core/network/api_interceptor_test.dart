import 'package:dio/dio.dart';
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
