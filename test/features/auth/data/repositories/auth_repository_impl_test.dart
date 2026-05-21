import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:musea/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:musea/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:musea/features/auth/domain/entities/auth_session.dart';
import 'package:musea/features/auth/domain/entities/auth_user.dart';

void main() {
  setUp(() {
    dotenv.testLoad(
      fileInput: '''
UNSPLASH_CLIENT_ID=test-client-id
UNSPLASH_CLIENT_SECRET=test-client-secret
UNSPLASH_REDIRECT_URI=musea://auth/callback
''',
    );
  });

  test('buildAuthorizationUri keeps plus-separated OAuth scopes', () {
    final repository = AuthRepositoryImpl(
      localDataSource: _FakeAuthLocalDataSource(),
      remoteDataSource: _FakeAuthRemoteDataSource(),
    );

    final uri = repository.buildAuthorizationUri(state: 'oauth-state');

    expect(
      uri.toString(),
      contains('scope=public+read_user'),
    );
  });
}

class _FakeAuthLocalDataSource implements AuthLocalDataSource {
  @override
  Future<void> clearSession() async {}

  @override
  Future<String?> readPendingOAuthState() async => null;

  @override
  Future<AuthSession?> readSession() async => null;

  @override
  Future<void> savePendingOAuthState(String? state) async {}

  @override
  Future<void> saveSession(AuthSession session) async {}
}

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<OAuthToken> exchangeCodeForToken(String code) {
    throw UnimplementedError();
  }

  @override
  Future<AuthUser> getCurrentUser() {
    throw UnimplementedError();
  }
}
