import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gal/gal.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/core/services/download_local_datasource.dart';
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

typedef TrackPhotoDownload = Future<Either<Failure, void>> Function(
    String photoId);
typedef RequestNotificationPermissions = Future<bool> Function();

enum DownloadStatus {
  idle,
  downloading,
  saving,
  completed,
  failed,
}

enum DownloadTaskStatus {
  downloading,
  completed,
  failed,
}

class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.photo,
    required this.title,
    required this.subtitle,
    required this.url,
    required this.progress,
    required this.receivedBytes,
    required this.totalBytes,
    required this.status,
  });

  final String id;
  final Photo photo;
  final String title;
  final String subtitle;
  final String url;
  final double progress;
  final int receivedBytes;
  final int totalBytes;
  final DownloadTaskStatus status;

  DownloadTask copyWith({
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    DownloadTaskStatus? status,
  }) {
    return DownloadTask(
      id: id,
      photo: photo,
      title: title,
      subtitle: subtitle,
      url: url,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'photo': photo.toJson(),
        'title': title,
        'subtitle': subtitle,
        'url': url,
        'progress': progress,
        'received_bytes': receivedBytes,
        'total_bytes': totalBytes,
        'status': status.name,
      };

  factory DownloadTask.fromJson(Map<String, dynamic> json) => DownloadTask(
        id: json['id'] as String,
        photo: Photo.fromJson(json['photo'] as Map<String, dynamic>),
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        url: json['url'] as String,
        progress: (json['progress'] as num).toDouble(),
        receivedBytes: (json['received_bytes'] as num).toInt(),
        totalBytes: (json['total_bytes'] as num).toInt(),
        status: DownloadTaskStatus.values.firstWhere(
          (s) => s.name == json['status'],
        ),
      );
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
    DownloadLocalDataSource? localDataSource,
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
        _saveImageBytes = saveImageBytes,
        _localDataSource = localDataSource ?? _NoopDownloadLocalDataSource();

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
  final DownloadLocalDataSource _localDataSource;

  final List<DownloadTask> _tasks = <DownloadTask>[];
  DownloadProgress _state = DownloadProgress.initial;
  bool _tasksLoaded = false;
  bool _isDownloading = false;
  bool _channelCreated = false;
  bool _disposed = false;
  bool _notificationsEnabled = false;

  CancelToken? _cancelToken;

  static const String _channelId = 'download_channel';
  static const int _notificationId = 1000;

  DownloadProgress get state => _state;
  bool get isDownloading => _isDownloading;
  List<DownloadTask> get tasks {
    _ensureTasksLoaded();
    return List<DownloadTask>.unmodifiable(_tasks);
  }

  void cancel() {
    _cancelToken?.cancel('Download cancelled by user');
    _cancelToken = null;
  }

  void _ensureTasksLoaded() {
    if (_tasksLoaded) return;
    _tasksLoaded = true;
    _localDataSource.loadTasks().then((saved) {
      if (saved.isNotEmpty) {
        var shouldPersist = false;
        final restored = saved.map((task) {
          if (task.status == DownloadTaskStatus.downloading) {
            shouldPersist = true;
            return task.copyWith(status: DownloadTaskStatus.failed);
          }
          return task;
        }).toList();
        _tasks.addAll(restored);
        if (shouldPersist) {
          _persistTasks();
        }
        _safeNotify();
      }
    });
  }

  Future<void> _persistTasks() {
    return _localDataSource.saveTasks(List<DownloadTask>.from(_tasks));
  }

  Future<void> download(String url, Photo photo) async {
    return _download(url, photo);
  }

  Future<void> _download(
    String url,
    Photo photo, {
    String? existingTaskId,
  }) async {
    if (_isDownloading) return;
    _ensureTasksLoaded();

    _isDownloading = true;
    _cancelToken = CancelToken();
    final taskId = existingTaskId ??
        '${photo.id}-${DateTime.now().microsecondsSinceEpoch}';
    if (existingTaskId == null) {
      _tasks.insert(
        0,
        DownloadTask(
          id: taskId,
          photo: photo,
          title: photo.description ?? photo.altDescription ?? photo.id,
          subtitle: _variantLabelForUrl(photo, url),
          url: url,
          progress: 0,
          receivedBytes: 0,
          totalBytes: 0,
          status: DownloadTaskStatus.downloading,
        ),
      );
    } else {
      _replaceTask(
        taskId,
        DownloadTask(
          id: taskId,
          photo: photo,
          title: photo.description ?? photo.altDescription ?? photo.id,
          subtitle: _variantLabelForUrl(photo, url),
          url: url,
          progress: 0,
          receivedBytes: 0,
          totalBytes: 0,
          status: DownloadTaskStatus.downloading,
        ),
      );
    }
    _persistTasks();
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
          _updateTask(
            taskId,
            progress: progress.clamp(0.0, 1.0),
            receivedBytes: received,
            totalBytes: total > 0 ? total : 0,
            status: DownloadTaskStatus.downloading,
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

      _updateTask(
        taskId,
        progress: 1.0,
        receivedBytes: bytes.length,
        totalBytes: bytes.length,
        status: DownloadTaskStatus.completed,
      );
      _persistTasks();
      _setState(
        _state.copyWith(
          progress: 1.0,
          statusText: 'Saved to gallery',
          status: DownloadStatus.completed,
        ),
      );
    } catch (e) {
      if (_isCancellation(e)) {
        _removeTask(taskId);
        await _persistTasks();
        if (_notificationsEnabled) {
          await _notifications.cancel(_notificationId);
        }
        _setState(DownloadProgress.initial);
        return;
      }

      if (_notificationsEnabled) {
        await _showFailureNotification(_humanizeError(e));
      }
      _setState(
        DownloadProgress(
          progress: 0.0,
          statusText: 'Download failed: ${_humanizeError(e)}',
          receivedBytes: 0,
          totalBytes: 0,
          status: DownloadStatus.failed,
        ),
      );
      _updateTask(
        taskId,
        progress: 0.0,
        status: DownloadTaskStatus.failed,
      );
      _persistTasks();
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

  void removeTask(String id) {
    _removeTask(id);
    _persistTasks();
  }

  void clearCompleted() {
    _removeTasksWhere((task) => task.status == DownloadTaskStatus.completed);
  }

  void clearFailed() {
    _removeTasksWhere((task) => task.status == DownloadTaskStatus.failed);
  }

  Future<void> retryTask(DownloadTask task) {
    return _download(task.url, task.photo, existingTaskId: task.id);
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
    if (error is DioException) {
      if (error.type == DioExceptionType.cancel) return 'cancelled';
      return '${error.type}${error.message != null ? ': ${error.message}' : ''}';
    }
    return error.toString();
  }

  void _setState(DownloadProgress value) {
    _state = value;
    _safeNotify();
  }

  void _updateTask(
    String id, {
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    DownloadTaskStatus? status,
  }) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return;

    _tasks[index] = _tasks[index].copyWith(
      progress: progress,
      receivedBytes: receivedBytes,
      totalBytes: totalBytes,
      status: status,
    );
    _safeNotify();
  }

  void _removeTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    _safeNotify();
  }

  void _removeTasksWhere(bool Function(DownloadTask task) predicate) {
    _tasks.removeWhere(predicate);
    _persistTasks();
    _safeNotify();
  }

  void _replaceTask(String id, DownloadTask next) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) {
      _tasks.insert(0, next);
    } else {
      _tasks[index] = next;
    }
    _safeNotify();
  }

  bool _isCancellation(Object error) {
    return error is DioException && error.type == DioExceptionType.cancel;
  }

  String _variantLabelForUrl(Photo photo, String url) {
    if (url == photo.urlRaw) return 'Raw';
    if (url == photo.urlFull) return 'Full';
    if (url == photo.urlRegular) return 'Regular';
    if (url == photo.urlSmall) return 'Small';
    if (url == photo.urlThumb) return 'Thumb';
    return 'Download';
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

class _NoopDownloadLocalDataSource implements DownloadLocalDataSource {
  @override
  Future<List<DownloadTask>> loadTasks() async => [];

  @override
  Future<void> saveTasks(List<DownloadTask> tasks) async {}

  @override
  Future<void> clearTasks() async {}
}
