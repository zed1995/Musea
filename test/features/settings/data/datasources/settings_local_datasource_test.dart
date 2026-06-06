import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musea/features/settings/data/datasources/settings_local_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late SettingsLocalDataSource dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'musea_settings_local_datasource_test',
    );
    Hive.init(tempDir.path);
    await Hive.deleteBoxFromDisk('settings');
    dataSource = SettingsLocalDataSourceImpl();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
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
