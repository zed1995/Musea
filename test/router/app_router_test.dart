import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/app.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/pages/collection_detail_page.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/discover/presentation/providers/topics_provider.dart';
import 'package:musea/features/photo_detail/presentation/pages/photo_detail_page.dart';
import 'package:musea/features/photo_detail/presentation/pages/photo_viewer_page.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/router/detail_route_extras.dart';

void main() {
  const user = User(
    id: 'user-1',
    username: 'forest',
    name: 'Forest Archive',
    bio: 'Shoots outdoors',
    location: 'Portland',
    profileImageSmall: 'https://example.com/small.jpg',
    profileImageMedium: 'https://example.com/medium.jpg',
    profileImageLarge: 'https://example.com/large.jpg',
    totalPhotos: 12,
    totalLikes: 44,
    totalCollections: 3,
  );

  final photo = Photo(
    id: 'photo-1',
    createdAt: DateTime(2024, 1, 1),
    width: 1200,
    height: 1600,
    color: '#AABBCC',
    description: 'Forest canopy',
    altDescription: 'Green trees',
    urlRaw: 'https://example.com/raw.jpg',
    urlFull: 'https://example.com/full.jpg',
    urlRegular: 'https://example.com/regular.jpg',
    urlSmall: 'https://example.com/small.jpg',
    urlThumb: 'https://example.com/thumb.jpg',
    likes: 80,
    downloads: 20,
    user: user,
  );

  const collection = Collection(
    id: 'collection-1',
    title: 'Forest Archive',
    description: 'Curated woodland work',
    totalPhotos: 12,
    user: user,
  );

  testWidgets(
      'home keeps discover route and bottom nav shows discover collections and mine',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photosProvider(1).overrideWith((ref) => <Photo>[photo]),
          topicsProvider.overrideWith((ref) => <Topic>[]),
          collectionsProvider(1).overrideWith((ref) => <Collection>[]),
        ],
        child: const MuseaApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Collections'), findsOneWidget);
    expect(find.text('Mine'), findsOneWidget);
    expect(find.text('Search photos, collections, users...'), findsOneWidget);
  });

  testWidgets('tapping the home search entry opens the full search page',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photosProvider(1).overrideWith((ref) => <Photo>[photo]),
          topicsProvider.overrideWith((ref) => <Topic>[]),
          collectionsProvider(1).overrideWith((ref) => <Collection>[]),
        ],
        child: const MuseaApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Search photos, collections, users...'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Photos'), findsWidgets);
    expect(find.text('Users'), findsWidgets);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
  });

  testWidgets('router forwards photo and collection extras into detail pages',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photosProvider(1).overrideWith((ref) => <Photo>[photo]),
          photoDetailProvider('photo-1').overrideWith((ref) => photo),
          topicsProvider.overrideWith((ref) => <Topic>[]),
          collectionsProvider(1).overrideWith((ref) => <Collection>[]),
          userProfileProvider('forest').overrideWith((ref) => user),
          userPhotosProvider('forest').overrideWith((ref) => <Photo>[photo]),
          userCollectionsProvider('forest')
              .overrideWith((ref) => <Collection>[collection]),
          userLikesProvider('forest').overrideWith((ref) => <Photo>[]),
          collectionDetailProvider('collection-1')
              .overrideWith((ref) => collection),
          collectionPhotosProvider('collection-1')
              .overrideWith((ref) => <Photo>[]),
        ],
        child: const MuseaApp(),
      ),
    );

    final appContext =
        tester.element(find.text('Search photos, collections, users...'));
    GoRouter.of(appContext).go(
      '/photo/${photo.id}',
      extra: PhotoDetailExtra(photo: photo),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final photoPage = tester.widget<PhotoDetailPage>(
      find.byType(PhotoDetailPage),
    );
    expect(photoPage.photoId, photo.id);
    expect(photoPage.initialPhoto, same(photo));
    expect(find.text('Forest Archive'), findsOneWidget);

    GoRouter.of(appContext).go(
      '/collection/${collection.id}',
      extra: const CollectionDetailExtra(collection: collection),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final collectionPage = tester.widget<CollectionDetailPage>(
      find.byType(CollectionDetailPage),
    );
    expect(collectionPage.collectionId, collection.id);
    expect(collectionPage.initialCollection, same(collection));
    expect(find.text('Forest Archive'), findsWidgets);
  });

  testWidgets('router forwards photo extra into photo viewer page',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photosProvider(1).overrideWith((ref) => <Photo>[photo]),
          photoDetailProvider('photo-1').overrideWith((ref) => photo),
          topicsProvider.overrideWith((ref) => <Topic>[]),
          collectionsProvider(1).overrideWith((ref) => <Collection>[]),
          userProfileProvider('forest').overrideWith((ref) => user),
          userPhotosProvider('forest').overrideWith((ref) => <Photo>[photo]),
          userCollectionsProvider('forest')
              .overrideWith((ref) => <Collection>[collection]),
          userLikesProvider('forest').overrideWith((ref) => <Photo>[]),
        ],
        child: const MuseaApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    final appContext = tester.element(find.byType(Scaffold).first);
    GoRouter.of(appContext).go(
      '/photo/${photo.id}/viewer',
      extra: PhotoViewerExtra(photo: photo),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final viewerPage = tester.widget<PhotoViewerPage>(
      find.byType(PhotoViewerPage),
    );
    expect(viewerPage.initialPhoto, same(photo));
    expect(viewerPage.photoId, photo.id);
  });
}
