import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/core/services/download_notifier.dart';
import 'package:musea/core/services/providers.dart';
import 'package:musea/features/auth/domain/entities/auth_session.dart';
import 'package:musea/features/auth/domain/entities/auth_user.dart';
import 'package:musea/features/auth/domain/repositories/auth_repository.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:musea/features/settings/presentation/pages/settings_page.dart';
import 'package:musea/features/settings/presentation/providers/settings_provider.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession?> getStoredSession() async => null;
  @override
  Future<void> saveSession(AuthSession session) async {}
  @override
  Future<void> clearSession() async {}
  @override
  Future<String?> getPendingOAuthState() async => null;
  @override
  Future<void> savePendingOAuthState(String? state) async {}
  @override
  Uri buildAuthorizationUri({required String state}) =>
      Uri.parse('https://example.com');
  @override
  Future<OAuthToken> exchangeCodeForToken(String code) async =>
      const OAuthToken(
        accessToken: '',
        tokenType: '',
        scope: '',
        createdAt: 0,
      );
  @override
  Future<AuthUser> fetchCurrentUser() async => const AuthUser(
        id: '',
        username: '',
        displayName: '',
        profileImageMedium: '',
        totalPhotos: 0,
        totalLikes: 0,
        totalCollections: 0,
      );
}

class _FakeAuthLauncher implements AuthLauncher {
  @override
  Future<void> launch(Uri uri) async {}
}

class _FakeAuthController extends AuthController {
  _FakeAuthController({AuthSession? session})
      : super(
          repository: _FakeAuthRepository(),
          launcher: _FakeAuthLauncher(),
          now: () => DateTime(2020),
          expectedRedirectUri: Uri.parse('musea://auth/callback'),
          initialSession: session,
        );
}

class _FakeSettingsLocalDataSource implements SettingsLocalDataSource {
  StoredSettings value = const StoredSettings(
    language: AppLanguage.system,
    downloadOverWifiOnly: true,
  );

  @override
  Future<StoredSettings> readSettings() async => value;

  @override
  Future<void> saveSettings(StoredSettings settings) async {
    value = settings;
  }
}

void main() {
  Widget buildApp({required bool authenticated}) {
    final session = authenticated
        ? AuthSession(
            accessToken: 'test',
            tokenType: 'bearer',
            scope: 'public',
            createdAt: 0,
            user: const AuthUser(
              id: '1',
              username: 'test',
              displayName: 'Test',
              profileImageMedium: '',
              totalPhotos: 0,
              totalLikes: 0,
              totalCollections: 0,
            ),
            lastProfileRefreshAt: DateTime(2020),
          )
        : null;

    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (_) => _FakeAuthController(session: session),
        ),
        settingsLocalDataSourceProvider
            .overrideWithValue(_FakeSettingsLocalDataSource()),
        appVersionProvider.overrideWith((ref) async => 'v1.0.0'),
        cacheBytesProvider.overrideWith((ref) async => 128 * 1024 * 1024),
        downloadNotifierProvider
            .overrideWith((ref) => DownloadNotifier.noop()),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(),
      ),
    );
  }

  testWidgets('renders grouped settings rows and sign out button',
      (tester) async {
    await tester.pumpWidget(buildApp(authenticated: true));

    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Download over Wi-Fi only'), findsOneWidget);
    expect(find.text('Cache'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('Feedback'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Sign out'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('hides sign out button when not authenticated',
      (tester) async {
    await tester.pumpWidget(buildApp(authenticated: false));

    await tester.pumpAndSettle();

    expect(find.text('Sign out'), findsNothing);
  });
}
