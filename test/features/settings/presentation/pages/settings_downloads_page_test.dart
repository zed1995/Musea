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
import 'package:musea/features/discover/data/models/photo_model.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/settings/presentation/pages/settings_downloads_page.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

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
  testWidgets('renders empty state when no download tasks exist',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadNotifierProvider
              .overrideWith((ref) => DownloadNotifier.noop()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsDownloadsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No downloads yet'), findsOneWidget);
  });

  testWidgets('renders grouped download sections with progress details',
      (tester) async {
    final photo = _buildPhoto();
    final completer = Completer<Uint8List>();
    final notifier = DownloadNotifier(
      notifications: FlutterLocalNotificationsPlugin(),
      trackDownload: (_) async => const Right(null),
      requestNotificationPermissions: () async => false,
      localDataSource: _FakeDownloadLocalDataSource([
        DownloadTask(
          id: 'completed',
          photo: photo,
          title: 'Quiet light 2',
          subtitle: 'Full',
          url: photo.urlFull,
          progress: 1,
          receivedBytes: 1000,
          totalBytes: 1000,
          status: DownloadTaskStatus.completed,
        ),
        DownloadTask(
          id: 'failed',
          photo: photo,
          title: 'Quiet light 3',
          subtitle: 'Original',
          url: photo.urlRaw,
          progress: 0.2,
          receivedBytes: 200,
          totalBytes: 1000,
          status: DownloadTaskStatus.failed,
        ),
      ]),
      downloadBytes: ({
        required url,
        required onProgress,
        required cancelToken,
      }) async {
        onProgress(400, 1000);
        return completer.future;
      },
      saveImageBytes: ({required bytes, required name}) async {},
    );

    final downloadFuture = notifier.download(photo.urlRegular, photo);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadNotifierProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsDownloadsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Downloading'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.textContaining('40%'), findsOneWidget);
    expect(find.textContaining('400 B / 1000 B'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    notifier.cancel();
    completer.completeError(
      DioException(
        requestOptions: RequestOptions(path: photo.urlRegular),
        type: DioExceptionType.cancel,
      ),
    );
    await downloadFuture;
  });

  testWidgets('reveals delete action on swipe and removes only the record',
      (tester) async {
    final photo = _buildPhoto();
    final notifier = DownloadNotifier(
      notifications: FlutterLocalNotificationsPlugin(),
      trackDownload: (_) async => const Right(null),
      requestNotificationPermissions: () async => false,
      localDataSource: _FakeDownloadLocalDataSource([
        DownloadTask(
          id: 'completed',
          photo: photo,
          title: 'Quiet light',
          subtitle: 'Regular',
          url: photo.urlRegular,
          progress: 1,
          receivedBytes: 1000,
          totalBytes: 1000,
          status: DownloadTaskStatus.completed,
        ),
        DownloadTask(
          id: 'failed',
          photo: photo,
          title: 'Quiet light 2',
          subtitle: 'Original',
          url: photo.urlRaw,
          progress: 0,
          receivedBytes: 0,
          totalBytes: 1000,
          status: DownloadTaskStatus.failed,
        ),
      ]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadNotifierProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsDownloadsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Quiet light'), findsOneWidget);
    expect(find.text('Quiet light 2'), findsOneWidget);

    await tester.drag(find.text('Quiet light'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-task-completed')));
    await tester.pumpAndSettle();

    expect(find.text('Quiet light'), findsNothing);
    expect(find.text('Quiet light 2'), findsOneWidget);
    expect(find.text('Task removed'), findsOneWidget);
  });

  testWidgets('shows cleanup hint and clears completed records from app bar',
      (tester) async {
    final photo = _buildPhoto();
    final notifier = DownloadNotifier(
      notifications: FlutterLocalNotificationsPlugin(),
      trackDownload: (_) async => const Right(null),
      requestNotificationPermissions: () async => false,
      localDataSource: _FakeDownloadLocalDataSource([
        DownloadTask(
          id: 'completed',
          photo: photo,
          title: 'Quiet light',
          subtitle: 'Regular',
          url: photo.urlRegular,
          progress: 1,
          receivedBytes: 1000,
          totalBytes: 1000,
          status: DownloadTaskStatus.completed,
        ),
        DownloadTask(
          id: 'failed',
          photo: photo,
          title: 'Quiet light 2',
          subtitle: 'Original',
          url: photo.urlRaw,
          progress: 0,
          receivedBytes: 0,
          totalBytes: 1000,
          status: DownloadTaskStatus.failed,
        ),
      ]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadNotifierProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsDownloadsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text(
        'Deleting a task removes only the record here. Saved images stay in your gallery.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear Completed'));
    await tester.pumpAndSettle();

    expect(find.text('Quiet light'), findsNothing);
    expect(find.text('Quiet light 2'), findsOneWidget);
    expect(find.text('Completed tasks cleared'), findsOneWidget);
  });
}
