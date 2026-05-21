import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/domain/repositories/collection_repository.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/collections/presentation/widgets/collection_edit_sheet.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

void main() {
  late MockCollectionRepository mockRepository;

  setUp(() {
    mockRepository = MockCollectionRepository();
  });

  Future<void> showSheet(WidgetTester tester, {Collection? collection}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showCollectionEditSheet(
                  context,
                  collection: collection ??
                      Collection(id: 'col-1', title: 'Test', totalPhotos: 5),
                ),
                child: const Text('Open Edit Sheet'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Edit Sheet'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders title and pre-populated fields', (tester) async {
    await showSheet(
      tester,
      collection: Collection(
        id: 'col-1',
        title: 'Kyoto Research',
        description: 'Street glow',
        totalPhotos: 5,
      ),
    );
    expect(find.text('Edit collection'), findsOneWidget);
    expect(find.text('Kyoto Research'), findsOneWidget);
    expect(find.text('Street glow'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('save calls repository with current values', (tester) async {
    when(
      () => mockRepository.updateCollection(
        any(),
        title: any(named: 'title'),
        description: any(named: 'description'),
        private: any(named: 'private'),
      ),
    ).thenAnswer(
      (_) async =>
          Right(Collection(id: 'col-1', title: 'Updated', totalPhotos: 5)),
    );

    await showSheet(
      tester,
      collection: Collection(id: 'col-1', title: 'Old Title', totalPhotos: 5),
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    verify(
      () => mockRepository.updateCollection(
        'col-1',
        title: 'Old Title',
        description: null,
        private: false,
      ),
    ).called(1);
  });

  testWidgets('making changes and saving passes new values', (tester) async {
    when(
      () => mockRepository.updateCollection(
        any(),
        title: any(named: 'title'),
        description: any(named: 'description'),
        private: any(named: 'private'),
      ),
    ).thenAnswer(
      (_) async =>
          Right(Collection(id: 'col-1', title: 'New Name', totalPhotos: 5)),
    );

    await showSheet(
      tester,
      collection: Collection(id: 'col-1', title: 'Old Title', totalPhotos: 5),
    );

    await tester.enterText(find.byType(TextFormField).first, 'New Name');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Private'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Private'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    verify(
      () => mockRepository.updateCollection(
        'col-1',
        title: 'New Name',
        description: null,
        private: true,
      ),
    ).called(1);
  });
}
