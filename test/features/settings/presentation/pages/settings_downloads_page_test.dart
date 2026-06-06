import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/core/services/download_notifier.dart';
import 'package:musea/core/services/providers.dart';
import 'package:musea/features/settings/presentation/pages/settings_downloads_page.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('renders empty state when no download tasks exist',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadNotifierProvider
              .overrideWith((ref) => DownloadNotifier.noop()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsDownloadsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No downloads yet'), findsOneWidget);
  });
}
