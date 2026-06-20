import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:musea/features/settings/presentation/pages/settings_language_page.dart';
import 'package:musea/features/settings/presentation/providers/settings_provider.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

class _FakeSettingsLocalDataSource implements SettingsLocalDataSource {
  StoredSettings value = const StoredSettings(
    language: AppLanguage.system,
    downloadOverWifiOnly: true,
    themeMode: AppThemeMode.system,
  );

  @override
  Future<StoredSettings> readSettings() async => value;

  @override
  Future<void> saveSettings(StoredSettings settings) async {
    value = settings;
  }
}

void main() {
  testWidgets('selecting a language updates the stored preference',
      (tester) async {
    final dataSource = _FakeSettingsLocalDataSource();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsLocalDataSourceProvider.overrideWithValue(dataSource),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsLanguagePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(dataSource.value.language, AppLanguage.english);
  });
}
