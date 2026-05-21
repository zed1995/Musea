import 'package:musea/features/auth/domain/entities/auth_session.dart';
import 'package:musea/features/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthSession?> getStoredSession();
  Future<void> saveSession(AuthSession session);
  Future<void> clearSession();
  Future<String?> getPendingOAuthState();
  Future<void> savePendingOAuthState(String? state);
  Uri buildAuthorizationUri({required String state});
  Future<OAuthToken> exchangeCodeForToken(String code);
  Future<AuthUser> fetchCurrentUser();
}
