import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/widgets/collection_manage_sheet.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

void main() {
  Widget buildTestApp({
    VoidCallback? onEdit,
    VoidCallback? onRemovePhotos,
    VoidCallback? onDelete,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showCollectionManageSheet(
              context,
              collection:
                  Collection(id: 'col-1', title: 'Test', totalPhotos: 5),
              onEdit: onEdit ?? () {},
              onRemovePhotos: onRemovePhotos ?? () {},
              onDelete: onDelete ?? () {},
            ),
            child: const Text('Open Manage Sheet'),
          ),
        ),
      ),
    );
  }

  testWidgets('renders title, subtitle, and 3 menu items', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open Manage Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Manage collection'), findsOneWidget);
    expect(find.text('Edit details'), findsOneWidget);
    expect(find.text('Remove photos'), findsOneWidget);
    expect(find.text('Delete collection'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('tapping Edit details calls onEdit', (tester) async {
    var edited = false;
    await tester.pumpWidget(buildTestApp(onEdit: () => edited = true));
    await tester.tap(find.text('Open Manage Sheet'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit details'));
    await tester.pumpAndSettle();
    expect(edited, isTrue);
  });

  testWidgets('tapping Remove photos calls onRemovePhotos', (tester) async {
    var removed = false;
    await tester.pumpWidget(
      buildTestApp(onRemovePhotos: () => removed = true),
    );
    await tester.tap(find.text('Open Manage Sheet'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove photos'));
    await tester.pumpAndSettle();
    expect(removed, isTrue);
  });

  testWidgets('tapping Delete collection calls onDelete', (tester) async {
    var deleted = false;
    await tester.pumpWidget(buildTestApp(onDelete: () => deleted = true));
    await tester.tap(find.text('Open Manage Sheet'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete collection'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });
}
