import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gal/gal.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';

typedef DownloadBytes = Future<Uint8List> Function({
  required String url,
  required void Function(int received, int total) onProgress,
  required CancelToken cancelToken,
});

typedef SaveImageBytes = Future<void> Function({
  required Uint8List bytes,
  required String name,
});

typedef TrackPhotoDownload = Future<Either<Failure, void>> Function(String photoId);
typedef RequestNotificationPermissions = Future<bool> Function();

enum DownloadStatus {
  idle,
  downloading,
  saving,
  completed,
  failed,
}

class DownloadProgress {
  const DownloadProgress({
    required this.progress,
    required this.statusText,
    required this.receivedBytes,
    required this.totalBytes,
    required this.status,
  });

  final double progress;
  final String statusText;
  final int receivedBytes;
  final int totalBytes;
  final DownloadStatus status;

  bool get isIdle => status == DownloadStatus.idle;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isSaving => status == DownloadStatus.saving;
  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;

  static const DownloadProgress initial = DownloadProgress(
    progress: 0.0,
    statusText: '',
    receivedBytes: 0,
    totalBytes: 0,
    status: DownloadStatus.idle,
  );

  DownloadProgress copyWith({
    double? progress,
    String? statusText,
    int? receivedBytes,
    int? totalBytes,
    DownloadStatus? status,
  }) {
    return DownloadProgress(
      progress: progress ?? this.progress,
      statusText: statusText ?? this.statusText,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
    );
  }
}

class DownloadNotifier extends ChangeNotifier {
  DownloadNotifier({
    required FlutterLocalNotificationsPlugin notifications,
    required TrackPhotoDownload trackDownload,
    RequestNotificationPermissions? requestNotificationPermissions,
    DownloadBytes? downloadBytes,
    SaveImageBytes? saveImageBytes,
    Duration successResetDelay = const Duration(seconds: 2),
    Dio? dio,
  })  : _notifications = notifications,
        _trackDownload = trackDownload,
        _requestNotificationPermissions =
            requestNotificationPermissions ?? _defaultRequestPermissions,
        _successResetDelay = successResetDelay,
        _ownsDio = dio == null,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
              ),
            ),
        _downloadBytes = downloadBytes,
        _saveImageBytes = saveImageBytes;

  factory DownloadNotifier.noop() {
    return DownloadNotifier(
      notifications: FlutterLocalNotificationsPlugin(),
      trackDownload: (_) async => const Right(null),
      requestNotificationPermissions: () async => false,
      downloadBytes: ({
        required url,
        required onProgress,
        required cancelToken,
      }) async {
        return Uint8List(0);
      },
      saveImageBytes: ({required bytes, required name}) async {},
      successResetDelay: Duration.zero,
    );
  }

  final FlutterLocalNotificationsPlugin _notifications;
  final Dio _dio;
  final bool _ownsDio;
  final TrackPhotoDownload _trackDownload;
  final RequestNotificationPermissions _requestNotificationPermissions;
  final DownloadBytes? _downloadBytes;
  final SaveImageBytes? _saveImageBytes;
  final Duration _successResetDelay;

  DownloadProgress _state = DownloadProgress.initial;
  bool _isDownloading = false;
  bool _channelCreated = false;
  bool _disposed = false;
  bool _notificationsEnabled = false;

  CancelToken? _cancelToken;

  static const String _channelId = 'download_channel';
  static const int _notificationId = 1000;

  DownloadProgress get state => _state;
  bool get isDownloading => _isDownloading;

  void cancel() {
    _cancelToken?.cancel('Download cancelled by user');
    _cancelToken = null;
  }

  Future<void> download(String url, Photo photo) async {
    if (_isDownloading) return;

    _isDownloading = true;
    _cancelToken = CancelToken();
    _setState(
      const DownloadProgress(
        progress: 0.0,
        statusText: 'Preparing download...',
        receivedBytes: 0,
        totalBytes: 0,
        status: DownloadStatus.downloading,
      ),
    );

    try {
      await _attemptTrackDownload(photo.id);
      await _ensureNotificationsReady();

      if (_notificationsEnabled) {
        await _showProgressNotification(0, 'Starting...');
      }

      final bytes = await (_downloadBytes ?? _downloadWithDio)(
        url: url,
        cancelToken: _cancelToken!,
        onProgress: (received, total) {
          final progress = total > 0 ? received / total : 0.0;
          _setState(
            DownloadProgress(
              progress: progress.clamp(0.0, 1.0),
              statusText: 'Downloading...',
              receivedBytes: received,
              totalBytes: total > 0 ? total : 0,
              status: DownloadStatus.downloading,
            ),
          );

          if (_notificationsEnabled && total > 0) {
            _showProgressNotification(
              (progress * 100).round(),
              'Downloading: ${(progress * 100).round()}%',
            );
          }
        },
      );

      _setState(
        _state.copyWith(
          progress: 1.0,
          statusText: 'Saving to gallery...',
          status: DownloadStatus.saving,
        ),
      );

      if (_notificationsEnabled) {
        await _showProgressNotification(100, 'Saving to gallery...');
      }

      await (_saveImageBytes ?? _defaultSaveImageBytes)(
        bytes: bytes,
        name: 'musea_${photo.id}',
      );

      if (_notificationsEnabled) {
        await _showSuccessNotification();
      }

      _setState(
        _state.copyWith(
          progress: 1.0,
          statusText: 'Saved to gallery',
          status: DownloadStatus.completed,
        ),
      );

      await Future.delayed(_successResetDelay);
      reset();
    } catch (e) {
      if (_notificationsEnabled) {
        await _showFailureNotification(_humanizeError(e));
      }
      _setState(
        const DownloadProgress(
          progress: 0.0,
          statusText: 'Download failed',
          receivedBytes: 0,
          totalBytes: 0,
          status: DownloadStatus.failed,
        ),
      );
    } finally {
      _cancelToken = null;
      _isDownloading = false;
    }
  }

  void reset() {
    _state = DownloadProgress.initial;
    _isDownloading = false;
    _safeNotify();
  }

  Future<void> _attemptTrackDownload(String photoId) async {
    try {
      await _trackDownload(photoId);
    } catch (_) {
      // Keep the user flow working even if analytics/download tracking fails.
    }
  }

  Future<void> _ensureNotificationsReady() async {
    final enabled = await _requestNotificationPermissions();
    _notificationsEnabled = enabled;

    if (!enabled || _channelCreated) return;

    await _createNotificationChannel();
    _channelCreated = true;
  }

  Future<Uint8List> _downloadWithDio({
    required String url,
    required void Function(int received, int total) onProgress,
    required CancelToken cancelToken,
  }) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
      cancelToken: cancelToken,
      onReceiveProgress: onProgress,
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Empty response data');
    }

    return Uint8List.fromList(data);
  }

  Future<void> _defaultSaveImageBytes({
    required Uint8List bytes,
    required String name,
  }) {
    return Gal.putImageBytes(bytes, name: name);
  }

  static Future<bool> _defaultRequestPermissions() async {
    try {
      final android = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final darwin = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      final androidGranted =
          await android?.requestNotificationsPermission() ?? false;
      final iosGranted = await darwin?.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          ) ??
          false;

      return android != null ? androidGranted : iosGranted;
    } catch (_) {
      return false;
    }
  }

  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      'Download Progress',
      description: 'Shows download progress for image downloads',
      importance: Importance.low,
      enableVibration: false,
      playSound: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _showProgressNotification(int progress, String text) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        'Download Progress',
        channelDescription: 'Shows download progress for image downloads',
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: 100,
        progress: progress,
        onlyAlertOnce: true,
        ongoing: true,
        autoCancel: false,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );
      await _notifications.show(
        _notificationId,
        'Downloading Image',
        text,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (_) {
      // Notifications are a side effect; keep download flow alive.
    }
  }

  Future<void> _showSuccessNotification() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        'Download Progress',
        channelDescription: 'Shows download progress for image downloads',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: false,
        autoCancel: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      );
      await _notifications.show(
        _notificationId,
        'Download Complete',
        'Image saved to gallery',
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (_) {}
  }

  Future<void> _showFailureNotification(String error) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        'Download Progress',
        channelDescription: 'Shows download progress for image downloads',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        ongoing: false,
        autoCancel: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      );
      await _notifications.show(
        _notificationId,
        'Download Failed',
        error,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (_) {}
  }

  String _humanizeError(Object error) {
    if (error is DioException && error.type == DioExceptionType.cancel) {
      return 'Download cancelled';
    }
    return 'Unable to save image';
  }

  void _setState(DownloadProgress value) {
    _state = value;
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelToken?.cancel();
    if (_ownsDio) {
      _dio.close();
    }
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
