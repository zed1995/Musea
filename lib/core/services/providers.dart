import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/services/download_local_datasource.dart';
import 'package:musea/core/services/download_notifier.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/main.dart';

enum DownloadConnectionType {
  wifi,
  cellular,
  other,
  none,
  unknown,
}

typedef ReadDownloadConnectionType = Future<DownloadConnectionType> Function();

final downloadNotifierProvider =
    ChangeNotifierProvider<DownloadNotifier>((ref) {
  return DownloadNotifier(
    notifications: flutterLocalNotificationsPlugin,
    trackDownload: ref.read(photoRepositoryProvider).trackDownload,
    requestNotificationPermissions: requestNotificationPermissions,
    localDataSource: DownloadLocalDataSourceImpl(),
  );
});

final downloadConnectionTypeProvider = Provider<ReadDownloadConnectionType>((
  ref,
) {
  return () async {
    try {
      final results = await Connectivity().checkConnectivity();
      return _mapDownloadConnectionType(results);
    } catch (_) {
      return DownloadConnectionType.unknown;
    }
  };
});

DownloadConnectionType _mapDownloadConnectionType(
  List<ConnectivityResult> results,
) {
  if (results.contains(ConnectivityResult.wifi)) {
    return DownloadConnectionType.wifi;
  }
  if (results.contains(ConnectivityResult.mobile)) {
    return DownloadConnectionType.cellular;
  }
  if (results.contains(ConnectivityResult.none)) {
    return DownloadConnectionType.none;
  }
  if (results.isEmpty) {
    return DownloadConnectionType.unknown;
  }
  return DownloadConnectionType.other;
}
