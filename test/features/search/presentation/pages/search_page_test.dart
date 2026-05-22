import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/domain/repositories/collection_repository.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/discover/domain/repositories/photo_repository.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/profile/domain/repositories/profile_repository.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/features/search/domain/entities/search_result.dart';
import 'package:musea/features/search/presentation/pages/search_page.dart';

class MockPhotoRepository extends Mock implements PhotoRepository {}

class MockCollectionRepository extends Mock implements CollectionRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockPhotoRepository mockPhotoRepo;
  late MockCollectionRepository mockCollectionRepo;
  late MockProfileRepository mockProfileRepo;

  const forestUser = User(
    id: 'user-1',
    username: 'forest',
    name: 'Forest Archive',
    bio: 'Shoots outdoors',
    location: 'Portland',
    profileImageSmall: 'https://example.com/small-1.jpg',
    profileImageMedium: 'https://example.com/medium-1.jpg',
    profileImageLarge: 'https://example.com/large-1.jpg',
    totalPhotos: 12,
    totalLikes: 44,
    totalCollections: 3,
    followedByUser: true,
  );

  final photos = [
    Photo(
      id: 'photo-1',
      createdAt: DateTime(2024, 1, 1),
      width: 1200,
      height: 1600,
      color: '#AABBCC',
      description: 'Forest canopy',
      altDescription: 'Green trees',
      urlRaw: 'https://example.com/raw-1.jpg',
      urlFull: 'https://example.com/full-1.jpg',
      urlRegular: 'https://example.com/regular-1.jpg',
      urlSmall: 'https://example.com/small-1.jpg',
      urlThumb: 'https://example.com/thumb-1.jpg',
      likes: 80,
      downloads: 20,
      user: forestUser,
      tags: const [Tag(title: 'nature')],
    ),
  ];

  final collections = [
    Collection(
      id: 'collection-1',
      title: 'Forest Archive',
      description: 'Moody green landscapes',
      totalPhotos: 24,
      user: forestUser,
      coverPhoto: photos.first,
    ),
  ];

  setUp(() {
    mockPhotoRepo = MockPhotoRepository();
    mockCollectionRepo = MockCollectionRepository();
    mockProfileRepo = MockProfileRepository();

    when(() => mockPhotoRepo.searchPhotos(
          any(),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
          orderBy: any(named: 'orderBy'),
          color: any(named: 'color'),
          orientation: any(named: 'orientation'),
          contentFilter: any(named: 'contentFilter'),
        )).thenAnswer((_) async => Right(SearchPhotosResult(
          total: 2431,
          totalPages: 82,
          results: photos,
        )));

    when(() => mockCollectionRepo.searchCollections(
          any(),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        )).thenAnswer((_) async => Right(SearchCollectionsResult(
          total: 324,
          totalPages: 11,
          results: collections,
        )));

    when(() => mockProfileRepo.searchUsers(
          any(),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        )).thenAnswer((_) async => const Right(SearchUsersResult(
          total: 88,
          totalPages: 5,
          results: [forestUser],
        )));
  });

  Widget buildApp({String initialQuery = ''}) {
    return ProviderScope(
      overrides: [
        photoRepositoryProvider.overrideWithValue(mockPhotoRepo),
        collectionRepositoryProvider.overrideWithValue(mockCollectionRepo),
        profileRepositoryProvider.overrideWithValue(mockProfileRepo),
      ],
      child: MaterialApp(
        home: SearchPage(initialQuery: initialQuery),
      ),
    );
  }

  testWidgets('SearchPage shows idle state before search', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.text('Start typing to search'), findsOneWidget);
  });

  testWidgets('SearchPage shows photo results after submit', (tester) async {
    await tester.pumpWidget(buildApp(initialQuery: 'forest'));
    await tester.pump();

    await tester.tap(find.byKey(const Key('search-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Photos'), findsWidgets);
    expect(find.text('Collections'), findsWidgets);
    expect(find.text('Users'), findsWidgets);
    expect(find.byKey(const Key('photo-filter-trigger')), findsOneWidget);
  });

  testWidgets('SearchPage debounces text input and triggers search',
      (tester) async {
    await tester.pumpWidget(buildApp(initialQuery: ''));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'cats');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Start typing to search'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    verify(() => mockPhotoRepo.searchPhotos(
          'cats',
          page: 1,
          perPage: 20,
          orderBy: 'relevant',
          color: null,
          orientation: null,
          contentFilter: 'high',
        )).called(1);
  });

  testWidgets('SearchPage auto-searches when initialQuery is provided',
      (tester) async {
    await tester.pumpWidget(buildApp(initialQuery: 'forest'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    verify(() => mockPhotoRepo.searchPhotos(
          'forest',
          page: 1,
          perPage: 20,
          orderBy: 'relevant',
          color: null,
          orientation: null,
          contentFilter: 'high',
        )).called(1);
    expect(find.text('Start typing to search'), findsNothing);
  });

  testWidgets('SearchPage opens and closes the photo filter panel',
      (tester) async {
    await tester.pumpWidget(buildApp(initialQuery: 'forest'));
    await tester.pump();

    await tester.tap(find.byKey(const Key('search-submit-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('photo-filter-trigger')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('photo-filter-panel')), findsOneWidget);
    expect(find.byKey(const Key('photo-filter-overlay')), findsOneWidget);
    expect(find.text('Sort by'), findsOneWidget);
    expect(find.text('Orientation'), findsOneWidget);

    await tester.tap(find.byKey(const Key('photo-filter-trigger')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('photo-filter-panel')), findsNothing);
  });

  testWidgets('SearchPage switches to collections and users segments',
      (tester) async {
    await tester.pumpWidget(buildApp(initialQuery: 'forest'));
    await tester.pump();

    await tester.tap(find.byKey(const Key('search-submit-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Collections').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('photo-filter-trigger')), findsNothing);
    expect(find.text('Forest Archive'), findsOneWidget);

    await tester.tap(find.text('Users').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('photo-filter-trigger')), findsNothing);
    expect(find.text('@forest · 12 photos · 3 collections'), findsOneWidget);
    expect(find.text('Shoots outdoors'), findsOneWidget);
    expect(find.text('Following'), findsOneWidget);
  });

  testWidgets('SearchPage shows empty state when no results', (tester) async {
    when(() => mockPhotoRepo.searchPhotos(
          any(),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
          orderBy: any(named: 'orderBy'),
          color: any(named: 'color'),
          orientation: any(named: 'orientation'),
          contentFilter: any(named: 'contentFilter'),
        )).thenAnswer((_) async => const Right(SearchPhotosResult(
          total: 0,
          totalPages: 0,
          results: [],
        )));

    await tester.pumpWidget(buildApp(initialQuery: 'desert'));
    await tester.pump();

    await tester.tap(find.byKey(const Key('search-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('No matching photos'), findsOneWidget);
  });
}
