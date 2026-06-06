import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/features/auth/domain/entities/auth_session.dart';
import 'package:musea/features/auth/domain/entities/auth_user.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/domain/repositories/collection_repository.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/collections/presentation/widgets/save_to_collection_sheet.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

void main() {
  late MockCollectionRepository mockRepository;

  setUp(() {
    mockRepository = MockCollectionRepository();
  });

  Future<void> showSheet(WidgetTester tester) async {
    // Use a taller surface so the bottom sheet content is visible
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authBootstrapSessionProvider.overrideWithValue(
            AuthSession(
              accessToken: 'test-token',
              tokenType: 'bearer',
              scope: 'public read_user write_likes write_collections',
              createdAt: 0,
              user: const AuthUser(
                id: 'test-user',
                username: 'testuser',
                displayName: 'Test User',
                profileImageMedium: '',
                totalPhotos: 0,
                totalLikes: 0,
                totalCollections: 0,
              ),
              lastProfileRefreshAt: DateTime(2024),
            ),
          ),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
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
    showSaveToCollectionSheet(context, photoId: 'photo-123');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('sheet shows select view with collections on load',
      (tester) async {
    when(
      () => mockRepository.getUserCollections(
        any(),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => Right([
        Collection(
          id: 'col-1',
          title: 'Test Collection',
          totalPhotos: 5,
          isPrivate: true,
        ),
      ]),
    );

    await showSheet(tester);

    expect(find.text('Select collection'), findsOneWidget);
    expect(find.text('Test Collection'), findsOneWidget);
    expect(find.text('5 photos'), findsOneWidget);
    expect(find.text('Create new collection'), findsOneWidget);
  });

  testWidgets('tapping create new collection switches to create view',
      (tester) async {
    when(
      () => mockRepository.getUserCollections(
        any(),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(<Collection>[]));

    await showSheet(tester);

    await tester.tap(find.text('Create new collection'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('New collection'), findsOneWidget);
    expect(find.text('Back to collections'), findsOneWidget);
  });

  testWidgets('selecting a collection calls addPhotoToCollection',
      (tester) async {
    when(
      () => mockRepository.getUserCollections(
        any(),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => Right([
        Collection(
          id: 'col-1',
          title: 'Test Collection',
          totalPhotos: 5,
          isPrivate: true,
        ),
      ]),
    );

    when(
      () => mockRepository.addPhotoToCollection(
        collectionId: any(named: 'collectionId'),
        photoId: any(named: 'photoId'),
      ),
    ).thenAnswer((_) async => const Right(null));

    await showSheet(tester);

    await tester.ensureVisible(find.text('Test Collection'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Test Collection'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    verify(
      () => mockRepository.addPhotoToCollection(
        collectionId: 'col-1',
        photoId: 'photo-123',
      ),
    ).called(1);
  });
}
