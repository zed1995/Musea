import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/domain/repositories/collection_repository.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/collections/presentation/widgets/collection_delete_sheet.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

void main() {
  late MockCollectionRepository mockRepository;

  setUp(() {
    mockRepository = MockCollectionRepository();
  });

  Future<void> showSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showCollectionDeleteSheet(
                  context,
                  collection: Collection(
                    id: 'col-1',
                    title: 'Kyoto Research',
                    totalPhotos: 5,
                  ),
                ),
                child: const Text('Open Delete Sheet'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Delete Sheet'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders title and warning', (tester) async {
    await showSheet(tester);
    expect(find.text('Delete collection?'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('delete button disabled until correct name typed', (tester) async {
    when(
      () => mockRepository.deleteCollection(any()),
    ).thenAnswer((_) async => const Right(null));
    await showSheet(tester);

    expect(
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Delete collection'),
      ).enabled,
      isFalse,
    );

    await tester.enterText(find.byType(TextFormField), 'Kyoto Research');
    await tester.pumpAndSettle();

    expect(
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Delete collection'),
      ).enabled,
      isTrue,
    );
  });

  testWidgets('wrong name keeps button disabled', (tester) async {
    await showSheet(tester);
    await tester.enterText(find.byType(TextFormField), 'Wrong Name');
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Delete collection'),
      ).enabled,
      isFalse,
    );
  });

  testWidgets('tapping delete calls repository', (tester) async {
    when(
      () => mockRepository.deleteCollection(any()),
    ).thenAnswer((_) async => const Right(null));
    await showSheet(tester);
    await tester.enterText(find.byType(TextFormField), 'Kyoto Research');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Delete collection'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete collection'),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    verify(() => mockRepository.deleteCollection('col-1')).called(1);
  });

  testWidgets('tapping cancel dismisses sheet', (tester) async {
    await showSheet(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete collection?'), findsNothing);
  });
}
