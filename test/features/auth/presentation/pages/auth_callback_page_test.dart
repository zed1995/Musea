import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/features/auth/domain/entities/auth_session.dart';
import 'package:musea/features/auth/domain/entities/auth_user.dart';
import 'package:musea/features/auth/domain/repositories/auth_repository.dart';
import 'package:musea/features/auth/presentation/pages/auth_callback_page.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';

void main() {
  testWidgets('OAuth callback route handles callback location and lands on Mine',
      (tester) async {
    final repository = _FakeAuthRepository();
    repository.pendingState = 'oauth-state';
    repository.tokenToReturn = const OAuthToken(
      accessToken: 'token-123',
      tokenType: 'bearer',
      scope: 'public read_user',
      createdAt: 123456,
    );
    repository.userToReturn = const AuthUser(
      id: 'user-1',
      username: 'spaciba',
      displayName: 'Paula Poeira',
      profileImageMedium: 'https://example.com/avatar-medium.jpg',
      totalPhotos: 12,
      totalLikes: 34,
      totalCollections: 56,
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Text('Home'),
          ),
        ),
        GoRoute(
          path: '/callback',
          builder: (context, state) {
            return AuthCallbackPage(callbackUri: state.uri);
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) {
            return Consumer(
              builder: (context, ref, child) {
                final session = ref.watch(authControllerProvider).session;
                return Scaffold(
                  body: Text(session?.user.displayName ?? 'signed-out'),
                );
              },
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          authLinkServiceProvider.overrideWithValue(_FakeAuthLinkService()),
          authClockProvider.overrideWithValue(() => DateTime(2026, 5, 21, 12)),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    final appContext = tester.element(find.text('Home'));
    GoRouter.of(appContext).go(
      '/callback?code=abc123&state=oauth-state',
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Paula Poeira'), findsOneWidget);
    expect(repository.exchangedCodeCount, 1);
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
  int exchangedCodeCount = 0;

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
    exchangedCodeCount += 1;
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

class _FakeAuthLinkService implements AuthLinkService {
  @override
  Future<Uri?> getInitialLink() async => null;

  @override
  Stream<Uri> get uriStream => const Stream<Uri>.empty();
}
