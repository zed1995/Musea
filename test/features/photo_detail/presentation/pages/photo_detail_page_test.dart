import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/features/auth/domain/entities/auth_session.dart';
import 'package:musea/features/auth/domain/entities/auth_user.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/repositories/photo_repository.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/photo_detail/presentation/pages/photo_detail_page.dart';
import 'package:musea/features/photo_detail/presentation/pages/photo_viewer_page.dart';
import 'package:musea/features/photo_detail/presentation/widgets/color_palette_bar.dart';
import 'package:musea/features/follow/presentation/widgets/follow_button.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/l10n/generated/app_localizations.dart';
import 'package:musea/router/detail_route_extras.dart';
import 'package:musea/shared/widgets/immersive_hero_app_bar.dart';

class MockPhotoRepository extends Mock implements PhotoRepository {}

void main() {
  Photo buildPhoto({
    required String id,
    required String username,
    required String name,
    required String color,
    List<Map<String, String>> tags = const [],
    String make = 'Sony',
    String model = 'A7 III',
    bool likedByUser = false,
    int likes = 1284,
  }) {
    return PhotoModel.fromJson({
      'id': id,
      'created_at': '2024-01-01T00:00:00Z',
      'width': 1200,
      'height': 1600,
      'color': color,
      'description': 'Quiet light',
      'urls': {
        'raw': 'https://example.com/$id-raw.jpg',
        'full': 'https://example.com/$id-full.jpg',
        'regular': 'https://example.com/$id-regular.jpg',
        'small': 'https://example.com/$id-small.jpg',
        'thumb': 'https://example.com/$id-thumb.jpg',
      },
      'likes': likes,
      'liked_by_user': likedByUser,
      'downloads': 12000,
      'views': 52300,
      'user': {
        'id': 'user-$id',
        'username': username,
        'name': name,
        'profile_image': {
          'small': 'https://example.com/small-profile.jpg',
          'medium': 'https://example.com/medium-profile.jpg',
          'large': 'https://example.com/large-profile.jpg',
        },
        'total_photos': 20,
        'total_likes': 30,
        'total_collections': 2,
      },
      'exif': {
        'make': make,
        'model': model,
        'aperture': '2.8',
        'exposure_time': '1/250',
        'focal_length': '35mm',
        'iso': 400,
      },
      'location': {
        'city': 'Kyoto',
        'country': 'Japan',
        'position': {
          'latitude': 35.0116,
          'longitude': 135.7681,
        },
      },
      'tags': tags,
    }).toEntity();
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

  testWidgets(
      'PhotoDetailPage tolerates null numeric fields from detail payload',
      (tester) async {
    final photo = PhotoModel.fromJson({
      'id': 'photo-1',
      'created_at': '2024-01-01T00:00:00Z',
      'width': null,
      'height': null,
      'color': '#FFFFFF',
      'description': 'Quiet light',
      'urls': {
        'raw': 'https://example.com/raw.jpg',
        'full': 'https://example.com/full.jpg',
        'regular': 'https://example.com/regular.jpg',
        'small': 'https://example.com/small.jpg',
        'thumb': 'https://example.com/thumb.jpg',
      },
      'likes': null,
      'downloads': null,
      'views': null,
      'user': {
        'id': 'user-1',
        'username': 'paula',
        'name': 'Paula Poeira',
        'profile_image': {
          'small': 'https://example.com/small-profile.jpg',
          'medium': 'https://example.com/medium-profile.jpg',
          'large': 'https://example.com/large-profile.jpg',
        },
        'total_photos': null,
        'total_likes': null,
        'total_collections': null,
      },
      'exif': {
        'make': 'VeryLongCameraBrandName',
        'model': 'SuperDetailedMirrorlessBodyEdition',
        'iso': null,
      },
      'location': {
        'city': 'Paris',
        'country': 'France',
        'position': {
          'latitude': null,
          'longitude': null,
        },
      },
      'tags': const [
        {'title': 'editorial'}
      ],
    }).toEntity();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider('photo-1').overrideWith((ref) => photo),
          userPhotosProvider('paula').overrideWith((ref) => <Photo>[]),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoDetailPage(photoId: 'photo-1'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Paula Poeira'), findsOneWidget);
    expect(find.text('Quiet light'), findsAtLeastNWidgets(1));
    expect(find.text('Download Free'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PhotoDetailPage share icon opens share action sheet',
      (tester) async {
    final photo = buildPhoto(
      id: 'photo-share',
      username: 'paula',
      name: 'Paula Poeira',
      color: '#5B7B9A',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider('photo-share').overrideWith((ref) => photo),
          userPhotosProvider('paula').overrideWith((ref) => <Photo>[]),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoDetailPage(photoId: 'photo-share'),
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.byIcon(Icons.ios_share_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.share), findsOneWidget);
    expect(find.text(l10n.copyLink), findsOneWidget);
  });

  testWidgets('PhotoDetailPage shows missing-link feedback from share sheet',
      (tester) async {
    final photo = buildPhoto(
      id: 'photo-missing-link',
      username: 'paula',
      name: 'Paula Poeira',
      color: '#5B7B9A',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider('photo-missing-link').overrideWith((ref) => photo),
          userPhotosProvider('paula').overrideWith((ref) => <Photo>[]),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoDetailPage(photoId: 'photo-missing-link'),
        ),
      ),
    );

    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.byIcon(Icons.ios_share_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text(l10n.copyLink));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text(l10n.shareUnavailable), findsOneWidget);
  });

  testWidgets(
      'PhotoDetailPage renders color palette and long exif can open full text',
      (tester) async {
    final photo = buildPhoto(
      id: 'photo-main',
      username: 'paula',
      name: 'Paula Poeira',
      color: '#5B7B9A',
      tags: const [
        {'title': 'Kyoto'},
        {'title': 'Temple'},
        {'title': 'Autumn'},
      ],
      make: 'VeryLongCameraBrandName',
      model: 'SuperDetailedMirrorlessBodyEdition',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider('photo-main').overrideWith((ref) => photo),
          userPhotosProvider('paula').overrideWith((ref) => <Photo>[]),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoDetailPage(photoId: 'photo-main'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('COLOR PALETTE'), findsOneWidget);
    expect(find.byType(ColorPaletteSection), findsOneWidget);

    await tester.tap(
      find
          .text('VeryLongCameraBrandName SuperDetailedMirrorlessBodyEdition')
          .first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('VeryLongCameraBrandName SuperDetailedMirrorlessBodyEdition'),
      findsAtLeastNWidgets(2),
    );
    expect(find.text('Camera'), findsAtLeastNWidgets(2));
  });

  testWidgets('PhotoDetailPage shows filled red like stat for liked photo',
      (tester) async {
    final photo = buildPhoto(
      id: 'photo-liked',
      username: 'paula',
      name: 'Paula Poeira',
      color: '#5B7B9A',
      likedByUser: true,
      likes: 12,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider('photo-liked').overrideWith((ref) => photo),
          userPhotosProvider('paula').overrideWith((ref) => <Photo>[]),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoDetailPage(photoId: 'photo-liked'),
        ),
      ),
    );

    await tester.pump();

    final likeIcon = tester.widget<Icon>(find.byIcon(Icons.favorite));
    final likeButton = find.byKey(const ValueKey('photo-detail-like-button'));
    final likeCount = tester.widget<Text>(
      find.descendant(of: likeButton, matching: find.text('12')),
    );

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
    expect(likeIcon.color, const Color(0xFFE11D48));
    expect(likeCount.style?.color, const Color(0xFF52525B));
  });

  testWidgets('PhotoDetailPage toggles like through Unsplash API',
      (tester) async {
    final repository = MockPhotoRepository();
    final photo = buildPhoto(
      id: 'photo-toggle-like',
      username: 'paula',
      name: 'Paula Poeira',
      color: '#5B7B9A',
      likes: 12,
    );
    final likedPhoto = buildPhoto(
      id: 'photo-toggle-like',
      username: 'paula',
      name: 'Paula Poeira',
      color: '#5B7B9A',
      likes: 13,
      likedByUser: true,
    );
    final unlikedPhoto = buildPhoto(
      id: 'photo-toggle-like',
      username: 'paula',
      name: 'Paula Poeira',
      color: '#5B7B9A',
      likes: 12,
      likedByUser: false,
    );

    when(
      () => repository.likePhoto('photo-toggle-like'),
    ).thenAnswer((_) async => Right(likedPhoto));
    when(
      () => repository.unlikePhoto('photo-toggle-like'),
    ).thenAnswer((_) async => Right(unlikedPhoto));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authBootstrapSessionProvider.overrideWithValue(session),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          photoRepositoryProvider.overrideWithValue(repository),
          photoDetailProvider('photo-toggle-like').overrideWith((ref) => photo),
          userPhotosProvider('paula').overrideWith((ref) => <Photo>[]),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoDetailPage(photoId: 'photo-toggle-like'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('12'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('photo-detail-like-button')).first);
    await tester.pump();

    verify(
      () => repository.likePhoto('photo-toggle-like'),
    ).called(1);
    expect(find.text('13'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('photo-detail-like-button')).first);
    await tester.pump();

    verify(
      () => repository.unlikePhoto('photo-toggle-like'),
    ).called(1);
    expect(find.text('12'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('PhotoDetailPage hero opens photo viewer', (tester) async {
    final photo = buildPhoto(
      id: 'photo-main',
      username: 'paula',
      name: 'Paula Poeira',
      color: '#5B7B9A',
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => PhotoDetailPage(
            photoId: photo.id,
            initialPhoto: photo,
          ),
        ),
        GoRoute(
          path: '/photo/:id/viewer',
          builder: (context, state) {
            final extra = state.extra as PhotoViewerExtra?;
            return PhotoViewerPage(
              photoId: state.pathParameters['id']!,
              initialPhoto: extra!.photo,
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider(photo.id).overrideWith((ref) => photo),
          userPhotosProvider('paula').overrideWith((ref) => <Photo>[]),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.pump();

    await tester
        .tap(find.byKey(const ValueKey('photo-detail-hero-tap-target')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(PhotoViewerPage), findsOneWidget);
    expect(
      find.byKey(const ValueKey('photo-viewer-dismiss-area')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('photo-viewer-image-tap-target')),
      findsOneWidget,
    );
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('PhotoDetailPage tag chip navigates to search page',
      (tester) async {
    final photo = buildPhoto(
      id: 'photo-tags',
      username: 'paula',
      name: 'Paula Poeira',
      color: '#5B7B9A',
      tags: const [
        {'title': 'Kyoto'},
        {'title': 'Temple'},
      ],
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => PhotoDetailPage(
            photoId: photo.id,
            initialPhoto: photo,
          ),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) {
            final query = state.uri.queryParameters['q'] ?? '';
            return Text('SearchPage: $query');
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider(photo.id).overrideWith((ref) => photo),
          userPhotosProvider('paula').overrideWith((ref) => <Photo>[]),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.pump();

    // Verify tags are rendered
    expect(find.text('Kyoto'), findsOneWidget);
    expect(find.text('Temple'), findsOneWidget);

    await tester.tap(find.text('Kyoto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('SearchPage: Kyoto'), findsOneWidget);
  });

  testWidgets('PhotoViewerPage expands image viewport to full screen',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final photo = buildPhoto(
      id: 'photo-viewer',
      username: 'paula',
      name: 'Paula Poeira',
      color: '#5B7B9A',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider(photo.id).overrideWith((ref) => photo),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoViewerPage(
            photoId: photo.id,
            initialPhoto: photo,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const ValueKey('photo-viewer-viewport')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('photo-viewer-viewport'))),
      const Size(390, 844),
    );
  });

  testWidgets('PhotoDetailPage bar background lerps as the hero scrolls out',
      (tester) async {
    // Use the default test surface (800x600 logical) so _MoreFromPhotographer
    // has enough horizontal room. The default viewport is short enough that
    // max scroll exceeds the 320px placeholder hero, so progress can reach 1.0.
    addTearDown(tester.view.reset);

    final photo = buildPhoto(
      id: 'photo-collapse',
      username: 'paula',
      name: 'Paula Poeira',
      color: '#5B7B9A',
      tags: const [
        {'title': 'landscape'},
        {'title': 'mountains'},
        {'title': 'sunset'},
        {'title': 'golden-hour'},
        {'title': 'nature'},
        {'title': 'outdoor'},
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider('photo-collapse')
              .overrideWith((ref) => photo),
          userPhotosProvider('paula').overrideWith((ref) => <Photo>[]),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoDetailPage(photoId: 'photo-collapse'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    ImmersiveHeroAppBar bar() => tester.widget<ImmersiveHeroAppBar>(
          find.byType(ImmersiveHeroAppBar),
        );

    expect(bar().progress, 0.0);
    expect(bar().scrolled, isFalse);

    // Drive the inner scroll position directly so we can land on a known offset
    // regardless of how much content the test photo happens to render.
    final scrollableState = tester.state<ScrollableState>(find.byType(Scrollable));
    scrollableState.position.jumpTo(160);
    await tester.pump();

    expect(bar().progress, closeTo(0.5, 0.05));
    expect(bar().scrolled, isTrue);

    scrollableState.position.jumpTo(320);
    await tester.pump();

    expect(bar().progress, 1.0);
    expect(bar().scrolled, isTrue);
  });

  testWidgets('PhotoDetailPage shows the FollowButton next to the photographer',
      (tester) async {
    final photo = buildPhoto(
      id: 'photo-follow',
      username: 'paula',
      name: 'Paula Poeira',
      color: '#5B7B9A',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authBootstrapSessionProvider.overrideWithValue(null),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          photoDetailProvider('photo-follow').overrideWith((ref) => photo),
          userPhotosProvider('paula').overrideWith((ref) => <Photo>[]),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoDetailPage(photoId: 'photo-follow'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(FollowButton), findsOneWidget);
  });
}
