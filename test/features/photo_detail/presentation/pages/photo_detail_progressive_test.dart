import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/photo_detail/presentation/pages/photo_detail_page.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/l10n/generated/app_localizations.dart';
import 'package:musea/router/detail_route_extras.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';

void main() {
  const photographer = User(
    id: 'user-1',
    username: 'forest',
    name: 'Forest Archive',
    profileImageSmall: 'https://example.com/small-profile.jpg',
    profileImageMedium: 'https://example.com/medium-profile.jpg',
    profileImageLarge: 'https://example.com/large-profile.jpg',
    totalPhotos: 20,
    totalLikes: 30,
    totalCollections: 2,
  );

  Photo buildPhoto({
    required String id,
    String? description = 'Quiet light',
    String color = '#5B7B9A',
    ExifData? exif,
    List<Tag> tags = const [],
    String? downloadLink,
    String? downloadLocation,
  }) {
    return Photo(
      id: id,
      createdAt: DateTime(2024, 1, 1),
      width: 1200,
      height: 1600,
      color: color,
      description: description,
      altDescription: description,
      urlRaw: 'https://example.com/$id-raw.jpg',
      urlFull: 'https://example.com/$id-full.jpg',
      urlRegular: 'https://example.com/$id-regular.jpg',
      urlSmall: 'https://example.com/$id-small.jpg',
      urlThumb: 'https://example.com/$id-thumb.jpg',
      downloadLink: downloadLink,
      downloadLocation: downloadLocation,
      likes: 1284,
      downloads: 12000,
      views: 52300,
      user: photographer,
      exif: exif,
      tags: tags,
    );
  }

  testWidgets(
      'photo detail renders initial photo immediately while detail hydrates',
      (tester) async {
    final pending = Completer<Photo>();
    final initialPhoto = buildPhoto(id: 'photo-1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider('photo-1').overrideWith((ref) => pending.future),
          userPhotosProvider('forest').overrideWith((ref) => <Photo>[]),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoDetailPage(
            photoId: 'photo-1',
            initialPhoto: initialPhoto,
            hydrateDeferredDetailsFromInitialPhoto: true,
          ),
        ),
      ),
    );

    expect(find.text('Forest Archive'), findsOneWidget);
    expect(find.text('Quiet light'), findsOneWidget);
    expect(find.byType(ErrorState), findsNothing);
    expect(
      find.byKey(const ValueKey('photo-detail-tags-skeleton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('photo-detail-exif-skeleton')),
      findsOneWidget,
    );
  });

  testWidgets('photo detail keeps initial content when hydration fails',
      (tester) async {
    final initialPhoto = buildPhoto(id: 'photo-1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider('photo-1').overrideWith(
            (ref) => Future<Photo>.error(Exception('deferred failure')),
          ),
          userPhotosProvider('forest').overrideWith((ref) => <Photo>[]),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoDetailPage(
            photoId: 'photo-1',
            initialPhoto: initialPhoto,
            hydrateDeferredDetailsFromInitialPhoto: true,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Forest Archive'), findsOneWidget);
    expect(find.text('Quiet light'), findsOneWidget);
    expect(find.byType(ErrorState), findsNothing);
    expect(find.text('Retry loading details'), findsOneWidget);
  });

  testWidgets(
      'photo detail does not show deferred placeholders for hydrated empty metadata',
      (tester) async {
    final hydratedEmptyPhoto = buildPhoto(
      id: 'photo-1',
      downloadLink: 'https://example.com/download',
      downloadLocation: 'https://example.com/download-location',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider('photo-1').overrideWith(
            (ref) => Future<Photo>.error(Exception('deferred failure')),
          ),
          userPhotosProvider('forest').overrideWith((ref) => <Photo>[]),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoDetailPage(
            photoId: 'photo-1',
            initialPhoto: hydratedEmptyPhoto,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(
        find.byKey(const ValueKey('photo-detail-tags-skeleton')), findsNothing);
    expect(
        find.byKey(const ValueKey('photo-detail-exif-skeleton')), findsNothing);
    expect(find.text('Retry loading details'), findsNothing);
  });

  testWidgets(
      'photo detail still hydrates deferred sections for prefetched photo with download links',
      (tester) async {
    final pending = Completer<Photo>();
    final prefetchedPhoto = buildPhoto(
      id: 'photo-1',
      downloadLink: 'https://example.com/download',
      downloadLocation: 'https://example.com/download-location',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider('photo-1').overrideWith((ref) => pending.future),
          userPhotosProvider('forest').overrideWith((ref) => <Photo>[]),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoDetailPage(
            photoId: 'photo-1',
            initialPhoto: prefetchedPhoto,
            hydrateDeferredDetailsFromInitialPhoto: true,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('photo-detail-tags-skeleton')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('photo-detail-exif-skeleton')),
        findsOneWidget);
  });

  testWidgets(
      'photo detail deep link without initial photo keeps full-page loading',
      (tester) async {
    final pending = Completer<Photo>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider('photo-1').overrideWith((ref) => pending.future),
          userPhotosProvider('forest').overrideWith((ref) => <Photo>[]),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PhotoDetailPage(photoId: 'photo-1'),
        ),
      ),
    );

    expect(find.byType(LoadingIndicator), findsOneWidget);
    expect(find.text('Forest Archive'), findsNothing);
  });

  testWidgets(
      'photo detail replaces initial partial photo after hydration succeeds',
      (tester) async {
    final pending = Completer<Photo>();
    final initialPhoto = buildPhoto(id: 'photo-1');
    final hydratedPhoto = buildPhoto(
      id: 'photo-1',
      description: 'Hydrated detail',
      exif: const ExifData(make: 'Sony', model: 'A7 III'),
      tags: const [Tag(title: 'Kyoto'), Tag(title: 'Temple')],
      downloadLink: 'https://example.com/download',
      downloadLocation: 'https://example.com/download-location',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider('photo-1').overrideWith((ref) => pending.future),
          userPhotosProvider('forest').overrideWith((ref) => <Photo>[]),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoDetailPage(
            photoId: 'photo-1',
            initialPhoto: initialPhoto,
            hydrateDeferredDetailsFromInitialPhoto: true,
          ),
        ),
      ),
    );

    expect(find.text('Quiet light'), findsOneWidget);
    expect(find.byKey(const ValueKey('photo-detail-tags-skeleton')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('photo-detail-exif-skeleton')),
        findsOneWidget);

    pending.complete(hydratedPhoto);
    await tester.pump();

    expect(find.text('Hydrated detail'), findsOneWidget);
    expect(find.text('Kyoto'), findsOneWidget);
    expect(find.text('Temple'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Sony A7 III'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('photo-detail-tags-skeleton')), findsNothing);
    expect(
        find.byKey(const ValueKey('photo-detail-exif-skeleton')), findsNothing);
  });

  testWidgets('photo detail keeps initial hero image source after hydration',
      (tester) async {
    final pending = Completer<Photo>();
    final initialPhoto = buildPhoto(id: 'photo-hero-lock');
    final hydratedPhoto = Photo(
      id: 'photo-hero-lock',
      createdAt: DateTime(2024, 1, 1),
      width: 800,
      height: 800,
      color: '#445566',
      description: 'Hydrated detail',
      altDescription: 'Hydrated detail',
      urlRaw: 'https://example.com/photo-hero-lock-hydrated-raw.jpg',
      urlFull: 'https://example.com/photo-hero-lock-hydrated-full.jpg',
      urlRegular: 'https://example.com/photo-hero-lock-hydrated-regular.jpg',
      urlSmall: 'https://example.com/photo-hero-lock-hydrated-small.jpg',
      urlThumb: 'https://example.com/photo-hero-lock-hydrated-thumb.jpg',
      downloadLink: 'https://example.com/download',
      downloadLocation: 'https://example.com/download-location',
      likes: 1284,
      downloads: 12000,
      views: 52300,
      user: photographer,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider('photo-hero-lock')
              .overrideWith((ref) => pending.future),
          userPhotosProvider('forest').overrideWith((ref) => <Photo>[]),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoDetailPage(
            photoId: 'photo-hero-lock',
            initialPhoto: initialPhoto,
            hydrateDeferredDetailsFromInitialPhoto: true,
          ),
        ),
      ),
    );

    final initialImage = tester.widget<CachedNetworkImage>(
      find.descendant(
        of: find.byType(Hero),
        matching: find.byType(CachedNetworkImage),
      ),
    );

    pending.complete(hydratedPhoto);
    await tester.pump();

    final hydratedImage = tester.widget<CachedNetworkImage>(
      find.descendant(
        of: find.byType(Hero),
        matching: find.byType(CachedNetworkImage),
      ),
    );

    expect(hydratedImage.imageUrl, initialImage.imageUrl);
    expect(find.text('Hydrated detail'), findsOneWidget);
  });

  testWidgets('photo detail back button is safe when route cannot pop',
      (tester) async {
    final photo = buildPhoto(id: 'photo-root');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider('photo-root').overrideWith((ref) => photo),
          userPhotosProvider('forest').overrideWith((ref) => <Photo>[]),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PhotoDetailPage(photoId: 'photo-root'),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Forest Archive'), findsOneWidget);
  });

  testWidgets('more from photographer passes photo in route extra',
      (tester) async {
    final currentPhoto = buildPhoto(
      id: 'photo-1',
      exif: const ExifData(make: 'Sony', model: 'A7 III'),
      tags: const [Tag(title: 'Kyoto')],
    );
    final relatedPhoto = buildPhoto(id: 'photo-2', description: 'Second frame');

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => ProviderScope(
            overrides: [
              photoDetailProvider('photo-1')
                  .overrideWith((ref) => currentPhoto),
              userPhotosProvider('forest')
                  .overrideWith((ref) => <Photo>[currentPhoto, relatedPhoto]),
            ],
            child: const PhotoDetailPage(photoId: 'photo-1'),
          ),
        ),
        GoRoute(
          path: '/photo/:id',
          builder: (context, state) {
            final extra = state.extra as PhotoDetailExtra?;
            return Scaffold(
              body: Text(extra?.photo.id ?? 'missing-extra'),
            );
          },
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

    await tester.pump(const Duration(milliseconds: 200));
    await tester.scrollUntilVisible(
      find.text('More from photographer'),
      300,
    );
    await tester.pump(const Duration(milliseconds: 200));

    final relatedPhotoTap = tester.widget<GestureDetector>(
      find
          .ancestor(
            of: find.byType(ClipRRect).last,
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    relatedPhotoTap.onTap?.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('photo-2'), findsOneWidget);
  });
}
