import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/profile/presentation/pages/profile_page.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';

void main() {
  const user = User(
    id: 'user-1',
    username: 'spaciba',
    name: 'Paula Poeira',
    bio: 'Visual storyteller',
    location: 'Costa da Caparica',
    profileImageSmall: 'https://example.com/small.jpg',
    profileImageMedium: 'https://example.com/medium.jpg',
    profileImageLarge: 'https://example.com/large.jpg',
    totalPhotos: 14,
    totalLikes: 114769,
    totalCollections: 58,
  );

  const collection = Collection(
    id: 'collection-1',
    title: 'Venezuela',
    totalPhotos: 1,
  );

  final likedPhoto = Photo(
    id: 'liked-photo-1',
    createdAt: DateTime(2024, 1, 1),
    width: 1200,
    height: 1200,
    color: '#ABCDEF',
    urlRaw: 'https://example.com/raw.jpg',
    urlFull: 'https://example.com/full.jpg',
    urlRegular: 'https://example.com/regular.jpg',
    urlSmall: 'https://example.com/small.jpg',
    urlThumb: 'https://example.com/thumb.jpg',
    likes: 88,
    downloads: 12,
    user: user,
  );

  testWidgets('ProfilePage renders prototype detail structure', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider('spaciba').overrideWith((ref) => user),
          userPhotosProvider('spaciba').overrideWith((ref) => <Photo>[]),
          userCollectionsProvider('spaciba')
              .overrideWith((ref) => <Collection>[]),
          userLikesProvider('spaciba').overrideWith((ref) => <Photo>[]),
        ],
        child: const MaterialApp(
          home: ProfilePage(username: 'spaciba'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Paula Poeira'), findsOneWidget);
    expect(find.text('Follow'), findsOneWidget);
    expect(find.text('Photos'), findsAtLeastNWidgets(1));
    expect(find.text('Collections'), findsAtLeastNWidgets(1));
    expect(find.text('Likes'), findsAtLeastNWidgets(1));
    expect(find.textContaining('@spaciba'), findsOneWidget);
    expect(
        find.text('14 public photos · 58 curated collections'), findsNothing);
    expect(find.text('Latest uploads'), findsNothing);
    expect(find.text('Curated groupings'), findsNothing);
    expect(find.text('Saved inspiration'), findsNothing);
  });

  testWidgets('ProfilePage omits missing optional copy safely', (tester) async {
    const blankUser = User(
      id: 'user-2',
      username: 'blank',
      name: 'Blank User',
      profileImageSmall: 'https://example.com/small.jpg',
      profileImageMedium: 'https://example.com/medium.jpg',
      profileImageLarge: 'https://example.com/large.jpg',
      totalPhotos: 0,
      totalLikes: 0,
      totalCollections: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider('blank').overrideWith((ref) => blankUser),
          userPhotosProvider('blank').overrideWith((ref) => <Photo>[]),
          userCollectionsProvider('blank')
              .overrideWith((ref) => <Collection>[]),
          userLikesProvider('blank').overrideWith((ref) => <Photo>[]),
        ],
        child: const MaterialApp(
          home: ProfilePage(username: 'blank'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Blank User'), findsOneWidget);
    expect(find.textContaining('@blank'), findsOneWidget);
    expect(find.text('No public photos yet'), findsOneWidget);
    expect(find.text('Costa da Caparica'), findsNothing);
    expect(find.text('Visual storyteller'), findsNothing);
  });

  testWidgets('ProfilePage shows only the selected segment content',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider('spaciba').overrideWith((ref) => user),
          userPhotosProvider('spaciba').overrideWith((ref) => <Photo>[]),
          userCollectionsProvider('spaciba').overrideWith(
            (ref) => <Collection>[collection],
          ),
          userLikesProvider('spaciba').overrideWith(
            (ref) => <Photo>[likedPhoto],
          ),
        ],
        child: const MaterialApp(
          home: ProfilePage(username: 'spaciba'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Latest uploads'), findsNothing);
    expect(find.text('Curated groupings'), findsNothing);
    expect(find.text('Saved inspiration'), findsNothing);

    await tester.tap(find.text('Collections').last);
    await tester.pumpAndSettle();

    expect(find.text('Latest uploads'), findsNothing);
    expect(find.text('Curated groupings'), findsNothing);
    expect(find.text('Venezuela'), findsOneWidget);
    expect(find.text('Saved inspiration'), findsNothing);

    await tester.tap(find.text('Likes').last);
    await tester.pumpAndSettle();

    expect(find.text('Latest uploads'), findsNothing);
    expect(find.text('Curated groupings'), findsNothing);
    expect(find.text('Saved inspiration'), findsNothing);
    expect(find.text('No liked photos yet'), findsNothing);
  });

  testWidgets('ProfilePage renders initialUser immediately while API loads',
      (tester) async {
    final pendingUser = Completer<User>();
    const initialUser = User(
      id: 'user-3',
      username: 'preview',
      name: 'Preview Name',
      bio: 'Preview bio',
      location: 'Preview City',
      profileImageSmall: 'https://example.com/small.jpg',
      profileImageMedium: 'https://example.com/medium.jpg',
      profileImageLarge: 'https://example.com/large.jpg',
      totalPhotos: 5,
      totalLikes: 100,
      totalCollections: 3,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider('preview').overrideWith((ref) => pendingUser.future),
          userPhotosProvider('preview').overrideWith((ref) => <Photo>[]),
          userCollectionsProvider('preview').overrideWith((ref) => <Collection>[]),
          userLikesProvider('preview').overrideWith((ref) => <Photo>[]),
        ],
        child: const MaterialApp(
          home: ProfilePage(
            username: 'preview',
            initialUser: initialUser,
          ),
        ),
      ),
    );

    expect(find.text('Preview Name'), findsOneWidget);
    expect(find.text('Preview bio'), findsOneWidget);
    expect(find.textContaining('@preview'), findsOneWidget);
    expect(find.textContaining('Preview City'), findsOneWidget);
    expect(find.byType(LoadingIndicator), findsNothing);
  });

  testWidgets('ProfilePage keeps initialUser when fetch fails',
      (tester) async {
    const initialUser = User(
      id: 'user-4',
      username: 'offline',
      name: 'Offline User',
      profileImageSmall: 'https://example.com/small.jpg',
      profileImageMedium: 'https://example.com/medium.jpg',
      profileImageLarge: 'https://example.com/large.jpg',
      totalPhotos: 0,
      totalLikes: 0,
      totalCollections: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider('offline').overrideWith(
            (ref) => Future<User>.error(Exception('network error')),
          ),
          userPhotosProvider('offline').overrideWith((ref) => <Photo>[]),
          userCollectionsProvider('offline').overrideWith((ref) => <Collection>[]),
          userLikesProvider('offline').overrideWith((ref) => <Photo>[]),
        ],
        child: const MaterialApp(
          home: ProfilePage(
            username: 'offline',
            initialUser: initialUser,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Offline User'), findsOneWidget);
    expect(find.textContaining('@offline'), findsOneWidget);
    expect(find.byType(LoadingIndicator), findsNothing);
  });

  testWidgets('ProfilePage shows loading when no initialUser',
      (tester) async {
    final pendingUser = Completer<User>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider('pending').overrideWith((ref) => pendingUser.future),
          userPhotosProvider('pending').overrideWith((ref) => <Photo>[]),
          userCollectionsProvider('pending').overrideWith((ref) => <Collection>[]),
          userLikesProvider('pending').overrideWith((ref) => <Photo>[]),
        ],
        child: const MaterialApp(
          home: ProfilePage(username: 'pending'),
        ),
      ),
    );

    expect(find.byType(LoadingIndicator), findsOneWidget);
    expect(find.text('Paula Poeira'), findsNothing);
  });

  testWidgets('ProfilePage replaces initialUser when API succeeds',
      (tester) async {
    final pendingUser = Completer<User>();
    const initialUser = User(
      id: 'user-5',
      username: 'replace',
      name: 'Placeholder',
      profileImageSmall: 'https://example.com/small.jpg',
      profileImageMedium: 'https://example.com/medium.jpg',
      profileImageLarge: 'https://example.com/large.jpg',
      totalPhotos: 0,
      totalLikes: 0,
      totalCollections: 0,
    );
    const hydratedUser = User(
      id: 'user-5',
      username: 'replace',
      name: 'Hydrated Name',
      bio: 'Fresh bio from API',
      profileImageSmall: 'https://example.com/small.jpg',
      profileImageMedium: 'https://example.com/medium.jpg',
      profileImageLarge: 'https://example.com/large.jpg',
      totalPhotos: 42,
      totalLikes: 999,
      totalCollections: 7,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider('replace').overrideWith((ref) => pendingUser.future),
          userPhotosProvider('replace').overrideWith((ref) => <Photo>[]),
          userCollectionsProvider('replace').overrideWith((ref) => <Collection>[]),
          userLikesProvider('replace').overrideWith((ref) => <Photo>[]),
        ],
        child: const MaterialApp(
          home: ProfilePage(
            username: 'replace',
            initialUser: initialUser,
          ),
        ),
      ),
    );

    expect(find.text('Placeholder'), findsOneWidget);
    expect(find.text('Fresh bio from API'), findsNothing);

    pendingUser.complete(hydratedUser);
    await tester.pump();

    expect(find.text('Hydrated Name'), findsOneWidget);
    expect(find.text('Fresh bio from API'), findsOneWidget);
    expect(find.text('Placeholder'), findsNothing);
  });
}
