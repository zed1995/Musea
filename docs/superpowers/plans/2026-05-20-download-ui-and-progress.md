# Download UI + Progress Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the download sheet to match the prototype (radio buttons + resolution labels + Cancel/Download actions) and add download progress indication (in-app progress bar + Android notification via `flutter_local_notifications`).

**Architecture:** Create a `DownloadNotifier` (ChangeNotifier) to manage download state and notification updates. Rewrite `DownloadSheet` in two views (selection → progress). The `DownloadNotifier` encapsulates Dio download + `Gal.putImageBytes()` + notification updates.

**Tech Stack:** Flutter, Riverpod, Dio, `gal: ^2.3.0`, `flutter_local_notifications`

---

### Task 1: Add dependencies and permission

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add `flutter_local_notifications`**

In `pubspec.yaml`, add after the `gal` line (line 46):

```yaml
  flutter_local_notifications: ^17.2.1+2
```

- [ ] **Step 2: Add Android notification permission**

In `android/app/src/main/AndroidManifest.xml`, add before the `<application>` tag:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

Also add inside `<application>`:

```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
```

- [ ] **Step 3: Run `flutter pub get`**

Run: `cd /Users/zed/Codes/Musea && flutter pub get`
Expected: Packages resolved successfully

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml
git commit -m "feat: add flutter_local_notifications dependency and Android permissions"
```

---

### Task 2: Initialize notification plugin in main.dart

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Add initialization code**

Replace the content of `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:musea/app.dart';

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize local notifications
  await initNotifications();

  runApp(
    const ProviderScope(
      child: MuseaApp(),
    ),
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/main.dart
git commit -m "feat: initialize flutter_local_notifications on app startup"
```

---

### Task 3: Create DownloadNotifier service

**Files:**
- Create: `lib/core/services/download_notifier.dart`

- [ ] **Step 1: Create the notifier**

`lib/core/services/download_notifier.dart`:

```dart
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gal/gal.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';

class DownloadProgress {
  final double progress; // 0.0 - 1.0
  final String statusText;

  const DownloadProgress({
    required this.progress,
    required this.statusText,
  });

  static const DownloadProgress initial = DownloadProgress(
    progress: 0.0,
    statusText: '',
  );
}

class DownloadNotifier extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _notifications;
  final Dio _dio;

  DownloadProgress _state = DownloadProgress.initial;
  bool _isDownloading = false;

  DownloadNotifier({
    required FlutterLocalNotificationsPlugin notifications,
    Dio? dio,
  })  : _notifications = notifications,
        _dio = dio ?? Dio(BaseOptions());

  DownloadProgress get state => _state;
  bool get isDownloading => _isDownloading;

  static const String _channelId = 'download_channel';
  static const int _notificationId = 1000;

  Future<void> download(String url, Photo photo) async {
    if (_isDownloading) return;
    _isDownloading = true;
    _state = const DownloadProgress(progress: 0.0, statusText: 'Downloading...');
    notifyListeners();

    try {
      // Create or update notification channel
      await _createNotificationChannel();

      // Show initial notification
      await _showProgressNotification(0, 'Starting...');

      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total == -1) return;
          final progress = received / total;
          _state = DownloadProgress(
            progress: progress,
            statusText: 'Downloading...',
          );
          notifyListeners();

          // Update notification
          _showProgressNotification(
            (progress * 100).toInt(),
            'Downloading: ${(progress * 100).toInt()}%',
          );
        },
      );

      if (response.data == null) {
        throw Exception('Empty response data');
      }

      _state = DownloadProgress(
        progress: 1.0,
        statusText: 'Saving to gallery...',
      );
      notifyListeners();
      await _showProgressNotification(100, 'Saving to gallery...');

      // Save to gallery
      await Gal.putImageBytes(
        Uint8List.fromList(response.data!),
        name: 'musea_${photo.id}',
      );

      // Success notification
      await _showSuccessNotification();

      _state = const DownloadProgress(
        progress: 1.0,
        statusText: 'Saved to gallery',
      );
      notifyListeners();

      // Auto-reset after a moment
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      // Show failure notification
      await _showFailureNotification(e.toString());
      _state = DownloadProgress(
        progress: 0.0,
        statusText: 'Download failed: $e',
      );
      notifyListeners();
    } finally {
      _isDownloading = false;
    }
  }

  void reset() {
    _state = DownloadProgress.initial;
    _isDownloading = false;
    notifyListeners();
  }

  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      'Download Progress',
      description: 'Shows download progress for image downloads',
      importance: Importance.low,
      priority: Priority.low,
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
      // Silently handle notification errors
    }
  }

  Future<void> _showSuccessNotification() async {
    try {
      final androidDetails = const AndroidNotificationDetails(
        _channelId,
        'Download Progress',
        channelDescription: 'Shows download progress for image downloads',
        importance: Importance.low,
        priority: Priority.low,
        showProgress: false,
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
        NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (_) {
      // Silently handle notification errors
    }
  }

  Future<void> _showFailureNotification(String error) async {
    try {
      final androidDetails = const AndroidNotificationDetails(
        _channelId,
        'Download Progress',
        channelDescription: 'Shows download progress for image downloads',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showProgress: false,
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
        NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (_) {
      // Silently handle notification errors
    }
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/services/download_notifier.dart
git commit -m "feat: create DownloadNotifier with progress tracking and notification support"
```

---

### Task 4: Create notification provider

**Files:**
- Create: `lib/core/services/providers.dart`

- [ ] **Step 1: Create providers for the services**

`lib/core/services/providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/services/download_notifier.dart';
import 'package:musea/main.dart';

final downloadNotifierProvider = ChangeNotifierProvider<DownloadNotifier>((ref) {
  return DownloadNotifier(
    notifications: flutterLocalNotificationsPlugin,
  );
});
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/services/providers.dart
git commit -m "feat: add Riverpod provider for DownloadNotifier"
```

---

### Task 5: Rewrite DownloadSheet with new UI

**Files:**
- Rewrite: `lib/features/photo_detail/presentation/widgets/download_sheet.dart`

- [ ] **Step 1: Replace the entire file**

`lib/features/photo_detail/presentation/widgets/download_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/core/services/download_notifier.dart';
import 'package:musea/core/services/providers.dart';

class DownloadOption {
  final String label;
  final String url;
  final String resolution;

  const DownloadOption({
    required this.label,
    required this.url,
    required this.resolution,
  });
}

class DownloadSheet extends ConsumerStatefulWidget {
  const DownloadSheet({super.key, required this.photo});

  final Photo photo;

  static Future<DownloadOption?> show(BuildContext context, Photo photo) {
    return showModalBottomSheet<DownloadOption>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DownloadSheet(photo: photo),
    );
  }

  @override
  ConsumerState<DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends ConsumerState<DownloadSheet> {
  int _selectedIndex = 0;
  bool _startedDownload = false;

  List<DownloadOption> get _options => [
        DownloadOption(
          label: 'Raw',
          url: widget.photo.urlRaw,
          resolution: _resolution(widget.photo.width, widget.photo.height),
        ),
        DownloadOption(
          label: 'Full',
          url: widget.photo.urlFull,
          resolution: _resolution(
            _closestSide(widget.photo.width, 5760),
            _closestSide(widget.photo.height, 5760),
          ),
        ),
        DownloadOption(
          label: 'Regular',
          url: widget.photo.urlRegular,
          resolution: _resolution(
            _closestSide(widget.photo.width, 1080),
            _closestSide(widget.photo.height, 1080),
          ),
        ),
        DownloadOption(
          label: 'Small',
          url: widget.photo.urlSmall,
          resolution: _resolution(
            _closestSide(widget.photo.width, 400),
            _closestSide(widget.photo.height, 400),
          ),
        ),
        DownloadOption(
          label: 'Thumb',
          url: widget.photo.urlThumb,
          resolution: _resolution(
            _closestSide(widget.photo.width, 200),
            _closestSide(widget.photo.height, 200),
          ),
        ),
      ];

  String _resolution(int w, int h) => '${w}×${h}';

  int _closestSide(int original, int max) {
    if (original <= max) return original;
    // Maintain aspect ratio: scale the longer side to max
    if (widget.photo.width >= widget.photo.height) {
      return (widget.photo.height * max / widget.photo.width).round();
    }
    return (widget.photo.width * max / widget.photo.height).round();
  }

  @override
  Widget build(BuildContext context) {
    final downloadNotifier = ref.watch(downloadNotifierProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: _startedDownload
            ? _buildProgressView(downloadNotifier)
            : _buildSelectionView(downloadNotifier),
      ),
    );
  }

  Widget _buildSelectionView(DownloadNotifier notifier) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose Size', style: AppTextStyles.heading3),
        const SizedBox(height: 20),
        ..._options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = _selectedIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected ? const Color(0xFFF5F5F5) : Colors.transparent,
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.gray300,
                        width: isSelected ? 2 : 1.5,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.gray900 : AppColors.gray700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    option.resolution,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFA1A1AA),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: const Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final option = _options[_selectedIndex];
                  setState(() => _startedDownload = true);
                  notifier.download(option.url, widget.photo);
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.primary,
                  ),
                  child: const Center(
                    child: Text(
                      'Download',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressView(DownloadNotifier notifier) {
    final progress = notifier.state.progress;
    final statusText = notifier.state.statusText;
    final isComplete = progress >= 1.0 && statusText == 'Saved to gallery';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Downloading', style: AppTextStyles.heading3),
        const SizedBox(height: 32),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: isComplete ? 1.0 : (progress > 0 ? progress : null),
                strokeWidth: 6,
                color: AppColors.primary,
                backgroundColor: AppColors.gray200,
              ),
            ),
            Text(
              isComplete ? '✓' : '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: isComplete ? 28 : 16,
                fontWeight: FontWeight.w700,
                color: isComplete ? const Color(0xFF22C55E) : AppColors.gray900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          statusText,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.gray600,
          ),
        ),
        if (!isComplete && progress > 0) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.gray200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () {
            if (isComplete) {
              Navigator.of(context).pop();
            } else {
              // "Download in background" - close sheet, download continues
              Navigator.of(context).pop();
            }
          },
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Center(
              child: Text(
                isComplete ? 'Done' : 'Download in Background',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/photo_detail/presentation/widgets/download_sheet.dart
git commit -m "feat: redesign DownloadSheet with radio buttons, resolution labels, and progress view"
```

---

### Task 6: Update photo_detail_page.dart

**Files:**
- Modify: `lib/features/photo_detail/presentation/pages/photo_detail_page.dart`

- [ ] **Step 1: Remove inline download logic (now handled by DownloadNotifier)**

The `_triggerDownload` method in `PhotoDetailPage` currently handles Dio download + `Gal.putImageBytes()`. Now that `DownloadNotifier` handles this, simplify the page to just open `DownloadSheet` and remove `_triggerDownload`.

Replace the `PhotoDetailPage` class in `lib/features/photo_detail/presentation/pages/photo_detail_page.dart`:

```dart
class PhotoDetailPage extends ConsumerWidget {
  const PhotoDetailPage({super.key, required this.photoId});

  final String photoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoAsync = ref.watch(photoDetailProvider(photoId));

    return photoAsync.when(
      data: (photo) => _PhotoDetailContent(
        photo: photo,
        onDownload: (url) {
          // Download sheet handles everything now via DownloadNotifier
        },
      ),
      loading: () => const Scaffold(
        body: Center(child: LoadingIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(photoDetailProvider(photoId)),
        ),
      ),
    );
  }
}
```

And remove the `import 'dart:typed_data'`, `import 'package:dio/dio.dart'`, `import 'package:gal/gal.dart'` lines from the imports at the top (since they were only used by `_triggerDownload`).

Also update the `onDownload` callback in `_PhotoDetailContent` — it currently takes a `String url` parameter used by `_triggerDownload`. Since the download sheet manages everything, simplify this. The button just opens the sheet:

In `_PhotoDetailContent.build`, replace the download button callback:

```dart
_DownloadButton(
  onTap: () async {
    final option = await DownloadSheet.show(context, photo);
    // The sheet handles download internally via DownloadNotifier
    // option is only returned if user closes without downloading
  },
),
```

Remove the `import 'dart:typed_data';`, `import 'package:dio/dio.dart';`, `import 'package:gal/gal.dart';` since they're no longer needed.

Remove the `_triggerDownload` method entirely (lines 45-80).

- [ ] **Step 2: Commit**

```bash
git add lib/features/photo_detail/presentation/pages/photo_detail_page.dart
git commit -m "refactor: remove inline download logic, delegate to DownloadNotifier"
```

---

### Self-Review

**Spec coverage:**
- Radio-button size selection with resolution labels → Task 5
- Cancel/Download action buttons → Task 5
- Progress view with CircularProgressIndicator + LinearProgressIndicator → Task 5
- In-app progress bar → Task 5 (progress view)
- Android notification with progress → Task 3 (DownloadNotifier)
- iOS notification on completion → Task 3 (DarwinNotificationDetails)
- Resolution display from Photo.width/height → Task 5 (_resolution helper)

**Placeholder scan:** No placeholders, all code is complete.

**Type consistency:**
- `DownloadNotifier.download(String url, Photo photo)` → matches `Dio.get<List<int>>(url)` and `Gal.putImageBytes(Uint8List, name:)`
- `DownloadSheet.show(context, photo)` returns `DownloadOption?` → same API as before
- `DownloadOption` fields: `label`, `url`, `resolution` → used in selection view
