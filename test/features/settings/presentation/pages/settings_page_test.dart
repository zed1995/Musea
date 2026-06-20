import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/core/services/download_notifier.dart';
import 'package:musea/core/services/download_local_datasource.dart';
import 'package:musea/core/services/providers.dart';
import 'package:musea/features/auth/domain/entities/auth_session.dart';
import 'package:musea/features/auth/domain/entities/auth_user.dart';
import 'package:musea/features/auth/domain/repositories/auth_repository.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
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
    themeMode: AppThemeMode.system,
  );

  @override
  Future<StoredSettings> readSettings() async => value;

  @override
  Future<void> saveSettings(StoredSettings settings) async {
    value = settings;
  }
}

class _FakeDownloadLocalDataSource implements DownloadLocalDataSource {
  _FakeDownloadLocalDataSource(this.initialTasks);

  final List<DownloadTask> initialTasks;

  @override
  Future<void> clearTasks() async {}

  @override
  Future<List<DownloadTask>> loadTasks() async => initialTasks;

  @override
  Future<void> saveTasks(List<DownloadTask> tasks) async {}
}

Photo _buildPhoto() {
  return PhotoModel.fromJson({
    'id': 'photo-1',
    'created_at': '2024-01-01T00:00:00Z',
    'width': 6000,
    'height': 4000,
    'color': '#FFFFFF',
    'description': 'Quiet light',
    'urls': {
      'raw': 'https://example.com/raw.jpg',
      'full': 'https://example.com/full.jpg',
      'regular': 'https://example.com/regular.jpg',
      'small': 'https://example.com/small.jpg',
      'thumb': 'https://example.com/thumb.jpg',
    },
    'likes': 1,
    'downloads': 1,
    'views': 1,
    'user': {
      'id': 'user-1',
      'username': 'paula',
      'name': 'Paula Poeira',
      'profile_image': {
        'small': 'https://example.com/small-profile.jpg',
        'medium': 'https://example.com/medium-profile.jpg',
        'large': 'https://example.com/large-profile.jpg',
      },
      'total_photos': 1,
      'total_likes': 1,
      'total_collections': 1,
    },
  }).toEntity();
}

void main() {
  Widget buildApp({
    required bool authenticated,
    List<DownloadTask> tasks = const [],
    DownloadNotifier? notifier,
  }) {
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

    final resolvedNotifier = notifier ??
        DownloadNotifier(
          notifications: FlutterLocalNotificationsPlugin(),
          trackDownload: (_) async => const Right(null),
          requestNotificationPermissions: () async => false,
          localDataSource: _FakeDownloadLocalDataSource(tasks),
        );

    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (_) => _FakeAuthController(session: session),
        ),
        settingsLocalDataSourceProvider
            .overrideWithValue(_FakeSettingsLocalDataSource()),
        appVersionProvider.overrideWith((ref) async => 'v1.0.0'),
        cacheBytesProvider.overrideWith((ref) async => 128 * 1024 * 1024),
        downloadNotifierProvider.overrideWith((ref) => resolvedNotifier),
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

  testWidgets('hides sign out button when not authenticated', (tester) async {
    await tester.pumpWidget(buildApp(authenticated: false));

    await tester.pumpAndSettle();

    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('shows active download count when downloads are in progress',
      (tester) async {
    final photo = _buildPhoto();
    final completer = Completer<Uint8List>();
    final notifier = DownloadNotifier(
      notifications: FlutterLocalNotificationsPlugin(),
      trackDownload: (_) async => const Right(null),
      requestNotificationPermissions: () async => false,
      downloadBytes: ({
        required url,
        required onProgress,
        required cancelToken,
      }) async {
        onProgress(400, 1000);
        return completer.future;
      },
      saveImageBytes: ({required bytes, required name}) async {},
      localDataSource: _FakeDownloadLocalDataSource(const []),
    );
    final downloadFuture = notifier.download(photo.urlRegular, photo);
    await tester.pumpWidget(
      buildApp(
        authenticated: false,
        notifier: notifier,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1 task'), findsOneWidget);

    notifier.cancel();
    completer.completeError(
      DioException(
        requestOptions: RequestOptions(path: photo.urlRegular),
        type: DioExceptionType.cancel,
      ),
    );
    await downloadFuture;
  });
}
