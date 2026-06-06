# Settings Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a dedicated settings flow reachable from Mine, with local language/download preferences, cache management, download task management, version display, GitHub feedback, and sign out.

**Architecture:** Keep settings as a dedicated `features/settings` module with a lightweight local-data architecture: Hive-backed preference storage, Riverpod providers for read/update flows, and small presentation pages that consume core services. Extend the existing `DownloadNotifier` to expose a task list/history so the downloads page can stay read-only and avoid a second parallel download state system.

**Tech Stack:** Flutter, Riverpod, GoRouter, Hive, `cached_network_image`, `flutter_cache_manager`, `package_info_plus`, `url_launcher`, existing auth/download services

---

## File Map

### Create

- `lib/features/settings/data/datasources/settings_local_datasource.dart`
- `lib/features/settings/presentation/providers/settings_provider.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/features/settings/presentation/pages/settings_language_page.dart`
- `lib/features/settings/presentation/pages/settings_downloads_page.dart`
- `lib/features/settings/presentation/widgets/settings_section.dart`
- `lib/features/settings/presentation/widgets/settings_row.dart`
- `lib/core/services/cache_summary_service.dart`
- `test/features/settings/data/datasources/settings_local_datasource_test.dart`
- `test/features/settings/presentation/pages/settings_page_test.dart`
- `test/features/settings/presentation/pages/settings_language_page_test.dart`
- `test/features/settings/presentation/pages/settings_downloads_page_test.dart`
- `test/core/services/cache_summary_service_test.dart`

### Modify

- `pubspec.yaml`
- `pubspec.lock`
- `lib/router/app_router.dart`
- `lib/core/services/download_notifier.dart`
- `lib/core/services/providers.dart`
- `lib/features/profile/presentation/pages/mine_page.dart`
- `test/core/services/download_notifier_test.dart`
- `test/router/app_router_test.dart`
- `test/features/profile/presentation/pages/mine_tab_page_test.dart`

### Responsibilities

- `settings_local_datasource.dart`: persist language + Wi-Fi-only preferences in one Hive box
- `settings_provider.dart`: expose settings state, app version, cache summary, feedback launcher, and settings mutations
- `cache_summary_service.dart`: compute/clear app-managed cache (Hive boxes + image cache)
- `download_notifier.dart`: keep current progress behavior, plus expose task list/history and retry support
- `settings_page.dart`: grouped settings hub and sign-out action
- `settings_language_page.dart`: single-choice language page
- `settings_downloads_page.dart`: grouped download task list
- `settings_section.dart` / `settings_row.dart`: compact reusable settings UI primitives

---

### Task 1: Add direct dependencies and local settings persistence

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Create: `lib/features/settings/data/datasources/settings_local_datasource.dart`
- Test: `test/features/settings/data/datasources/settings_local_datasource_test.dart`

- [ ] **Step 1: Write the failing datasource test**

Create `test/features/settings/data/datasources/settings_local_datasource_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musea/features/settings/data/datasources/settings_local_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsLocalDataSource dataSource;

  setUpAll(() async {
    Hive.init('./test/hive_test_data');
  });

  setUp(() async {
    await Hive.deleteBoxFromDisk('settings');
    dataSource = SettingsLocalDataSourceImpl();
  });

  test('reads defaults before anything is saved', () async {
    final settings = await dataSource.readSettings();

    expect(settings.language, AppLanguage.system);
    expect(settings.downloadOverWifiOnly, isTrue);
  });

  test('persists language and wifi-only preference', () async {
    await dataSource.saveSettings(
      const StoredSettings(
        language: AppLanguage.simplifiedChinese,
        downloadOverWifiOnly: false,
      ),
    );

    final settings = await dataSource.readSettings();
    expect(settings.language, AppLanguage.simplifiedChinese);
    expect(settings.downloadOverWifiOnly, isFalse);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/settings/data/datasources/settings_local_datasource_test.dart`

Expected: FAIL with file-not-found/import errors for `settings_local_datasource.dart`

- [ ] **Step 3: Add direct package dependencies**

In `pubspec.yaml`, add the two direct dependencies under `dependencies:`:

```yaml
  flutter_cache_manager: ^3.4.1
  package_info_plus: ^8.0.2
```

- [ ] **Step 4: Implement the local datasource**

Create `lib/features/settings/data/datasources/settings_local_datasource.dart`:

```dart
import 'package:hive_flutter/hive_flutter.dart';

enum AppLanguage {
  system('system'),
  english('english'),
  simplifiedChinese('zhHans');

  const AppLanguage(this.storageValue);
  final String storageValue;

  static AppLanguage fromStorage(String? raw) {
    return AppLanguage.values.firstWhere(
      (value) => value.storageValue == raw,
      orElse: () => AppLanguage.system,
    );
  }
}

class StoredSettings {
  const StoredSettings({
    required this.language,
    required this.downloadOverWifiOnly,
  });

  final AppLanguage language;
  final bool downloadOverWifiOnly;
}

abstract class SettingsLocalDataSource {
  Future<StoredSettings> readSettings();
  Future<void> saveSettings(StoredSettings settings);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  static const _boxName = 'settings';
  static const _languageKey = 'language';
  static const _wifiOnlyKey = 'download_over_wifi_only';

  Box<dynamic>? _box;

  Future<Box<dynamic>> get box async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  @override
  Future<StoredSettings> readSettings() async {
    final settingsBox = await box;
    return StoredSettings(
      language: AppLanguage.fromStorage(settingsBox.get(_languageKey) as String?),
      downloadOverWifiOnly:
          (settingsBox.get(_wifiOnlyKey) as bool?) ?? true,
    );
  }

  @override
  Future<void> saveSettings(StoredSettings settings) async {
    final settingsBox = await box;
    await settingsBox.put(_languageKey, settings.language.storageValue);
    await settingsBox.put(_wifiOnlyKey, settings.downloadOverWifiOnly);
  }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/features/settings/data/datasources/settings_local_datasource_test.dart`

Expected: PASS with 2 tests

- [ ] **Step 6: Refresh packages**

Run: `flutter pub get`

Expected: dependency resolution succeeds and `pubspec.lock` updates

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/features/settings/data/datasources/settings_local_datasource.dart test/features/settings/data/datasources/settings_local_datasource_test.dart
git commit -m "feat: add local settings persistence"
```

---

### Task 2: Add cache summary and settings providers

**Files:**
- Create: `lib/core/services/cache_summary_service.dart`
- Create: `lib/features/settings/presentation/providers/settings_provider.dart`
- Test: `test/core/services/cache_summary_service_test.dart`

- [ ] **Step 1: Write the failing cache service test**

Create `test/core/services/cache_summary_service_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musea/core/services/cache_summary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('formats bytes into compact labels', () {
    expect(CacheSummaryService.formatBytes(0), '0 B');
    expect(CacheSummaryService.formatBytes(128), '128 B');
    expect(CacheSummaryService.formatBytes(2048), '2 KB');
    expect(CacheSummaryService.formatBytes(3 * 1024 * 1024), '3 MB');
  });

  test('computes directory size recursively', () async {
    final root = await Directory.systemTemp.createTemp('cache-summary-test');
    final nested = Directory('${root.path}/nested')..createSync();
    File('${root.path}/a.bin').writeAsBytesSync(List<int>.filled(5, 1));
    File('${nested.path}/b.bin').writeAsBytesSync(List<int>.filled(7, 1));

    final bytes = await CacheSummaryService.directorySize(root);

    expect(bytes, 12);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/services/cache_summary_service_test.dart`

Expected: FAIL because `cache_summary_service.dart` does not exist

- [ ] **Step 3: Implement the cache summary service**

Create `lib/core/services/cache_summary_service.dart`:

```dart
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class CacheSummaryService {
  const CacheSummaryService();

  static const List<String> hiveBoxes = <String>[
    'photos_cache',
    'topics_cache',
  ];

  Future<int> getTotalCacheBytes() async {
    var total = 0;

    for (final boxName in hiveBoxes) {
      final box = await Hive.openBox(boxName);
      final path = box.path;
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          total += await file.length();
        }
      }
    }

    final tempDirectory = await getTemporaryDirectory();
    final imageCacheDirectory = Directory(
      '${tempDirectory.path}/${DefaultCacheManager.key}',
    );
    if (await imageCacheDirectory.exists()) {
      total += await directorySize(imageCacheDirectory);
    }

    return total;
  }

  Future<void> clearAll() async {
    for (final boxName in hiveBoxes) {
      final box = await Hive.openBox(boxName);
      await box.clear();
    }
    await DefaultCacheManager().emptyCache();
  }

  static Future<int> directorySize(Directory directory) async {
    var total = 0;
    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).round()} MB';
  }
}
```

- [ ] **Step 4: Implement settings providers**

Create `lib/features/settings/presentation/providers/settings_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:musea/core/services/cache_summary_service.dart';
import 'package:musea/features/settings/data/datasources/settings_local_datasource.dart';

class SettingsState {
  const SettingsState({
    required this.language,
    required this.downloadOverWifiOnly,
  });

  final AppLanguage language;
  final bool downloadOverWifiOnly;

  SettingsState copyWith({
    AppLanguage? language,
    bool? downloadOverWifiOnly,
  }) {
    return SettingsState(
      language: language ?? this.language,
      downloadOverWifiOnly: downloadOverWifiOnly ?? this.downloadOverWifiOnly,
    );
  }
}

final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>((ref) {
  return SettingsLocalDataSourceImpl();
});

final cacheSummaryServiceProvider = Provider<CacheSummaryService>((ref) {
  return const CacheSummaryService();
});

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'v${info.version}';
});

final cacheBytesProvider = FutureProvider<int>((ref) async {
  return ref.read(cacheSummaryServiceProvider).getTotalCacheBytes();
});

final feedbackUriProvider = Provider<Uri>((ref) {
  return Uri.parse('https://github.com/<owner>/<repo>');
});

final feedbackLauncherProvider = Provider<Future<bool> Function(Uri)>((ref) {
  return launchUrl;
});

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);

class SettingsController extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    final stored = await ref.read(settingsLocalDataSourceProvider).readSettings();
    return SettingsState(
      language: stored.language,
      downloadOverWifiOnly: stored.downloadOverWifiOnly,
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    final current = state.requireValue;
    final next = current.copyWith(language: language);
    state = AsyncData(next);
    await ref.read(settingsLocalDataSourceProvider).saveSettings(
          StoredSettings(
            language: next.language,
            downloadOverWifiOnly: next.downloadOverWifiOnly,
          ),
        );
  }

  Future<void> setDownloadOverWifiOnly(bool value) async {
    final current = state.requireValue;
    final next = current.copyWith(downloadOverWifiOnly: value);
    state = AsyncData(next);
    await ref.read(settingsLocalDataSourceProvider).saveSettings(
          StoredSettings(
            language: next.language,
            downloadOverWifiOnly: next.downloadOverWifiOnly,
          ),
        );
  }

  Future<void> clearCache() async {
    await ref.read(cacheSummaryServiceProvider).clearAll();
    ref.invalidate(cacheBytesProvider);
  }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/core/services/cache_summary_service_test.dart`

Expected: PASS with 2 tests

- [ ] **Step 6: Commit**

```bash
git add lib/core/services/cache_summary_service.dart lib/features/settings/presentation/providers/settings_provider.dart test/core/services/cache_summary_service_test.dart
git commit -m "feat: add cache summary and settings providers"
```

---

### Task 3: Extend DownloadNotifier into a task list source

**Files:**
- Modify: `lib/core/services/download_notifier.dart`
- Modify: `test/core/services/download_notifier_test.dart`
- Modify: `lib/core/services/providers.dart`

- [ ] **Step 1: Write the failing notifier test for task history**

Append to `test/core/services/download_notifier_test.dart`:

```dart
test('adds completed task to task list after a successful download', () async {
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

test('marks a failed task and allows retry metadata to remain available', () async {
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
  expect(notifier.tasks.single.url, 'https://example.com/regular.jpg');
});
```

- [ ] **Step 2: Run the notifier test to verify it fails**

Run: `flutter test test/core/services/download_notifier_test.dart`

Expected: FAIL because `tasks` / `DownloadTaskStatus` are undefined

- [ ] **Step 3: Add task models and list behavior**

Update `lib/core/services/download_notifier.dart` with these additions:

```dart
enum DownloadTaskStatus {
  downloading,
  completed,
  failed,
}

class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.photoId,
    required this.title,
    required this.subtitle,
    required this.url,
    required this.progress,
    required this.receivedBytes,
    required this.totalBytes,
    required this.status,
  });

  final String id;
  final String photoId;
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
      photoId: photoId,
      title: title,
      subtitle: subtitle,
      url: url,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
    );
  }
}
```

Add state inside `DownloadNotifier`:

```dart
  final List<DownloadTask> _tasks = <DownloadTask>[];

  List<DownloadTask> get tasks => List<DownloadTask>.unmodifiable(_tasks);
```

At the start of `download(...)`, create a task:

```dart
    final taskId = '${photo.id}-${DateTime.now().microsecondsSinceEpoch}';
    _tasks.insert(
      0,
      DownloadTask(
        id: taskId,
        photoId: photo.id,
        title: photo.description ?? photo.altDescription ?? photo.id,
        subtitle: 'Regular',
        url: url,
        progress: 0,
        receivedBytes: 0,
        totalBytes: 0,
        status: DownloadTaskStatus.downloading,
      ),
    );
    _safeNotify();
```

Add a private updater:

```dart
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
```

Inside `onProgress`, update the task:

```dart
          _updateTask(
            taskId,
            progress: progress.clamp(0.0, 1.0),
            receivedBytes: received,
            totalBytes: total > 0 ? total : 0,
            status: DownloadTaskStatus.downloading,
          );
```

After save success:

```dart
      _updateTask(
        taskId,
        progress: 1.0,
        status: DownloadTaskStatus.completed,
      );
```

Inside the catch block:

```dart
      _updateTask(
        taskId,
        progress: 0.0,
        status: DownloadTaskStatus.failed,
      );
```

Finally, add retry support:

```dart
  Future<void> retryTask(DownloadTask task, Photo photo) {
    return download(task.url, photo);
  }
```

- [ ] **Step 4: Run the notifier tests to verify they pass**

Run: `flutter test test/core/services/download_notifier_test.dart`

Expected: PASS with the old notifier coverage plus the new task-list tests

- [ ] **Step 5: Keep provider wiring unchanged**

Confirm `lib/core/services/providers.dart` still exposes the same notifier:

```dart
final downloadNotifierProvider = ChangeNotifierProvider<DownloadNotifier>((ref) {
  return DownloadNotifier(
    notifications: flutterLocalNotificationsPlugin,
    trackDownload: ref.read(photoRepositoryProvider).trackDownload,
    requestNotificationPermissions: requestNotificationPermissions,
  );
});
```

- [ ] **Step 6: Commit**

```bash
git add lib/core/services/download_notifier.dart lib/core/services/providers.dart test/core/services/download_notifier_test.dart
git commit -m "feat: expose download task history for settings"
```

---

### Task 4: Build the settings pages and widgets

**Files:**
- Create: `lib/features/settings/presentation/widgets/settings_section.dart`
- Create: `lib/features/settings/presentation/widgets/settings_row.dart`
- Create: `lib/features/settings/presentation/pages/settings_page.dart`
- Create: `lib/features/settings/presentation/pages/settings_language_page.dart`
- Create: `lib/features/settings/presentation/pages/settings_downloads_page.dart`
- Test: `test/features/settings/presentation/pages/settings_page_test.dart`
- Test: `test/features/settings/presentation/pages/settings_language_page_test.dart`
- Test: `test/features/settings/presentation/pages/settings_downloads_page_test.dart`

- [ ] **Step 1: Write the failing settings-page widget test**

Create `test/features/settings/presentation/pages/settings_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:musea/features/settings/presentation/pages/settings_page.dart';
import 'package:musea/features/settings/presentation/providers/settings_provider.dart';

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
  testWidgets('renders grouped settings rows and sign out button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsLocalDataSourceProvider.overrideWithValue(_FakeSettingsLocalDataSource()),
          appVersionProvider.overrideWith((ref) async => 'v1.0.0'),
          cacheBytesProvider.overrideWith((ref) async => 128 * 1024 * 1024),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Download over Wi-Fi only'), findsOneWidget);
    expect(find.text('Cache'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('Feedback'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/settings/presentation/pages/settings_page_test.dart`

Expected: FAIL because `SettingsPage` does not exist yet

- [ ] **Step 3: Add the reusable widgets**

Create `lib/features/settings/presentation/widgets/settings_section.dart`:

```dart
import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: Color(0xFFA8A29E),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEEEBE6)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
```

Create `lib/features/settings/presentation/widgets/settings_row.dart`:

```dart
import 'package:flutter/material.dart';

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 72,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF292524)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF18181B),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Add the three pages**

Create `lib/features/settings/presentation/pages/settings_language_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:musea/features/settings/presentation/providers/settings_provider.dart';

class SettingsLanguagePage extends ConsumerWidget {
  const SettingsLanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final selected = settings.value?.language ?? AppLanguage.system;

    Widget option(AppLanguage language, String title) {
      return RadioListTile<AppLanguage>(
        value: language,
        groupValue: selected,
        title: Text(title),
        onChanged: (value) {
          if (value != null) {
            ref.read(settingsControllerProvider.notifier).setLanguage(value);
          }
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Language')),
      body: ListView(
        children: [
          option(AppLanguage.system, 'Follow system'),
          option(AppLanguage.english, 'English'),
          option(AppLanguage.simplifiedChinese, '简体中文'),
        ],
      ),
    );
  }
}
```

Create `lib/features/settings/presentation/pages/settings_downloads_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/services/download_notifier.dart';
import 'package:musea/core/services/providers.dart';

class SettingsDownloadsPage extends ConsumerWidget {
  const SettingsDownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadNotifierProvider).tasks;
    final downloading =
        tasks.where((task) => task.status == DownloadTaskStatus.downloading).toList();
    final completed =
        tasks.where((task) => task.status == DownloadTaskStatus.completed).toList();
    final failed =
        tasks.where((task) => task.status == DownloadTaskStatus.failed).toList();

    Widget section(String title, List<DownloadTask> items) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 12),
          ...items.map(
            (task) => ListTile(
              title: Text(task.title),
              subtitle: Text(task.subtitle),
              trailing: task.status == DownloadTaskStatus.failed
                  ? TextButton(onPressed: () {}, child: const Text('Retry'))
                  : Text(task.status.name),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: tasks.isEmpty
          ? const Center(child: Text('No downloads yet'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                section('Downloading', downloading),
                section('Completed', completed),
                section('Failed', failed),
              ],
            ),
    );
  }
}
```

Create `lib/features/settings/presentation/pages/settings_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/core/services/cache_summary_service.dart';
import 'package:musea/features/settings/presentation/providers/settings_provider.dart';
import 'package:musea/features/settings/presentation/widgets/settings_row.dart';
import 'package:musea/features/settings/presentation/widgets/settings_section.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final cacheBytes = ref.watch(cacheBytesProvider);
    final version = ref.watch(appVersionProvider);

    final current = settings.value;
    final languageLabel = switch (current?.language ?? AppLanguage.system) {
      AppLanguage.system => 'Follow system',
      AppLanguage.english => 'English',
      AppLanguage.simplifiedChinese => '简体中文',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          SettingsSection(
            title: 'Preferences',
            children: [
              SettingsRow(
                icon: Icons.translate_rounded,
                title: 'Language',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(languageLabel),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                onTap: () => context.push('/settings/language'),
              ),
              SettingsRow(
                icon: Icons.wifi_rounded,
                title: 'Download over Wi-Fi only',
                trailing: Switch(
                  value: current?.downloadOverWifiOnly ?? true,
                  onChanged: (value) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setDownloadOverWifiOnly(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SettingsSection(
            title: 'Storage',
            children: [
              SettingsRow(
                icon: Icons.delete_outline_rounded,
                title: 'Cache',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(CacheSummaryService.formatBytes(cacheBytes.value ?? 0)),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear cache?'),
                      content: const Text(
                        'This removes temporary cache but keeps completed downloads.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(settingsControllerProvider.notifier).clearCache();
                  }
                },
              ),
              SettingsRow(
                icon: Icons.download_rounded,
                title: 'Downloads',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.chevron_right_rounded),
                  ],
                ),
                onTap: () => context.push('/settings/downloads'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SettingsSection(
            title: 'About',
            children: [
              SettingsRow(
                icon: Icons.info_outline_rounded,
                title: 'Version',
                trailing: Text(version.value ?? '...'),
              ),
              SettingsRow(
                icon: Icons.code_rounded,
                title: 'Feedback',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('GitHub'),
                    Icon(Icons.open_in_new_rounded),
                  ],
                ),
                onTap: () async {
                  await ref.read(feedbackLauncherProvider)(
                    ref.read(feedbackUriProvider),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign out?'),
                    content: const Text(
                      'Your current account session will be removed from this device.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) context.pop();
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Add the remaining widget tests**

Create `test/features/settings/presentation/pages/settings_language_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:musea/features/settings/presentation/pages/settings_language_page.dart';
import 'package:musea/features/settings/presentation/providers/settings_provider.dart';

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
  testWidgets('selecting a language updates the checked option', (tester) async {
    final dataSource = _FakeSettingsLocalDataSource();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsLocalDataSourceProvider.overrideWithValue(dataSource),
        ],
        child: const MaterialApp(home: SettingsLanguagePage()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(dataSource.value.language, AppLanguage.english);
  });
}
```

Create `test/features/settings/presentation/pages/settings_downloads_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/core/services/download_notifier.dart';
import 'package:musea/core/services/providers.dart';
import 'package:musea/features/settings/presentation/pages/settings_downloads_page.dart';

void main() {
  testWidgets('renders empty state when no tasks exist', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadNotifierProvider.overrideWith((ref) => DownloadNotifier.noop()),
        ],
        child: const MaterialApp(home: SettingsDownloadsPage()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('No downloads yet'), findsOneWidget);
  });
}
```

- [ ] **Step 6: Run the settings page tests**

Run: `flutter test test/features/settings/presentation/pages/settings_page_test.dart`

Expected: PASS

Run: `flutter test test/features/settings/presentation/pages/settings_language_page_test.dart`

Expected: PASS

Run: `flutter test test/features/settings/presentation/pages/settings_downloads_page_test.dart`

Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/features/settings/presentation/widgets/settings_section.dart lib/features/settings/presentation/widgets/settings_row.dart lib/features/settings/presentation/pages/settings_page.dart lib/features/settings/presentation/pages/settings_language_page.dart lib/features/settings/presentation/pages/settings_downloads_page.dart test/features/settings/presentation/pages/settings_page_test.dart test/features/settings/presentation/pages/settings_language_page_test.dart test/features/settings/presentation/pages/settings_downloads_page_test.dart
git commit -m "feat: build settings pages"
```

---

### Task 5: Wire routes and Mine entry

**Files:**
- Modify: `lib/router/app_router.dart`
- Modify: `lib/features/profile/presentation/pages/mine_page.dart`
- Modify: `test/router/app_router_test.dart`
- Modify: `test/features/profile/presentation/pages/mine_tab_page_test.dart`

- [ ] **Step 1: Write the failing route test**

Append to `test/router/app_router_test.dart`:

```dart
testWidgets('router opens settings page from top-level path', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authLinkServiceProvider.overrideWithValue(_FakeAuthLinkService()),
        authRedirectUriProvider.overrideWithValue(
          Uri.parse('musea://auth/callback'),
        ),
        photosProvider(1).overrideWith((ref) => <Photo>[photo]),
        topicsProvider.overrideWith(() => TestTopicListNotifier(<Topic>[])),
        collectionsProvider(1).overrideWith((ref) => <Collection>[]),
      ],
      child: const MuseaApp(),
    ),
  );

  final appContext = tester.element(find.byType(Scaffold).first);
  GoRouter.of(appContext).go('/settings');
  await tester.pumpAndSettle();

  expect(find.text('Settings'), findsOneWidget);
});
```

- [ ] **Step 2: Write the failing Mine entry test**

Append to `test/features/profile/presentation/pages/mine_tab_page_test.dart`:

```dart
testWidgets('Mine tab exposes settings entry when signed in', (tester) async {
  const authUser = AuthUser(
    id: 'user-1',
    username: 'spaciba',
    displayName: 'Paula Poeira',
    profileImageMedium: 'https://example.com/avatar-medium.jpg',
    totalPhotos: 14,
    totalLikes: 114769,
    totalCollections: 58,
  );

  const publicUser = User(
    id: 'user-1',
    username: 'spaciba',
    name: 'Paula Poeira',
    profileImageSmall: 'https://example.com/avatar-small.jpg',
    profileImageMedium: 'https://example.com/avatar-medium.jpg',
    profileImageLarge: 'https://example.com/avatar-large.jpg',
    totalPhotos: 14,
    totalLikes: 114769,
    totalCollections: 58,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepository),
        authBootstrapSessionProvider.overrideWithValue(
          AuthSession(
            accessToken: 'token-1',
            tokenType: 'bearer',
            scope: 'public read_user',
            createdAt: 123,
            user: authUser,
            lastProfileRefreshAt: DateTime(2026, 5, 20, 10),
          ),
        ),
        authRedirectUriProvider.overrideWithValue(
          Uri.parse('musea://auth/callback'),
        ),
        userProfileProvider('spaciba').overrideWith((ref) => publicUser),
      ],
      child: const MaterialApp(home: ProfileTabPage()),
    ),
  );

  await tester.pump();
  expect(find.text('Settings'), findsOneWidget);
});
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/router/app_router_test.dart`

Expected: FAIL because `/settings` route is missing

Run: `flutter test test/features/profile/presentation/pages/mine_tab_page_test.dart`

Expected: FAIL because Mine does not expose a settings entry yet

- [ ] **Step 4: Add the routes**

Update `lib/router/app_router.dart` imports:

```dart
import 'package:musea/features/settings/presentation/pages/settings_downloads_page.dart';
import 'package:musea/features/settings/presentation/pages/settings_language_page.dart';
import 'package:musea/features/settings/presentation/pages/settings_page.dart';
```

Add root routes before `/callback`:

```dart
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsPage(),
      routes: [
        GoRoute(
          path: 'language',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const SettingsLanguagePage(),
        ),
        GoRoute(
          path: 'downloads',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const SettingsDownloadsPage(),
        ),
      ],
    ),
```

- [ ] **Step 5: Replace Mine actions with a settings entry**

In `lib/features/profile/presentation/pages/mine_page.dart`, remove the bottom-sheet action wiring:

```dart
                  _TopBarIconButton(
                    icon: Icons.tune_rounded,
                    onTap: () => context.push('/settings'),
                  ),
```

Add `import 'package:go_router/go_router.dart';`

Add a compact list card below the quick-action chips inside `_SignedInMineHeader`:

```dart
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F1F3)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings'),
                ),
              ),
```

Delete `_showMineActions(...)` entirely because sign out now lives in settings.

- [ ] **Step 6: Run the updated tests**

Run: `flutter test test/router/app_router_test.dart`

Expected: PASS including the new `/settings` route test

Run: `flutter test test/features/profile/presentation/pages/mine_tab_page_test.dart`

Expected: PASS including the new settings entry expectation

- [ ] **Step 7: Commit**

```bash
git add lib/router/app_router.dart lib/features/profile/presentation/pages/mine_page.dart test/router/app_router_test.dart test/features/profile/presentation/pages/mine_tab_page_test.dart
git commit -m "feat: connect mine to settings flow"
```

---

### Task 6: Final verification pass

**Files:**
- Modify: any files touched above if test fixes are needed

- [ ] **Step 1: Run focused settings test suite**

Run:

```bash
flutter test test/features/settings/ test/core/services/cache_summary_service_test.dart test/core/services/download_notifier_test.dart test/router/app_router_test.dart test/features/profile/presentation/pages/mine_tab_page_test.dart
```

Expected: PASS across settings, router, mine, cache, and download coverage

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze`

Expected: No issues found

- [ ] **Step 3: If analyzer or tests fail, fix only the reported issues**

Typical acceptable fixes in this pass:

```dart
// Example: add mounted check around async UI actions
if (!context.mounted) return;
```

```dart
// Example: make trailing rows const where the analyzer requests it
const Icon(Icons.chevron_right_rounded)
```

- [ ] **Step 4: Create the final feature commit**

```bash
git add lib/features/settings lib/core/services lib/router/app_router.dart lib/features/profile/presentation/pages/mine_page.dart test/features/settings test/core/services test/router/app_router_test.dart test/features/profile/presentation/pages/mine_tab_page_test.dart pubspec.yaml pubspec.lock
git commit -m "feat: add settings flow"
```

---

## Self-Review

### Spec coverage

- Settings entry from Mine: Task 5
- Dedicated settings route/page: Task 4 + Task 5
- Language selection + persistence: Task 1 + Task 2 + Task 4
- Wi-Fi-only toggle + persistence: Task 1 + Task 2 + Task 4
- Cache size + clear action: Task 2 + Task 4
- Downloads management page: Task 3 + Task 4
- Version display: Task 2 + Task 4
- GitHub feedback link: Task 2 + Task 4
- Sign out confirmation + session clearing: Task 4

### Placeholder scan

- No `TODO` / `TBD`
- Every file path is explicit
- Every test/run step includes commands
- Every feature area has at least one concrete implementation snippet

### Type consistency

- `AppLanguage` / `StoredSettings` are defined once in the datasource and consumed by providers/pages
- `DownloadTask` / `DownloadTaskStatus` are defined in `download_notifier.dart` and reused by the downloads page
- Route paths are consistent: `/settings`, `/settings/language`, `/settings/downloads`

