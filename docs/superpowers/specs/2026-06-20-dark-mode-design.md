# Dark Mode Design

Date: 2026-06-20

## Goal

Expose the already-implemented `ThemeMode` as a user-controlled setting. The user picks between **System / Light / Dark** in Settings, the choice is persisted across launches via the existing `settings` Hive box, and `MaterialApp.router` applies the choice immediately.

## Non-Goals

- No custom Material 3 seed color generation.
- No per-photo or per-screen theming.
- No auto-switch-by-time-of-day.
- No AMOLED pure-black variant in v1 (the existing dark theme is dark grey; revisit later if needed).

## Current State

- `app.dart` hardcodes `themeMode: ThemeMode.system`. The dark theme (`AppTheme.darkTheme`) is already defined and looks correct.
- `SettingsLocalDataSource` already persists `StoredSettings { language, downloadOverWifiOnly }` in Hive.
- `SettingsController` already extends `AsyncNotifier<SettingsState>` with `copyWith` and a `_save` helper.
- The Settings Page already has a "Preferences" section with two rows: Language and Download over Wi-Fi only.
- `SettingsLanguagePage` exists as a self-contained sub-page pattern we can mirror.

The only thing missing is:

1. A persisted `themeMode` field on `StoredSettings` / `SettingsState`.
2. A UI page to pick the value.
3. Wiring `MaterialApp.router.themeMode` to the chosen value.

## Approach

Mirror the existing Language pattern:

- New `AppThemeMode` enum (`system | light | dark`) with `storageValue` / `fromStorage`, same shape as `AppLanguage`.
- Extend `StoredSettings` and `SettingsState` with a `themeMode` field. Default to `system` when the key is missing on disk (backwards-compatible — old data still works).
- Extend `SettingsController` with `setThemeMode(AppThemeMode)`.
- New `SettingsAppearancePage` (single radio list) wired from a new row in the Settings "Preferences" section.
- `app.dart` reads `settingsControllerProvider` and binds `themeMode` accordingly.

## Data Design

### `AppThemeMode` enum (new)

Lives in `lib/features/settings/data/datasources/settings_local_datasource.dart`, right next to `AppLanguage`:

```dart
enum AppThemeMode {
  system('system'),
  light('light'),
  dark('dark');

  const AppThemeMode(this.storageValue);
  final String storageValue;

  static AppThemeMode fromStorage(String? raw) {
    return AppThemeMode.values.firstWhere(
      (value) => value.storageValue == raw,
      orElse: () => AppThemeMode.system,
    );
  }
}
```

### `StoredSettings` (extend)

```dart
class StoredSettings {
  const StoredSettings({
    required this.language,
    required this.downloadOverWifiOnly,
    required this.themeMode,   // NEW
  });

  final AppLanguage language;
  final bool downloadOverWifiOnly;
  final AppThemeMode themeMode;   // NEW
}
```

### `SettingsState` (extend)

```dart
class SettingsState {
  const SettingsState({
    required this.language,
    required this.downloadOverWifiOnly,
    required this.themeMode,   // NEW
  });

  final AppLanguage language;
  final bool downloadOverWifiOnly;
  final AppThemeMode themeMode;   // NEW

  SettingsState copyWith({
    AppLanguage? language,
    bool? downloadOverWifiOnly,
    AppThemeMode? themeMode,   // NEW
  }) { ... }
}
```

### `SettingsLocalDataSourceImpl` (modify)

- Add `static const String _themeModeKey = 'theme_mode';`.
- `readSettings()` reads `_themeModeKey` and falls back to `AppThemeMode.system` if missing.
- `saveSettings(...)` writes `_themeModeKey` alongside the existing two.

The migration is automatic: the first read on a device that was on the old schema returns `system` because the key is absent, and from then on it persists.

## State Management

### `SettingsController` (extend)

```dart
class SettingsController extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    final stored = await ref.read(settingsLocalDataSourceProvider).readSettings();
    return SettingsState(
      language: stored.language,
      downloadOverWifiOnly: stored.downloadOverWifiOnly,
      themeMode: stored.themeMode,   // NEW
    );
  }

  Future<void> setLanguage(AppLanguage language) async { ... }
  Future<void> setDownloadOverWifiOnly(bool value) async { ... }
  Future<void> setThemeMode(AppThemeMode mode) async {   // NEW
    final current = state.requireValue;
    final next = current.copyWith(themeMode: mode);
    state = AsyncData(next);
    await _save(next);
  }
}
```

`_save` is updated to pass `themeMode` through to `StoredSettings`.

## Wiring

### `app.dart` (modify)

```dart
return MaterialApp.router(
  title: 'Musea',
  ...
  themeMode: settings.valueOrNull?.themeMode.toFlutterThemeMode() ?? ThemeMode.system,
  ...
);
```

Where:

```dart
extension on AppThemeMode {
  ThemeMode toFlutterThemeMode() => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}
```

Lives in the same `settings_provider.dart` file (next to `localeForAppLanguage`, which is the same shape of helper for the language case).

## UI

### `SettingsAppearancePage` (new)

A self-contained page mirroring `SettingsLanguagePage`:

- `AndroidTopBar` with title `appearanceTitle` and a back button.
- A `SettingsSection` with three `SettingsRow` rows. Each row is tappable, with a leading radio dot showing the selected state:
  - `themeSystem` — `AppThemeMode.system`
  - `themeLight` — `AppThemeMode.light`
  - `themeDark` — `AppThemeMode.dark`
- Tapping a row calls `ref.read(settingsControllerProvider.notifier).setThemeMode(value)`. No need to pop the page — the radio update is enough feedback, same as `SettingsLanguagePage` (which also stays open while the user changes selections, and the user pops manually).

### `SettingsPage` (modify)

Add a new `SettingsRow` to the "Preferences" section, **above** the language row so the order is "Theme" → "Language" → "Download over Wi-Fi only". This matches iOS / Android conventions where appearance comes first.

The row's trailing widget shows the current value (`themeSystem` / `themeLight` / `themeDark`) plus a chevron. Tapping pushes `SettingsAppearancePage`.

## i18n

Five new keys, en + zh:

| Key | en | zh |
|---|---|---|
| `appearanceTitle` | Appearance | 外观 |
| `themeSystem` | Follow system | 跟随系统 |
| `themeLight` | Light | 浅色 |
| `themeDark` | Dark | 深色 |

## Error Handling

- Hive read failure: `readSettings` already throws; `AsyncNotifier.build` will surface it as `AsyncError`. The Settings page already handles this gracefully (shows nothing / `current` is null, rows render in their default state).
- Hive write failure: `_save` propagates the error. The in-memory state is already updated, so the UI reflects the user's choice immediately; the next launch will fall back to the previously persisted value. We do not show a SnackBar in v1 — the failure is silent because there is no user-recoverable action.
- Missing `themeMode` key on disk: read falls back to `system`. Same as if a brand-new install ran.

## Files

### New

- `lib/features/settings/presentation/pages/settings_appearance_page.dart`
- `test/features/settings/presentation/pages/settings_appearance_page_test.dart`

### Modify

- `lib/features/settings/data/datasources/settings_local_datasource.dart` — add `AppThemeMode`, extend `StoredSettings`, update `read` / `save`.
- `lib/features/settings/presentation/providers/settings_provider.dart` — extend `SettingsState`, add `setThemeMode`, add `toFlutterThemeMode` extension.
- `lib/app.dart` — bind `themeMode` to the controller value.
- `lib/features/settings/presentation/pages/settings_page.dart` — add the Appearance row to the Preferences section.
- `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb` — add the five new keys.
- `test/features/settings/data/datasources/settings_local_datasource_test.dart` — assert old data (no `theme_mode` key) reads as `system`; new writes round-trip.
- `test/features/settings/presentation/pages/settings_page_test.dart` — assert the Appearance row exists and shows the current value.
- `test/features/settings/presentation/pages/settings_appearance_page_test.dart` — assert the three radios reflect the current value and that tapping a row calls `setThemeMode`.

### No-Op

- `AppTheme` — already defines a working `darkTheme`.
- Router, navigation, other features.
- The existing `themeMode: ThemeMode.system` in `app.dart` is replaced, not added.

## Testing

### Unit / widget

- `settings_local_datasource_test.dart`:
  - read on a fresh box returns `themeMode: system`.
  - read on a box with only `language` / `download_over_wifi_only` keys also returns `themeMode: system`.
  - round-trip: save `dark`, read returns `dark`.
- `settings_appearance_page_test.dart`:
  - Initial render shows the three rows with the right labels.
  - Tapping a row calls `setThemeMode` with the new value and the radio moves.
  - The back button is shown.

### Integration

- `app.dart` smoke test (widget): render `MuseaApp` with a `ProviderScope` that overrides `settingsControllerProvider` with a `FakeSettingsController` (extends `SettingsController`, overrides `build()` to return a `SettingsState(themeMode: AppThemeMode.dark)`), and assert that the `MaterialApp` it produces has `themeMode == ThemeMode.dark`. The override pattern is the same one the existing tests use for `authBootstrapSessionProvider`.

## Rollout

- TDD-first per `CLAUDE.md`.
- One commit per logical unit (enum + persistence, controller, settings page, app wiring).
- Final pass: `flutter analyze` + `flutter test` clean.
