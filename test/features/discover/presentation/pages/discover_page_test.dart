import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/features/auth/domain/entities/auth_session.dart';
import 'package:musea/features/auth/domain/entities/auth_user.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/repositories/photo_repository.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/discover/presentation/pages/discover_page.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/discover/presentation/providers/topics_provider.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

class MockPhotoRepository extends Mock implements PhotoRepository {}

class TestTopicListNotifier extends TopicListNotifier {
  TestTopicListNotifier(List<Topic> topics) : initialTopics = topics;

  final List<Topic> initialTopics;

  @override
  List<Topic> build() => initialTopics;
}

void main() {
  const user = User(
    id: 'user-1',
    username: 'forest',
    name: 'Forest Archive',
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

  Photo buildPhoto({
    required bool likedByUser,
    required int likes,
  }) {
    return Photo(
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
      likes: likes,
      downloads: 20,
      likedByUser: likedByUser,
      user: user,
    );
  }

  void stubGetPhotos(
    MockPhotoRepository repository, {
    required List<Photo> photos,
  }) {
    when(
      () => repository.getPhotos(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((invocation) async {
      final page = invocation.namedArguments[#page] as int? ?? 1;
      return Right(page == 1 ? photos : <Photo>[]);
    });
  }

  final session = AuthSession(
    accessToken: 'access-token',
    tokenType: 'bearer',
    scope: 'public read_user write_likes',
    createdAt: 1,
    user: const AuthUser(
      id: 'me',
      username: 'musea',
      displayName: 'Musea User',
      profileImageMedium: 'https://example.com/me.jpg',
      totalPhotos: 1,
      totalLikes: 1,
      totalCollections: 1,
    ),
    lastProfileRefreshAt: DateTime(2024, 1, 1),
  );

  testWidgets('unauthenticated like tap opens sign-in sheet', (tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MockPhotoRepository();
    stubGetPhotos(repository, photos: [photo]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authBootstrapSessionProvider.overrideWithValue(null),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          photoRepositoryProvider.overrideWithValue(repository),
          topicsProvider.overrideWith(() => TestTopicListNotifier(<Topic>[])),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DiscoverPage(),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sign in to like photos'), findsOneWidget);
    expect(
      find.text(
        'Save what moves you, keep your visual trail together, and sync every like with your Unsplash account.',
      ),
      findsOneWidget,
    );
    expect(find.text('Liked photos'), findsOneWidget);
    expect(find.text('Save for later'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    expect(find.text('Continue with Unsplash'), findsAtLeastNWidgets(2));

    final sheetContainer = tester.widgetList<Container>(find.byType(Container)).firstWhere(
      (widget) {
        final padding = widget.padding;
        final decoration = widget.decoration;
        return padding is EdgeInsets &&
            padding.left == 16 &&
            padding.top == 10 &&
            padding.right == 16 &&
            decoration is BoxDecoration &&
            decoration.borderRadius ==
                const BorderRadius.vertical(top: Radius.circular(28));
      },
    );
    expect((sheetContainer.padding as EdgeInsets).bottom, 0);

    final containers = tester.widgetList<Container>(find.byType(Container));
    expect(
      containers.any(
        (container) =>
            container.margin == const EdgeInsets.fromLTRB(12, 0, 12, 12),
      ),
      isFalse,
    );
  });

  testWidgets(
      'search bar and filter tabs remain fixed when scrolling photo feed',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MockPhotoRepository();
    final photos = List.generate(
      10,
      (i) => Photo(
        id: 'photo-$i',
        createdAt: DateTime(2024, 1, 1),
        width: 1200,
        height: 1600,
        color: '#AABBCC',
        description: 'Photo $i',
        altDescription: 'Description $i',
        urlRaw: 'https://example.com/$i/raw.jpg',
        urlFull: 'https://example.com/$i/full.jpg',
        urlRegular: 'https://example.com/$i/regular.jpg',
        urlSmall: 'https://example.com/$i/small.jpg',
        urlThumb: 'https://example.com/$i/thumb.jpg',
        likes: 80,
        downloads: 20,
        user: user,
      ),
    );
    stubGetPhotos(repository, photos: photos);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authBootstrapSessionProvider.overrideWithValue(null),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          photoRepositoryProvider.overrideWithValue(repository),
          topicsProvider.overrideWith(() => TestTopicListNotifier([
                const Topic(
                  slug: 'nature',
                  title: 'Nature',
                  id: '1',
                  totalPhotos: 10,
                ),
              ])),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DiscoverPage(),
        ),
      ),
    );

    await tester.pump();

    // Guard: ensure the search header rendered before testing scroll behavior
    expect(find.byIcon(Icons.search), findsOneWidget);

    // Scroll down the CustomScrollView
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The search bar and filter tabs must still be in the widget tree
    // after scrolling (they should NOT scroll off screen).
    // In the RED (broken) layout, the sliver lazy-rebuilds and they disappear.
    expect(find.byIcon(Icons.search), findsOneWidget,
        reason: 'Search bar should remain visible after scrolling');
    expect(find.text('All'), findsOneWidget,
        reason: 'Filter tabs should remain visible after scrolling');
  });

  testWidgets(
      'switching topic does not auto-paginate from previous scroll position',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MockPhotoRepository();
    final allPhotos = List.generate(
      12,
      (i) => Photo(
        id: 'all-$i',
        createdAt: DateTime(2024, 1, 1),
        width: 1200,
        height: 1600,
        color: '#AABBCC',
        description: 'All photo $i',
        altDescription: 'All description $i',
        urlRaw: 'https://example.com/all-$i/raw.jpg',
        urlFull: 'https://example.com/all-$i/full.jpg',
        urlRegular: 'https://example.com/all-$i/regular.jpg',
        urlSmall: 'https://example.com/all-$i/small.jpg',
        urlThumb: 'https://example.com/all-$i/thumb.jpg',
        likes: 80,
        downloads: 20,
        user: user,
      ),
    );
    final topicPhotos = <Photo>[
      Photo(
        id: 'nature-1',
        createdAt: DateTime(2024, 1, 1),
        width: 1200,
        height: 1600,
        color: '#99CC88',
        description: 'Nature photo',
        altDescription: 'Nature description',
        urlRaw: 'https://example.com/nature/raw.jpg',
        urlFull: 'https://example.com/nature/full.jpg',
        urlRegular: 'https://example.com/nature/regular.jpg',
        urlSmall: 'https://example.com/nature/small.jpg',
        urlThumb: 'https://example.com/nature/thumb.jpg',
        likes: 40,
        downloads: 10,
        user: user,
      ),
    ];

    when(
      () => repository.getPhotos(
          page: any(named: 'page'), perPage: any(named: 'perPage')),
    ).thenAnswer((invocation) async {
      final page = invocation.namedArguments[#page] as int? ?? 1;
      return Right(page == 1 ? allPhotos : <Photo>[]);
    });
    when(
      () => repository.getTopicPhotos(
        'nature',
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((invocation) async {
      final page = invocation.namedArguments[#page] as int? ?? 1;
      return Right(page == 1 ? topicPhotos : <Photo>[]);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authBootstrapSessionProvider.overrideWithValue(null),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          photoRepositoryProvider.overrideWithValue(repository),
          topicsProvider.overrideWith(
            () => TestTopicListNotifier([
              const Topic(
                slug: 'nature',
                title: 'Nature',
                id: '1',
                totalPhotos: 10,
              ),
            ]),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DiscoverPage(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DiscoverPage)),
    );
    await container.read(discoverFeedProvider(null).notifier).loadMore();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Nature'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verifyNever(
      () => repository.getTopicPhotos(
        'nature',
        page: 2,
        perPage: any(named: 'perPage'),
      ),
    );
  });

  testWidgets('switching tabs preserves each feed data independently',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MockPhotoRepository();
    final allPageOne = List.generate(
      10,
      (i) => Photo(
        id: 'all-$i',
        createdAt: DateTime(2024, 1, 1),
        width: 1200,
        height: 1600,
        color: '#AABBCC',
        description: 'All photo $i',
        altDescription: 'All description $i',
        urlRaw: 'https://example.com/all-$i/raw.jpg',
        urlFull: 'https://example.com/all-$i/full.jpg',
        urlRegular: 'https://example.com/all-$i/regular.jpg',
        urlSmall: 'https://example.com/all-$i/small.jpg',
        urlThumb: 'https://example.com/all-$i/thumb.jpg',
        likes: 80,
        downloads: 20,
        user: user,
      ),
    );
    final allPageTwo = <Photo>[
      Photo(
        id: 'all-10',
        createdAt: DateTime(2024, 1, 1),
        width: 1200,
        height: 1600,
        color: '#AACCEE',
        description: 'All photo 10',
        altDescription: 'All description 10',
        urlRaw: 'https://example.com/all-10/raw.jpg',
        urlFull: 'https://example.com/all-10/full.jpg',
        urlRegular: 'https://example.com/all-10/regular.jpg',
        urlSmall: 'https://example.com/all-10/small.jpg',
        urlThumb: 'https://example.com/all-10/thumb.jpg',
        likes: 10,
        downloads: 2,
        user: user,
      ),
    ];
    final naturePhotos = <Photo>[
      Photo(
        id: 'nature-1',
        createdAt: DateTime(2024, 1, 1),
        width: 1200,
        height: 1600,
        color: '#99CC88',
        description: 'Nature photo',
        altDescription: 'Nature description',
        urlRaw: 'https://example.com/nature/raw.jpg',
        urlFull: 'https://example.com/nature/full.jpg',
        urlRegular: 'https://example.com/nature/regular.jpg',
        urlSmall: 'https://example.com/nature/small.jpg',
        urlThumb: 'https://example.com/nature/thumb.jpg',
        likes: 40,
        downloads: 10,
        user: user,
      ),
    ];

    when(
      () => repository.getPhotos(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((invocation) async {
      final page = invocation.namedArguments[#page] as int? ?? 1;
      if (page == 1) return Right(allPageOne);
      if (page == 2) return Right(allPageTwo);
      return const Right(<Photo>[]);
    });
    when(
      () => repository.getTopicPhotos(
        'nature',
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(naturePhotos));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authBootstrapSessionProvider.overrideWithValue(null),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          photoRepositoryProvider.overrideWithValue(repository),
          topicsProvider.overrideWith(
            () => TestTopicListNotifier([
              const Topic(
                slug: 'nature',
                title: 'Nature',
                id: '1',
                totalPhotos: 10,
              ),
            ]),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DiscoverPage(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DiscoverPage)),
    );
    await container.read(discoverFeedProvider(null).notifier).loadMore();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    verify(() => repository.getPhotos(page: 2, perPage: any(named: 'perPage')))
        .called(1);
    clearInteractions(repository);

    await tester.tap(find.text('Nature'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    verify(
      () => repository.getTopicPhotos(
        'nature',
        page: 1,
        perPage: any(named: 'perPage'),
      ),
    ).called(1);

    await tester.tap(find.text('All'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verifyNever(
      () => repository.getPhotos(page: 2, perPage: any(named: 'perPage')),
    );
  });

  testWidgets('authenticated like tap calls Unsplash API and toggles state',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MockPhotoRepository();
    final likedPhoto = buildPhoto(likedByUser: true, likes: 81);
    final unlikedPhoto = buildPhoto(likedByUser: false, likes: 80);
    stubGetPhotos(repository, photos: [photo]);

    when(
      () => repository.likePhoto('photo-1'),
    ).thenAnswer((_) async => Right(likedPhoto));
    when(
      () => repository.unlikePhoto('photo-1'),
    ).thenAnswer((_) async => Right(unlikedPhoto));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authBootstrapSessionProvider.overrideWithValue(session),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          photoRepositoryProvider.overrideWithValue(repository),
          topicsProvider.overrideWith(() => TestTopicListNotifier(<Topic>[])),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DiscoverPage(),
        ),
      ),
    );

    await tester.pump();

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.text('80'), findsOneWidget);

    await tester.ensureVisible(find.byIcon(Icons.favorite_border));
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();

    verify(
      () => repository.likePhoto('photo-1'),
    ).called(1);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.text('81'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pump();

    verify(
      () => repository.unlikePhoto('photo-1'),
    ).called(1);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.text('80'), findsOneWidget);
  });
}
