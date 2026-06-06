import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/core/services/download_notifier.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/repositories/photo_repository.dart';

class MockPhotoRepository extends Mock implements PhotoRepository {}

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

void main() {
  group('DownloadNotifier', () {
    late MockPhotoRepository repository;

    setUp(() {
      repository = MockPhotoRepository();
      when(() => repository.getPhotos(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'))).thenThrow(UnimplementedError());
      when(() => repository.getPhotoById(any()))
          .thenThrow(UnimplementedError());
      when(() => repository.getRandomPhoto()).thenThrow(UnimplementedError());
      when(
        () => repository.searchPhotos(
          any(),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
          orderBy: any(named: 'orderBy'),
          color: any(named: 'color'),
          orientation: any(named: 'orientation'),
          contentFilter: any(named: 'contentFilter'),
        ),
      ).thenThrow(UnimplementedError());
      when(() => repository.getTopics(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'))).thenThrow(UnimplementedError());
      when(
        () => repository.getTopicPhotos(
          any(),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenThrow(UnimplementedError());
    });

    test('tracks download before saving image bytes', () async {
      final saved = <({Uint8List bytes, String name})>[];
      when(() => repository.trackDownload('photo-1'))
          .thenAnswer((_) async => const Right(null));

      final notifier = DownloadNotifier(
        notifications: FlutterLocalNotificationsPlugin(),
        trackDownload: repository.trackDownload,
        requestNotificationPermissions: () async => false,
        downloadBytes: ({
          required url,
          required onProgress,
          required cancelToken,
        }) async {
          onProgress(3, 3);
          return Uint8List.fromList([1, 2, 3]);
        },
        saveImageBytes: ({required bytes, required name}) async {
          saved.add((bytes: bytes, name: name));
        },
        successResetDelay: Duration.zero,
      );

      await notifier.download('https://example.com/regular.jpg', buildPhoto());

      verify(() => repository.trackDownload('photo-1')).called(1);
      expect(saved, hasLength(1));
      expect(saved.single.name, 'musea_photo-1');
    });

    test('continues download when trackDownload fails', () async {
      var saved = false;
      when(() => repository.trackDownload('photo-1')).thenAnswer(
        (_) async => const Left(Failure.network(message: 'offline')),
      );

      final notifier = DownloadNotifier(
        notifications: FlutterLocalNotificationsPlugin(),
        trackDownload: repository.trackDownload,
        requestNotificationPermissions: () async => false,
        downloadBytes: ({
          required url,
          required onProgress,
          required cancelToken,
        }) async {
          return Uint8List.fromList([7, 8, 9]);
        },
        saveImageBytes: ({required bytes, required name}) async {
          saved = true;
        },
        successResetDelay: Duration.zero,
      );

      await notifier.download('https://example.com/regular.jpg', buildPhoto());

      expect(saved, isTrue);
      expect(notifier.state.statusText, isEmpty);
    });

    test('adds completed task to task list after a successful download',
        () async {
      when(() => repository.trackDownload('photo-1'))
          .thenAnswer((_) async => const Right(null));

      final notifier = DownloadNotifier(
        notifications: FlutterLocalNotificationsPlugin(),
        trackDownload: repository.trackDownload,
        requestNotificationPermissions: () async => false,
        downloadBytes: ({
          required url,
          required onProgress,
          required cancelToken,
        }) async {
          onProgress(4, 8);
          onProgress(8, 8);
          return Uint8List.fromList([1, 2, 3]);
        },
        saveImageBytes: ({required bytes, required name}) async {},
        successResetDelay: Duration.zero,
      );

      await notifier.download('https://example.com/regular.jpg', buildPhoto());

      expect(notifier.tasks, hasLength(1));
      expect(notifier.tasks.single.status, DownloadTaskStatus.completed);
      expect(notifier.tasks.single.title, 'Quiet light');
    });

    test('marks a failed task and keeps retry metadata available', () async {
      when(() => repository.trackDownload('photo-1'))
          .thenAnswer((_) async => const Right(null));

      final notifier = DownloadNotifier(
        notifications: FlutterLocalNotificationsPlugin(),
        trackDownload: repository.trackDownload,
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

      expect(notifier.tasks, hasLength(1));
      expect(notifier.tasks.single.status, DownloadTaskStatus.failed);
      expect(
        notifier.tasks.single.url,
        'https://example.com/regular.jpg',
      );
      expect(notifier.tasks.single.photo.id, 'photo-1');
    });
  });
}
