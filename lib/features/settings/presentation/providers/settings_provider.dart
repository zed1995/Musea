import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:musea/core/services/cache_summary_service.dart';
import 'package:musea/features/settings/data/datasources/settings_local_datasource.dart';

class SettingsState {
  const SettingsState({
    required this.language,
    required this.downloadOverWifiOnly,
    required this.themeMode,
  });

  final AppLanguage language;
  final bool downloadOverWifiOnly;
  final AppThemeMode themeMode;

  SettingsState copyWith({
    AppLanguage? language,
    bool? downloadOverWifiOnly,
    AppThemeMode? themeMode,
  }) {
    return SettingsState(
      language: language ?? this.language,
      downloadOverWifiOnly: downloadOverWifiOnly ?? this.downloadOverWifiOnly,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

final settingsLocalDataSourceProvider =
    Provider<SettingsLocalDataSource>((ref) {
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
  return Uri.parse('https://github.com/zed1995/Musea');
});

final feedbackLauncherProvider = Provider<Future<bool> Function(Uri)>((ref) {
  return launchUrl;
});

Locale? localeForAppLanguage(AppLanguage language) {
  return switch (language) {
    AppLanguage.system => null,
    AppLanguage.english => const Locale('en'),
    AppLanguage.simplifiedChinese => const Locale('zh'),
  };
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);

class SettingsController extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    final stored =
        await ref.read(settingsLocalDataSourceProvider).readSettings();
    return SettingsState(
      language: stored.language,
      downloadOverWifiOnly: stored.downloadOverWifiOnly,
      themeMode: stored.themeMode,
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    final current = state.requireValue;
    final next = current.copyWith(language: language);
    state = AsyncData(next);
    await _save(next);
  }

  Future<void> setDownloadOverWifiOnly(bool value) async {
    final current = state.requireValue;
    final next = current.copyWith(downloadOverWifiOnly: value);
    state = AsyncData(next);
    await _save(next);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final current = state.requireValue;
    final next = current.copyWith(themeMode: mode);
    state = AsyncData(next);
    await _save(next);
  }

  Future<void> clearCache() async {
    await ref.read(cacheSummaryServiceProvider).clearAll();
    ref.invalidate(cacheBytesProvider);
  }

  Future<void> _save(SettingsState stateValue) {
    return ref.read(settingsLocalDataSourceProvider).saveSettings(
          StoredSettings(
            language: stateValue.language,
            downloadOverWifiOnly: stateValue.downloadOverWifiOnly,
            themeMode: stateValue.themeMode,
          ),
        );
  }
}
