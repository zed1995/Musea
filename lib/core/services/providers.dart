import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/services/download_local_datasource.dart';
import 'package:musea/core/services/download_notifier.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/main.dart';

final downloadNotifierProvider = ChangeNotifierProvider<DownloadNotifier>((ref) {
  return DownloadNotifier(
    notifications: flutterLocalNotificationsPlugin,
    trackDownload: ref.read(photoRepositoryProvider).trackDownload,
    requestNotificationPermissions: requestNotificationPermissions,
    localDataSource: DownloadLocalDataSourceImpl(),
  );
});
