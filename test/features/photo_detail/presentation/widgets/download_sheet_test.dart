import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/core/services/download_notifier.dart';
import 'package:musea/core/services/providers.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/photo_detail/presentation/widgets/download_sheet.dart';
import 'package:musea/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:musea/features/settings/presentation/providers/settings_provider.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

Photo buildPhoto({
  int width = 6000,
  int height = 4000,
}) {
  return PhotoModel.fromJson({
    'id': 'photo-1',
    'created_at': '2024-01-01T00:00:00Z',
    'width': width,
    'height': height,
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

class _FakeSettingsLocalDataSource implements SettingsLocalDataSource {
  _FakeSettingsLocalDataSource(this.value);

  final StoredSettings value;

  @override
  Future<StoredSettings> readSettings() async => value;

  @override
  Future<void> saveSettings(StoredSettings settings) async {}
}

void main() {
  testWidgets(
      'DownloadSheet matches prototype selection copy and default action',
      (tester) async {
    final notifier = DownloadNotifier.noop();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadNotifierProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DownloadSheet(photo: buildPhoto()),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(
      find.text(
        'Choose the size that works best for where you want to use this photo.',
      ),
      findsOneWidget,
    );
    expect(find.text('Download Regular'), findsOneWidget);
    expect(find.text('Fast to save and easy to share.'), findsOneWidget);
    expect(
      find.text('A balanced choice for most screens and posts.'),
      findsOneWidget,
    );
  });

  testWidgets('DownloadSheet does not show estimated resolutions',
      (tester) async {
    final notifier = DownloadNotifier.noop();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadNotifierProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DownloadSheet(photo: buildPhoto(width: 6000, height: 4000)),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.textContaining('×'), findsNothing);
  });

  testWidgets('DownloadSheet stays attached to the bottom edge',
      (tester) async {
    final notifier = DownloadNotifier.noop();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadNotifierProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DownloadSheet(photo: buildPhoto()),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(SafeArea), findsNothing);
  });

  testWidgets('DownloadSheet white surface reaches screen bottom',
      (tester) async {
    final notifier = DownloadNotifier.noop();
    final photo = buildPhoto();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadNotifierProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(bottom: 34),
              viewPadding: EdgeInsets.only(bottom: 34),
            ),
            child: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: FilledButton(
                    onPressed: () => DownloadSheet.show(context, photo),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final sheetFinder = find.byWidgetPredicate((widget) {
      if (widget is! DecoratedBox) return false;
      final decoration = widget.decoration;
      return decoration is BoxDecoration &&
          decoration.color == Colors.white &&
          decoration.borderRadius ==
              const BorderRadius.vertical(top: Radius.circular(26));
    });

    expect(
      tester.getRect(sheetFinder).bottom,
      tester.getRect(find.byType(Scaffold).first).bottom,
    );
  });

  testWidgets(
      'DownloadSheet reopens on selection view after a previous successful download',
      (tester) async {
    final notifier = DownloadNotifier(
      notifications: FlutterLocalNotificationsPlugin(),
      trackDownload: (_) async => const Right(null),
      requestNotificationPermissions: () async => false,
      downloadBytes: ({
        required url,
        required onProgress,
        required cancelToken,
      }) async {
        onProgress(5, 5);
        return Uint8List.fromList([1, 2, 3, 4, 5]);
      },
      saveImageBytes: ({required bytes, required name}) async {},
      successResetDelay: Duration.zero,
    );

    await notifier.download('https://example.com/regular.jpg', buildPhoto());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadNotifierProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DownloadSheet(photo: buildPhoto()),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Download Progress'), findsNothing);
    expect(find.text('Download Regular'), findsOneWidget);
  });

  testWidgets(
      'DownloadSheet reopens on selection view after a previous failed download',
      (tester) async {
    final notifier = DownloadNotifier(
      notifications: FlutterLocalNotificationsPlugin(),
      trackDownload: (_) async => const Right(null),
      requestNotificationPermissions: () async => false,
      downloadBytes: ({
        required url,
        required onProgress,
        required cancelToken,
      }) async {
        throw Exception('offline');
      },
      saveImageBytes: ({required bytes, required name}) async {},
      successResetDelay: Duration.zero,
    );

    await notifier.download('https://example.com/regular.jpg', buildPhoto());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadNotifierProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DownloadSheet(photo: buildPhoto()),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Download Progress'), findsNothing);
    expect(find.text('Download Regular'), findsOneWidget);
  });

  testWidgets(
      'DownloadSheet blocks download on non-wifi when wifi-only setting is enabled',
      (tester) async {
    final notifier = DownloadNotifier.noop();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadNotifierProvider.overrideWith((ref) => notifier),
          settingsLocalDataSourceProvider.overrideWithValue(
            _FakeSettingsLocalDataSource(
              const StoredSettings(
                language: AppLanguage.english,
                downloadOverWifiOnly: true,
              ),
            ),
          ),
          downloadConnectionTypeProvider.overrideWith(
            (ref) => () async => DownloadConnectionType.cellular,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DownloadSheet(photo: buildPhoto()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Download Regular'));
    await tester.pumpAndSettle();

    expect(
      find.text('Turn off Wi-Fi only or connect to Wi-Fi to download.'),
      findsOneWidget,
    );
    expect(find.text('Download Progress'), findsNothing);
    expect(find.text('Download Regular'), findsOneWidget);
  });
}
