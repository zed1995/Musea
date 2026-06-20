import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:musea/features/settings/presentation/pages/settings_appearance_page.dart';
import 'package:musea/features/settings/presentation/providers/settings_provider.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

class _FakeSettingsLocalDataSource implements SettingsLocalDataSource {
  _FakeSettingsLocalDataSource(this._value);

  StoredSettings _value;
  StoredSettings get value => _value;

  @override
  Future<StoredSettings> readSettings() async => _value;

  @override
  Future<void> saveSettings(StoredSettings settings) async {
    _value = settings;
  }
}

void main() {
  testWidgets('renders three options with the right labels', (tester) async {
    final dataSource = _FakeSettingsLocalDataSource(const StoredSettings(
      language: AppLanguage.system,
      downloadOverWifiOnly: true,
      themeMode: AppThemeMode.system,
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsLocalDataSourceProvider.overrideWithValue(dataSource),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsAppearancePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Follow system'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('tapping Dark calls setThemeMode and updates the stored value',
      (tester) async {
    final dataSource = _FakeSettingsLocalDataSource(const StoredSettings(
      language: AppLanguage.system,
      downloadOverWifiOnly: true,
      themeMode: AppThemeMode.system,
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsLocalDataSourceProvider.overrideWithValue(dataSource),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsAppearancePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(dataSource.value.themeMode, AppThemeMode.dark);
  });

  testWidgets('tapping Light from Dark updates the stored value',
      (tester) async {
    final dataSource = _FakeSettingsLocalDataSource(const StoredSettings(
      language: AppLanguage.system,
      downloadOverWifiOnly: true,
      themeMode: AppThemeMode.dark,
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsLocalDataSourceProvider.overrideWithValue(dataSource),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsAppearancePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    expect(dataSource.value.themeMode, AppThemeMode.light);
  });
}
