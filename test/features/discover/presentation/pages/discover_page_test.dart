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

class MockPhotoRepository extends Mock implements PhotoRepository {}

class TestTopicListNotifier extends TopicListNotifier {
  final List<Topic> initialTopics;
  TestTopicListNotifier(this.initialTopics);

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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authBootstrapSessionProvider.overrideWithValue(null),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          photosProvider(1).overrideWith((ref) => <Photo>[photo]),
          topicsProvider.overrideWith(() => TestTopicListNotifier(<Topic>[])),
        ],
        child: const MaterialApp(
          home: DiscoverPage(),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Save this to your Musea flow'), findsOneWidget);
    expect(find.text('Continue with Unsplash'), findsOneWidget);

    final containers = tester.widgetList<Container>(find.byType(Container));
    expect(
      containers.any(
        (container) =>
            container.margin == const EdgeInsets.fromLTRB(12, 0, 12, 12),
      ),
      isFalse,
    );
  });

  testWidgets('search bar and filter tabs remain fixed when scrolling photo feed',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authBootstrapSessionProvider.overrideWithValue(null),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          photosProvider(1).overrideWith((ref) => photos),
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

  testWidgets('authenticated like tap calls Unsplash API and toggles state',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MockPhotoRepository();
    final likedPhoto = buildPhoto(likedByUser: true, likes: 81);
    final unlikedPhoto = buildPhoto(likedByUser: false, likes: 80);

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
          photosProvider(1).overrideWith((ref) => <Photo>[photo]),
          topicsProvider.overrideWith(() => TestTopicListNotifier(<Topic>[])),
        ],
        child: const MaterialApp(
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
