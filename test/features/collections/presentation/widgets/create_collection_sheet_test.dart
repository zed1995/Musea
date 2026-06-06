import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/domain/repositories/collection_repository.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/collections/presentation/widgets/create_collection_sheet.dart';
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
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(child: Text('Test host')),
          ),
        ),
      ),
    );

    final context = tester.element(find.text('Test host'));
    showCreateCollectionSheet(context);
    await tester.pumpAndSettle();
  }

  testWidgets('sheet renders all form fields', (tester) async {
    await showSheet(tester);

    expect(find.text('New collection'), findsOneWidget);
    expect(find.text('Collection Name'), findsOneWidget);
    expect(find.text('Description Optional'), findsOneWidget);
    expect(find.text('Visibility'), findsOneWidget);
    expect(find.text('Private collection'), findsOneWidget);
    expect(find.text('Public collection'), findsOneWidget);
    expect(find.text('Create collection'), findsOneWidget);
  });

  testWidgets('create button is disabled when title is empty', (tester) async {
    await showSheet(tester);

    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create collection'),
    );
    expect(createButton.enabled, isFalse);
  });

  testWidgets('typing title enables create button', (tester) async {
    await showSheet(tester);

    await tester.enterText(find.byType(TextFormField).first, 'My Collection');
    await tester.pumpAndSettle();

    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create collection'),
    );
    expect(createButton.enabled, isTrue);
  });

  testWidgets('tapping create calls repository and navigates', (tester) async {
    when(
      () => mockRepository.createCollection(
        title: any(named: 'title'),
        description: any(named: 'description'),
        private: any(named: 'private'),
      ),
    ).thenAnswer(
      (_) async => Right(
        Collection(id: 'new-1', title: 'Test', totalPhotos: 0),
      ),
    );

    await showSheet(tester);

    await tester.enterText(find.byType(TextFormField).first, 'My Collection');
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(FilledButton, 'Create collection'),
    );
    await tester.pumpAndSettle();

    verify(
      () => mockRepository.createCollection(
        title: 'My Collection',
        description: null,
        private: true,
      ),
    ).called(1);
  });
}
