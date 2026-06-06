import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:musea/features/settings/presentation/pages/settings_page.dart';
import 'package:musea/features/settings/presentation/providers/settings_provider.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

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
  testWidgets('renders grouped settings rows and sign out button',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsLocalDataSourceProvider
              .overrideWithValue(_FakeSettingsLocalDataSource()),
          appVersionProvider.overrideWith((ref) async => 'v1.0.0'),
          cacheBytesProvider.overrideWith((ref) async => 128 * 1024 * 1024),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsPage(),
        ),
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
    await tester.scrollUntilVisible(
      find.text('Sign out'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Sign out'), findsOneWidget);
  });
}
