import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/collections/data/models/collection_model.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/pages/collection_detail_page.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/follow/presentation/widgets/follow_button.dart';
import 'package:musea/shared/widgets/photo_grid.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

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

  Photo buildPhoto({
    required String id,
    required String name,
    int likes = 40,
    bool likedByUser = false,
  }) {
    return Photo(
      id: id,
      createdAt: DateTime(2024, 1, 1),
      width: 1200,
      height: 1600,
      color: '#FFFFFF',
      urlRaw: 'https://example.com/$id-raw.jpg',
      urlFull: 'https://example.com/$id-full.jpg',
      urlRegular: 'https://example.com/$id-regular.jpg',
      urlSmall: 'https://example.com/$id-small.jpg',
      urlThumb: 'https://example.com/$id-thumb.jpg',
      likes: likes,
      downloads: 0,
      likedByUser: likedByUser,
      user: const User(
        id: 'photo-user',
        username: 'photo-user',
        name: 'Alex Lamb',
        profileImageSmall: 'https://example.com/p-small.jpg',
        profileImageMedium: 'https://example.com/p-medium.jpg',
        profileImageLarge: 'https://example.com/p-large.jpg',
        totalPhotos: 12,
        totalLikes: 20,
        totalCollections: 3,
      ),
      altDescription: name,
    );
  }

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
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          currentAuthStateProvider.overrideWithValue(const AuthState()),
          collectionDetailProvider('collection-1').overrideWith(
            (ref) => collection,
          ),
          collectionPhotosProvider('collection-1').overrideWith(
            (ref) => <Photo>[],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CollectionDetailPage(collectionId: 'collection-1'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('United States'), findsAtLeastNWidgets(1));
    expect(find.text('Collection Summary'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Collection Facts'), findsOneWidget);
    expect(find.text('Follow'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
  });

  testWidgets('CollectionDetailPage share icon opens share action sheet',
      (tester) async {
    const collection = Collection(
      id: 'collection-share',
      title: 'United States',
      description: 'Curated travel references.',
      totalPhotos: 316,
      links: CollectionLinks(
        html: 'https://unsplash.com/collections/2208769/united-states',
      ),
      user: curator,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          currentAuthStateProvider.overrideWithValue(const AuthState()),
          collectionDetailProvider('collection-share').overrideWith(
            (ref) => collection,
          ),
          collectionPhotosProvider('collection-share').overrideWith(
            (ref) => <Photo>[],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CollectionDetailPage(collectionId: 'collection-share'),
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.byIcon(Icons.ios_share_rounded));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.share), findsOneWidget);
    expect(find.text(l10n.copyLink), findsOneWidget);
  });

  testWidgets(
      'CollectionDetailPage shows missing-link feedback from share sheet',
      (tester) async {
    const collection = Collection(
      id: 'collection-missing-link',
      title: 'United States',
      description: 'Curated travel references.',
      totalPhotos: 316,
      user: curator,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          currentAuthStateProvider.overrideWithValue(const AuthState()),
          collectionDetailProvider('collection-missing-link').overrideWith(
            (ref) => collection,
          ),
          collectionPhotosProvider('collection-missing-link').overrideWith(
            (ref) => <Photo>[],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CollectionDetailPage(collectionId: 'collection-missing-link'),
        ),
      ),
    );

    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.byIcon(Icons.ios_share_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.copyLink));
    await tester.pumpAndSettle();

    expect(find.text(l10n.shareUnavailable), findsOneWidget);
  });

  testWidgets(
      'CollectionDetailPage renders initial collection immediately while detail hydrates',
      (tester) async {
    final pending = Completer<Collection>();
    const initialCollection = Collection(
      id: 'collection-progressive',
      title: 'United States',
      description: 'Curated travel references.',
      totalPhotos: 316,
      user: curator,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          currentAuthStateProvider.overrideWithValue(const AuthState()),
          collectionDetailProvider('collection-progressive').overrideWith(
            (ref) => pending.future,
          ),
          collectionPhotosProvider('collection-progressive').overrideWith(
            (ref) => <Photo>[],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CollectionDetailPage(
            collectionId: 'collection-progressive',
            initialCollection: initialCollection,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('United States'), findsAtLeastNWidgets(1));
    expect(find.text('Curated travel references.'), findsOneWidget);
    expect(find.byType(PhotoGrid), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.byKey(const ValueKey('collection-detail-preview-skeleton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('collection-detail-facts-skeleton')),
      findsOneWidget,
    );
  });

  testWidgets(
      'CollectionDetailPage deep link without initial collection keeps full-page loading and error states',
      (tester) async {
    final pending = Completer<Collection>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          currentAuthStateProvider.overrideWithValue(const AuthState()),
          collectionDetailProvider('collection-deep-link').overrideWith(
            (ref) => pending.future,
          ),
          collectionPhotosProvider('collection-deep-link').overrideWith(
            (ref) => <Photo>[],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CollectionDetailPage(collectionId: 'collection-deep-link'),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(Center), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.completeError(Exception('detail failed'));
    await tester.pumpAndSettle();

    expect(find.textContaining('detail failed'), findsOneWidget);
    expect(find.text('Collection Summary'), findsNothing);
  });

  testWidgets('CollectionDetailPage back button is safe when route cannot pop',
      (tester) async {
    const collection = Collection(
      id: 'collection-root',
      title: 'Root Entry',
      description: 'Opened directly',
      totalPhotos: 12,
      user: curator,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          currentAuthStateProvider.overrideWithValue(const AuthState()),
          collectionDetailProvider('collection-root').overrideWith(
            (ref) => collection,
          ),
          collectionPhotosProvider('collection-root').overrideWith(
            (ref) => <Photo>[],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CollectionDetailPage(collectionId: 'collection-root'),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Root Entry'), findsAtLeastNWidgets(1));
  });

  testWidgets(
      'CollectionDetailPage keeps initial content and shows deferred detail retry when hydration fails',
      (tester) async {
    const initialCollection = Collection(
      id: 'collection-error',
      title: 'United States',
      description: 'Curated travel references.',
      totalPhotos: 316,
      user: curator,
    );

    var attempts = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          currentAuthStateProvider.overrideWithValue(const AuthState()),
          collectionDetailProvider('collection-error')
              .overrideWith((ref) async {
            attempts++;
            throw Exception('detail failed');
          }),
          collectionPhotosProvider('collection-error').overrideWith(
            (ref) => [
              buildPhoto(id: 'photo-1', name: 'Feed photo'),
            ],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CollectionDetailPage(
            collectionId: 'collection-error',
            initialCollection: initialCollection,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('United States'), findsAtLeastNWidgets(1));
    expect(find.text('Curated travel references.'), findsOneWidget);
    expect(find.text('Inside the collection'), findsOneWidget);
    expect(find.byType(PhotoGrid), findsOneWidget);
    expect(find.text('Retry loading details'), findsAtLeastNWidgets(1));

    final retryButton = tester.widgetList<TextButton>(
      find.widgetWithText(TextButton, 'Retry loading details'),
    );
    retryButton.first.onPressed!.call();
    await tester.pump();
    await tester.pump();

    expect(attempts, greaterThan(1));
  });

  testWidgets(
      'CollectionDetailPage replaces deferred UI when hydrated detail succeeds',
      (tester) async {
    final pending = Completer<Collection>();
    const initialCollection = Collection(
      id: 'collection-hydrate-success',
      title: 'United States',
      description: 'Curated travel references.',
      totalPhotos: 316,
      user: curator,
    );
    final hydratedCollection = Collection(
      id: 'collection-hydrate-success',
      title: 'United States',
      description: 'Curated travel references.',
      totalPhotos: 316,
      publishedAt: DateTime(2024, 1, 2),
      updatedAt: DateTime(2024, 1, 3),
      lastCollectedAt: DateTime(2024, 1, 4),
      previewPhotos: [
        const PreviewPhoto(
          id: 'preview-1',
          thumbUrl: 'https://example.com/p1-thumb.jpg',
          smallUrl: 'https://example.com/p1-small.jpg',
          regularUrl: 'https://example.com/p1-regular.jpg',
        ),
      ],
      user: curator,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          currentAuthStateProvider.overrideWithValue(const AuthState()),
          collectionDetailProvider('collection-hydrate-success').overrideWith(
            (ref) => pending.future,
          ),
          collectionPhotosProvider('collection-hydrate-success').overrideWith(
            (ref) => <Photo>[],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CollectionDetailPage(
            collectionId: 'collection-hydrate-success',
            initialCollection: initialCollection,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(
      find.byKey(const ValueKey('collection-detail-preview-skeleton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('collection-detail-facts-skeleton')),
      findsOneWidget,
    );

    pending.complete(hydratedCollection);
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('collection-detail-preview-skeleton')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('collection-detail-facts-skeleton')),
      findsNothing,
    );
    expect(find.text('Preview unavailable until details finish loading.'),
        findsNothing);
    expect(find.text('Retry loading details'), findsNothing);
    expect(find.text('Published'), findsOneWidget);
    expect(find.text('Jan 2, 2024'), findsAtLeastNWidgets(1));
  });

  testWidgets(
      'CollectionDetailPage shows preview deferred fallback while photo feed stays independent on hydration failure',
      (tester) async {
    const initialCollection = Collection(
      id: 'collection-preview-error',
      title: 'United States',
      description: 'Curated travel references.',
      totalPhotos: 316,
      user: curator,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          currentAuthStateProvider.overrideWithValue(const AuthState()),
          collectionDetailProvider('collection-preview-error')
              .overrideWith((ref) async {
            throw Exception('detail failed');
          }),
          collectionPhotosProvider('collection-preview-error').overrideWith(
            (ref) => [
              buildPhoto(id: 'photo-1', name: 'Feed first'),
              buildPhoto(id: 'photo-2', name: 'Feed second'),
            ],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CollectionDetailPage(
            collectionId: 'collection-preview-error',
            initialCollection: initialCollection,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('First four photos'), findsOneWidget);
    expect(find.text('Preview unavailable until details finish loading.'),
        findsOneWidget);
    expect(
        find.text('Preview will appear when photos are added'), findsNothing);
    expect(find.text('Inside the collection'), findsOneWidget);
    expect(find.byType(PhotoGrid), findsOneWidget);
    expect(find.byType(PhotoGridTile), findsNWidgets(2));
  });

  testWidgets('CollectionDetailPage feed error retry invalidates photo feed',
      (tester) async {
    const collection = Collection(
      id: 'collection-feed-retry',
      title: 'Feed Retry',
      totalPhotos: 316,
      user: curator,
    );
    var attempts = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          currentAuthStateProvider.overrideWithValue(const AuthState()),
          collectionDetailProvider('collection-feed-retry').overrideWith(
            (ref) => collection,
          ),
          collectionPhotosProvider('collection-feed-retry').overrideWith(
            (ref) async {
              attempts++;
              throw Exception('feed failed');
            },
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CollectionDetailPage(collectionId: 'collection-feed-retry'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.textContaining('feed failed'), findsOneWidget);

    final retryButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Try Again'),
    );
    retryButton.onPressed!.call();
    await tester.pump();
    await tester.pump();

    expect(attempts, greaterThan(1));
  });

  testWidgets(
      'CollectionDetailPage renders continue exploring and shared double-column feed',
      (tester) async {
    const collection = Collection(
      id: 'collection-feed',
      title: 'United States',
      totalPhotos: 316,
      user: curator,
    );
    final photos = [
      buildPhoto(id: 'photo-1', name: 'Featured', likes: 40),
      buildPhoto(id: 'photo-2', name: 'Second', likes: 156),
      buildPhoto(id: 'photo-3', name: 'Third', likes: 97),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          currentAuthStateProvider.overrideWithValue(const AuthState()),
          collectionDetailProvider('collection-feed').overrideWith(
            (ref) => collection,
          ),
          collectionPhotosProvider('collection-feed').overrideWith(
            (ref) => photos,
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CollectionDetailPage(collectionId: 'collection-feed'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Continue Exploring'), findsOneWidget);
    expect(find.text('Explore nearby themes first'), findsOneWidget);
    expect(find.text('Inside the collection'), findsOneWidget);
    expect(find.byType(PhotoGrid), findsOneWidget);
    expect(find.byType(PhotoGridTile), findsNWidgets(3));
    expect(find.byIcon(Icons.favorite_border_rounded), findsNWidgets(3));
    expect(find.text('156'), findsOneWidget);
  });

  testWidgets(
      'CollectionDetailPage shows filled red like chip for liked photos',
      (tester) async {
    const collection = Collection(
      id: 'collection-liked-feed',
      title: 'Liked Feed',
      totalPhotos: 1,
      user: curator,
    );
    final photos = [
      buildPhoto(
        id: 'photo-liked',
        name: 'Liked',
        likes: 40,
        likedByUser: true,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          currentAuthStateProvider.overrideWithValue(const AuthState()),
          collectionDetailProvider('collection-liked-feed').overrideWith(
            (ref) => collection,
          ),
          collectionPhotosProvider('collection-liked-feed').overrideWith(
            (ref) => photos,
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CollectionDetailPage(collectionId: 'collection-liked-feed'),
        ),
      ),
    );

    await tester.pump();

    final likeIcon = tester.widget<Icon>(find.byIcon(Icons.favorite));

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    expect(likeIcon.color, const Color(0xFFE11D48));
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
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          currentAuthStateProvider.overrideWithValue(const AuthState()),
          collectionDetailProvider('collection-2').overrideWith(
            (ref) => collection,
          ),
          collectionPhotosProvider('collection-2').overrideWith(
            (ref) => <Photo>[],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          currentAuthStateProvider.overrideWithValue(const AuthState()),
          collectionDetailProvider('collection-3').overrideWith(
            (ref) => collection,
          ),
          collectionPhotosProvider('collection-3').overrideWith(
            (ref) => <Photo>[],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          currentAuthStateProvider.overrideWithValue(const AuthState()),
          collectionDetailProvider('collection-5').overrideWith(
            (ref) => collection,
          ),
          collectionPhotosProvider('collection-5').overrideWith(
            (ref) => <Photo>[],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CollectionDetailPage(collectionId: 'collection-5'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Sparse Detail'), findsAtLeastNWidgets(1));
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
              authRedirectUriProvider.overrideWithValue(
                Uri.parse('musea://auth/callback'),
              ),
              currentAuthStateProvider.overrideWithValue(const AuthState()),
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Paula Poeira'));
    await tester.pumpAndSettle();

    expect(find.text('profile:spaciba'), findsOneWidget);
  });

  testWidgets(
      'CollectionDetailPage shows FollowButton for non-self curator in the hero',
      (tester) async {
    const collection = Collection(
      id: 'collection-follow',
      title: 'Followable Curator',
      totalPhotos: 4,
      user: curator,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          authBootstrapSessionProvider.overrideWithValue(null),
          currentAuthStateProvider.overrideWithValue(const AuthState()),
          collectionDetailProvider('collection-follow').overrideWith(
            (ref) => collection,
          ),
          collectionPhotosProvider('collection-follow').overrideWith(
            (ref) => <Photo>[],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CollectionDetailPage(collectionId: 'collection-follow'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FollowButton), findsOneWidget);
  });
}
