import 'package:musea/core/constants/api_constants.dart';
import 'package:musea/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:musea/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:musea/features/auth/domain/entities/auth_session.dart';
import 'package:musea/features/auth/domain/entities/auth_user.dart';
import 'package:musea/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthLocalDataSource localDataSource,
    required AuthRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  final AuthLocalDataSource _localDataSource;
  final AuthRemoteDataSource _remoteDataSource;

  @override
  Uri buildAuthorizationUri({required String state}) {
    final scope = ApiConstants.authScopes.map(Uri.encodeQueryComponent).join(
      '+',
    );
    final query = [
      'client_id=${Uri.encodeQueryComponent(ApiConstants.clientId)}',
      'redirect_uri=${Uri.encodeQueryComponent(ApiConstants.redirectUri)}',
      'response_type=code',
      'scope=$scope',
      'state=${Uri.encodeQueryComponent(state)}',
    ].join('&');

    return Uri.parse(
      '${ApiConstants.unsplashOAuthBaseUrl}'
      '${ApiConstants.oauthAuthorizePath}?$query',
    );
  }

  @override
  Future<void> clearSession() => _localDataSource.clearSession();

  @override
  Future<OAuthToken> exchangeCodeForToken(String code) {
    return _remoteDataSource.exchangeCodeForToken(code);
  }

  @override
  Future<AuthUser> fetchCurrentUser() {
    return _remoteDataSource.getCurrentUser();
  }

  @override
  Future<String?> getPendingOAuthState() {
    return _localDataSource.readPendingOAuthState();
  }

  @override
  Future<AuthSession?> getStoredSession() {
    return _localDataSource.readSession();
  }

  @override
  Future<void> savePendingOAuthState(String? state) {
    return _localDataSource.savePendingOAuthState(state);
  }

  @override
  Future<void> saveSession(AuthSession session) {
    return _localDataSource.saveSession(session);
  }
}
