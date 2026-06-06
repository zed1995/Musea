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
  static const String _boxName = 'settings';
  static const String _languageKey = 'language';
  static const String _wifiOnlyKey = 'download_over_wifi_only';

  Box<dynamic>? _box;

  Future<Box<dynamic>> get box async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  @override
  Future<StoredSettings> readSettings() async {
    final settingsBox = await box;
    return StoredSettings(
      language: AppLanguage.fromStorage(
        settingsBox.get(_languageKey) as String?,
      ),
      downloadOverWifiOnly: (settingsBox.get(_wifiOnlyKey) as bool?) ?? true,
    );
  }

  @override
  Future<void> saveSettings(StoredSettings settings) async {
    final settingsBox = await box;
    await settingsBox.put(_languageKey, settings.language.storageValue);
    await settingsBox.put(_wifiOnlyKey, settings.downloadOverWifiOnly);
  }
}
