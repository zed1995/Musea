import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/auth/domain/entities/auth_session.dart';
import 'package:musea/features/auth/domain/entities/auth_user.dart';
import 'package:musea/features/auth/domain/repositories/auth_repository.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';

void main() {
  group('AuthController', () {
    test('beginSignIn persists pending state and launches authorize URL',
        () async {
      final repository = _FakeAuthRepository();
      final launcher = _FakeAuthLauncher();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          authLauncherProvider.overrideWithValue(launcher),
          authClockProvider.overrideWithValue(() => DateTime(2026, 5, 20, 12)),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).beginSignIn();

      expect(repository.pendingState, isNotNull);
      expect(launcher.launchedUri, isNotNull);
      expect(
        launcher.launchedUri!.queryParameters['state'],
        repository.pendingState,
      );
      expect(
        container.read(authControllerProvider).isAuthorizing,
        isTrue,
      );
    });

    test('handleCallback exchanges code, fetches me, and stores session',
        () async {
      final repository = _FakeAuthRepository();
      final launcher = _FakeAuthLauncher();
      const expectedUser = AuthUser(
        id: 'user-1',
        username: 'spaciba',
        displayName: 'Paula Poeira',
        firstName: 'Paula',
        lastName: 'Poeira',
        profileImageMedium: 'https://example.com/avatar-medium.jpg',
        totalPhotos: 12,
        totalLikes: 34,
        totalCollections: 56,
      );
      repository.pendingState = 'oauth-state';
      repository.tokenToReturn = const OAuthToken(
        accessToken: 'token-123',
        tokenType: 'bearer',
        scope: 'public read_user',
        createdAt: 123456,
      );
      repository.userToReturn = expectedUser;

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          authLauncherProvider.overrideWithValue(launcher),
          authClockProvider.overrideWithValue(() => DateTime(2026, 5, 20, 13)),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).handleCallbackUri(
            Uri.parse(
              'musea://auth/callback?code=abc123&state=oauth-state',
            ),
          );

      final state = container.read(authControllerProvider);
      expect(repository.exchangedCode, 'abc123');
      expect(repository.requestedMeToken, 'token-123');
      expect(repository.savedSession, isNotNull);
      expect(repository.pendingState, isNull);
      expect(state.isAuthenticated, isTrue);
      expect(state.session?.user.username, 'spaciba');
      expect(state.errorMessage, isNull);
    });

    test('refreshIfNeeded skips fresh cache and refreshes stale cache',
        () async {
      final freshSession = AuthSession(
        accessToken: 'token-1',
        tokenType: 'bearer',
        scope: 'public read_user',
        createdAt: 1,
        user: const AuthUser(
          id: 'user-1',
          username: 'fresh',
          displayName: 'Fresh User',
          profileImageMedium: 'https://example.com/avatar.jpg',
          totalPhotos: 1,
          totalLikes: 2,
          totalCollections: 3,
        ),
        lastProfileRefreshAt: DateTime(2026, 5, 20, 10, 55),
      );

      final staleSession = freshSession.copyWith(
        user: freshSession.user.copyWith(
          username: 'stale',
          displayName: 'Stale User',
        ),
        lastProfileRefreshAt: DateTime(2026, 5, 20, 9, 30),
      );

      final repository = _FakeAuthRepository()
        ..storedSession = freshSession
        ..userToReturn = staleSession.user.copyWith(
          username: 'updated',
          displayName: 'Updated User',
        );

      final freshContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          authLauncherProvider.overrideWithValue(_FakeAuthLauncher()),
          authBootstrapSessionProvider.overrideWithValue(freshSession),
          authClockProvider.overrideWithValue(() => DateTime(2026, 5, 20, 11)),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
        ],
      );
      addTearDown(freshContainer.dispose);

      await freshContainer
          .read(authControllerProvider.notifier)
          .refreshIfNeeded();
      expect(repository.requestedMeToken, isNull);

      repository.requestedMeToken = null;
      repository.savedSession = null;

      final staleContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          authLauncherProvider.overrideWithValue(_FakeAuthLauncher()),
          authBootstrapSessionProvider.overrideWithValue(staleSession),
          authClockProvider.overrideWithValue(() => DateTime(2026, 5, 20, 11)),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
        ],
      );
      addTearDown(staleContainer.dispose);

      await staleContainer
          .read(authControllerProvider.notifier)
          .refreshIfNeeded();

      expect(repository.requestedMeToken, 'token-1');
      expect(
        staleContainer.read(authControllerProvider).session?.user.username,
        'updated',
      );
      expect(repository.savedSession?.user.username, 'updated');
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  AuthSession? storedSession;
  AuthSession? savedSession;
  String? pendingState;
  OAuthToken? tokenToReturn;
  AuthUser? userToReturn;
  String? exchangedCode;
  String? requestedMeToken;

  @override
  Uri buildAuthorizationUri({required String state}) {
    return Uri.parse(
      'https://unsplash.com/oauth/authorize?client_id=demo&state=$state',
    );
  }

  @override
  Future<void> clearSession() async {
    storedSession = null;
    savedSession = null;
  }

  @override
  Future<OAuthToken> exchangeCodeForToken(String code) async {
    exchangedCode = code;
    return tokenToReturn!;
  }

  @override
  Future<AuthUser> fetchCurrentUser(String accessToken) async {
    requestedMeToken = accessToken;
    return userToReturn!;
  }

  @override
  Future<String?> getPendingOAuthState() async => pendingState;

  @override
  Future<AuthSession?> getStoredSession() async => storedSession;

  @override
  Future<void> savePendingOAuthState(String? state) async {
    pendingState = state;
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    savedSession = session;
    storedSession = session;
  }
}

class _FakeAuthLauncher implements AuthLauncher {
  Uri? launchedUri;

  @override
  Future<void> launch(Uri uri) async {
    launchedUri = uri;
  }
}
