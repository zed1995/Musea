import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/features/collections/data/models/collection_model.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/pages/collection_detail_page.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';

void main() {
  const curator = User(
    id: 'user-1',
    username: 'spaciba',
    name: 'Paula Poeira',
    profileImageSmall: 'https://example.com/small.jpg',
    profileImageMedium: 'https://example.com/medium.jpg',
    profileImageLarge: 'https://example.com/large.jpg',
    totalPhotos: 14,
    totalLikes: 10,
    totalCollections: 58,
  );

  testWidgets('CollectionDetailPage renders prototype detail sections',
      (tester) async {
    const collection = Collection(
      id: 'collection-1',
      title: 'United States',
      description: 'Curated travel references.',
      totalPhotos: 316,
      previewPhotos: [],
      user: curator,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionDetailProvider('collection-1').overrideWith(
            (ref) => collection,
          ),
          collectionPhotosProvider('collection-1').overrideWith(
            (ref) => <Photo>[],
          ),
        ],
        child: const MaterialApp(
          home: CollectionDetailPage(collectionId: 'collection-1'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('United States'), findsOneWidget);
    expect(find.text('Collection Summary'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Collection Facts'), findsOneWidget);
    expect(find.text('Follow'), findsOneWidget);
  });

  testWidgets(
      'CollectionDetailPage shows fallback copy when description is missing',
      (tester) async {
    const collection = Collection(
      id: 'collection-2',
      title: 'No Description',
      totalPhotos: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionDetailProvider('collection-2').overrideWith(
            (ref) => collection,
          ),
          collectionPhotosProvider('collection-2').overrideWith(
            (ref) => <Photo>[],
          ),
        ],
        child: const MaterialApp(
          home: CollectionDetailPage(collectionId: 'collection-2'),
        ),
      ),
    );

    await tester.pump();

    expect(find.textContaining('No curator description'), findsOneWidget);
    expect(find.text('No photos in this collection yet'), findsOneWidget);
  });

  testWidgets(
      'CollectionDetailPage treats null privacy values as public safely',
      (tester) async {
    final collection = CollectionModel.fromJson({
      'id': 'collection-3',
      'title': 'Nullable Privacy',
      'total_photos': 0,
      'private': null,
    }).toEntity();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionDetailProvider('collection-3').overrideWith(
            (ref) => collection,
          ),
          collectionPhotosProvider('collection-3').overrideWith(
            (ref) => <Photo>[],
          ),
        ],
        child: const MaterialApp(
          home: CollectionDetailPage(collectionId: 'collection-3'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Public'), findsAtLeastNWidgets(1));
    expect(find.text('Visibility'), findsOneWidget);
  });

  testWidgets(
      'CollectionDetailPage tolerates null numeric fields from detail payload',
      (tester) async {
    final collection = CollectionModel.fromJson({
      'id': 'collection-5',
      'title': 'Sparse Detail',
      'total_photos': null,
      'user': {
        'id': 'user-5',
        'username': 'sparse',
        'name': 'Sparse User',
        'profile_image': {
          'small': 'https://example.com/small.jpg',
          'medium': 'https://example.com/medium.jpg',
          'large': 'https://example.com/large.jpg',
        },
        'total_photos': null,
        'total_likes': null,
        'total_collections': null,
      },
      'cover_photo': {
        'id': 'photo-5',
        'created_at': '2024-01-01T00:00:00Z',
        'width': null,
        'height': null,
        'color': '#FFFFFF',
        'urls': {
          'raw': 'https://example.com/raw.jpg',
          'full': 'https://example.com/full.jpg',
          'regular': 'https://example.com/regular.jpg',
          'small': 'https://example.com/small.jpg',
          'thumb': 'https://example.com/thumb.jpg',
        },
        'likes': null,
        'user': {
          'id': 'user-6',
          'username': 'nested',
          'name': 'Nested User',
          'profile_image': {
            'small': 'https://example.com/small.jpg',
            'medium': 'https://example.com/medium.jpg',
            'large': 'https://example.com/large.jpg',
          },
          'total_photos': null,
          'total_likes': null,
          'total_collections': null,
        },
      },
    }).toEntity();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionDetailProvider('collection-5').overrideWith(
            (ref) => collection,
          ),
          collectionPhotosProvider('collection-5').overrideWith(
            (ref) => <Photo>[],
          ),
        ],
        child: const MaterialApp(
          home: CollectionDetailPage(collectionId: 'collection-5'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Sparse Detail'), findsOneWidget);
    expect(find.text('0 photos'), findsAtLeastNWidgets(1));
    expect(find.text('Sparse User'), findsOneWidget);
  });

  testWidgets('CollectionDetailPage curator area navigates to profile',
      (tester) async {
    const collection = Collection(
      id: 'collection-4',
      title: 'Curator Link',
      totalPhotos: 12,
      user: curator,
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => ProviderScope(
            overrides: [
              collectionDetailProvider('collection-4').overrideWith(
                (ref) => collection,
              ),
              collectionPhotosProvider('collection-4').overrideWith(
                (ref) => <Photo>[],
              ),
            ],
            child: const CollectionDetailPage(collectionId: 'collection-4'),
          ),
        ),
        GoRoute(
          path: '/profile/:username',
          builder: (context, state) => Scaffold(
            body: Text('profile:${state.pathParameters['username']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Paula Poeira'));
    await tester.pumpAndSettle();

    expect(find.text('profile:spaciba'), findsOneWidget);
  });
}
