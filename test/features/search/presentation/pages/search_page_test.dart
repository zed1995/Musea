import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/search/domain/entities/search_result.dart';
import 'package:musea/features/search/presentation/pages/search_page.dart';
import 'package:musea/features/search/presentation/providers/search_provider.dart';

void main() {
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

  const cityUser = User(
    id: 'user-2',
    username: 'city',
    name: 'City Studio',
    bio: 'Architecture observer',
    location: 'Tokyo',
    profileImageSmall: 'https://example.com/small-2.jpg',
    profileImageMedium: 'https://example.com/medium-2.jpg',
    profileImageLarge: 'https://example.com/large-2.jpg',
    totalPhotos: 8,
    totalLikes: 20,
    totalCollections: 2,
    followedByUser: false,
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
    Photo(
      id: 'photo-2',
      createdAt: DateTime(2024, 1, 2),
      width: 1600,
      height: 1200,
      color: '#DDEEFF',
      description: 'City geometry',
      altDescription: 'Modern architecture',
      urlRaw: 'https://example.com/raw-2.jpg',
      urlFull: 'https://example.com/full-2.jpg',
      urlRegular: 'https://example.com/regular-2.jpg',
      urlSmall: 'https://example.com/small-2.jpg',
      urlThumb: 'https://example.com/thumb-2.jpg',
      likes: 64,
      downloads: 11,
      user: cityUser,
      tags: const [Tag(title: 'architecture')],
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

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        photoSearchProvider(const PhotoSearchParams(query: 'forest'))
            .overrideWith(
          (ref) => SearchPhotosResult(
            total: 2431,
            totalPages: 82,
            results: photos,
          ),
        ),
        photoSearchProvider(const PhotoSearchParams(query: 'desert'))
            .overrideWith(
          (ref) => const SearchPhotosResult(
            total: 0,
            totalPages: 0,
            results: [],
          ),
        ),
        photoSearchProvider(
                const PhotoSearchParams(query: 'forest', orderBy: 'latest'))
            .overrideWith(
          (ref) => const SearchPhotosResult(
            total: 2431,
            totalPages: 82,
            results: [],
          ),
        ),
        photoSearchProvider(
                const PhotoSearchParams(query: 'forest', color: 'green'))
            .overrideWith(
          (ref) => SearchPhotosResult(
            total: 2431,
            totalPages: 82,
            results: photos,
          ),
        ),
        photoSearchProvider(const PhotoSearchParams(
                query: 'forest', orientation: 'landscape'))
            .overrideWith(
          (ref) => SearchPhotosResult(
            total: 2431,
            totalPages: 82,
            results: photos,
          ),
        ),
        collectionSearchProvider(
          const CollectionSearchParams(query: 'forest'),
        ).overrideWith(
          (ref) => SearchCollectionsResult(
            total: 324,
            totalPages: 11,
            results: collections,
          ),
        ),
        userSearchProvider(const UserSearchParams(query: 'forest'))
            .overrideWith(
          (ref) => const SearchUsersResult(
            total: 88,
            totalPages: 5,
            results: [forestUser],
          ),
        ),
      ],
      child: const MaterialApp(
        home: SearchPage(initialQuery: 'forest'),
      ),
    );
  }

  testWidgets('SearchPage shows photo results by default', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Photos'), findsWidgets);
    expect(find.text('Collections'), findsWidgets);
    expect(find.text('Users'), findsWidgets);
    expect(find.byKey(const Key('photo-filter-trigger')), findsOneWidget);
    expect(find.text('Forest Archive'), findsOneWidget);
    expect(find.text('No matching photos'), findsNothing);
  });

  testWidgets('SearchPage opens and closes the photo filter panel',
      (tester) async {
    await tester.pumpWidget(buildApp());
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
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Collections').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('photo-filter-trigger')), findsNothing);
    expect(find.text('Forest Archive'), findsOneWidget);
    expect(find.text('by Forest Archive'), findsOneWidget);

    await tester.tap(find.text('Users').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('photo-filter-trigger')), findsNothing);
    expect(find.text('@forest · 12 photos · 3 collections'), findsOneWidget);
    expect(find.text('Shoots outdoors'), findsOneWidget);
    expect(find.text('Following'), findsOneWidget);
  });

  testWidgets('SearchPage shows empty state when query does not match',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'desert');
    await tester.tap(find.byKey(const Key('search-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('No matching photos'), findsOneWidget);
  });

  testWidgets('SearchPage does not search until submit is triggered',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'desert');
    await tester.pumpAndSettle();

    expect(find.text('Forest Archive'), findsOneWidget);
    expect(find.text('No matching photos'), findsNothing);

    await tester.tap(find.byKey(const Key('search-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('No matching photos'), findsOneWidget);
  });
}
