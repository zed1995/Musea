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
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/router/detail_route_extras.dart';

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
    user: AuthUser(
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
          home: PhotoDetailPage(photoId: 'photo-1'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Paula Poeira'), findsOneWidget);
    expect(find.text('Quiet light'), findsOneWidget);
    expect(find.text('Download Free'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider('photo-liked').overrideWith((ref) => photo),
          userPhotosProvider('paula').overrideWith((ref) => <Photo>[]),
        ],
        child: const MaterialApp(
          home: PhotoDetailPage(photoId: 'photo-liked'),
        ),
      ),
    );

    await tester.pump();

    final likeIcon = tester.widget<Icon>(find.byIcon(Icons.favorite));

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
    expect(likeIcon.color, const Color(0xFFE11D48));
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
      () => repository.likePhoto(
        'photo-toggle-like',
        accessToken: 'access-token',
      ),
    ).thenAnswer((_) async => Right(likedPhoto));
    when(
      () => repository.unlikePhoto(
        'photo-toggle-like',
        accessToken: 'access-token',
      ),
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
      () => repository.likePhoto(
        'photo-toggle-like',
        accessToken: 'access-token',
      ),
    ).called(1);
    expect(find.text('13'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('photo-detail-like-button')).first);
    await tester.pump();

    verify(
      () => repository.unlikePhoto(
        'photo-toggle-like',
        accessToken: 'access-token',
      ),
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
        child: MaterialApp.router(routerConfig: router),
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
}
