import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/auth/domain/entities/auth_session.dart';
import 'package:musea/features/auth/domain/entities/auth_user.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/router/app_router.dart';
import 'package:musea/shared/widgets/collection_card.dart';

void main() {
  testWidgets('Mine tab shows sign-in surface when signed out', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authBootstrapSessionProvider.overrideWithValue(null),
          authClockProvider.overrideWithValue(() => DateTime(2026, 5, 20, 10)),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
        ],
        child: const MaterialApp(
          home: ProfileTabPage(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Sign in to shape your visual workspace'), findsOneWidget);
    expect(find.text('What you unlock'), findsOneWidget);
    expect(find.text('Continue with Unsplash'), findsAtLeastNWidgets(1));
  });

  testWidgets('Mine tab shows cached profile content when signed in',
      (tester) async {
    const authUser = AuthUser(
      id: 'user-1',
      username: 'spaciba',
      displayName: 'Paula Poeira',
      bio: 'Visual storyteller',
      location: 'Costa da Caparica',
      profileImageMedium: 'https://example.com/avatar-medium.jpg',
      totalPhotos: 14,
      totalLikes: 114769,
      totalCollections: 58,
    );

    const publicUser = User(
      id: 'user-1',
      username: 'spaciba',
      name: 'Paula Poeira',
      bio: 'Visual storyteller',
      location: 'Costa da Caparica',
      profileImageSmall: 'https://example.com/avatar-small.jpg',
      profileImageMedium: 'https://example.com/avatar-medium.jpg',
      profileImageLarge: 'https://example.com/avatar-large.jpg',
      totalPhotos: 14,
      totalLikes: 114769,
      totalCollections: 58,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authBootstrapSessionProvider.overrideWithValue(
            AuthSession(
              accessToken: 'token-1',
              tokenType: 'bearer',
              scope: 'public read_user',
              createdAt: 123,
              user: authUser,
              lastProfileRefreshAt: DateTime(2026, 5, 20, 10),
            ),
          ),
          authClockProvider.overrideWithValue(
            () => DateTime(2026, 5, 20, 10, 5),
          ),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          userProfileProvider('spaciba').overrideWith((ref) => publicUser),
          userPhotosProvider('spaciba').overrideWith((ref) => <Photo>[]),
          userCollectionsProvider('spaciba')
              .overrideWith((ref) => <Collection>[]),
          userLikesProvider('spaciba').overrideWith((ref) => <Photo>[]),
        ],
        child: const MaterialApp(
          home: ProfileTabPage(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Paula Poeira'), findsOneWidget);
    expect(find.textContaining('@spaciba'), findsOneWidget);
    expect(find.text('Photos'), findsWidgets);
    expect(find.text('Collections'), findsWidgets);
    expect(find.text('Likes'), findsWidgets);
    expect(find.text('Continue with Unsplash'), findsNothing);
  });

  testWidgets('Mine tab switches between photos collections and likes',
      (tester) async {
    const authUser = AuthUser(
      id: 'user-1',
      username: 'spaciba',
      displayName: 'Paula Poeira',
      bio: 'Visual storyteller',
      location: 'Costa da Caparica',
      profileImageMedium: 'https://example.com/avatar-medium.jpg',
      totalPhotos: 14,
      totalLikes: 114769,
      totalCollections: 58,
    );

    const publicUser = User(
      id: 'user-1',
      username: 'spaciba',
      name: 'Paula Poeira',
      bio: 'Visual storyteller',
      location: 'Costa da Caparica',
      profileImageSmall: 'https://example.com/avatar-small.jpg',
      profileImageMedium: 'https://example.com/avatar-medium.jpg',
      profileImageLarge: 'https://example.com/avatar-large.jpg',
      totalPhotos: 14,
      totalLikes: 114769,
      totalCollections: 58,
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
      user: publicUser,
    );

    const collection = Collection(
      id: 'collection-1',
      title: 'Forest Archive',
      totalPhotos: 12,
      user: publicUser,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authBootstrapSessionProvider.overrideWithValue(
            AuthSession(
              accessToken: 'token-1',
              tokenType: 'bearer',
              scope: 'public read_user',
              createdAt: 123,
              user: authUser,
              lastProfileRefreshAt: DateTime(2026, 5, 20, 10),
            ),
          ),
          authClockProvider.overrideWithValue(
            () => DateTime(2026, 5, 20, 10, 5),
          ),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          userProfileProvider('spaciba').overrideWith((ref) => publicUser),
          userPhotosProvider('spaciba').overrideWith((ref) => <Photo>[photo]),
          userCollectionsProvider('spaciba')
              .overrideWith((ref) => <Collection>[collection]),
          userLikesProvider('spaciba').overrideWith((ref) => <Photo>[photo]),
        ],
        child: const MaterialApp(
          home: ProfileTabPage(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Forest Archive'), findsNothing);

    await tester.tap(find.text('Collections').last);
    await tester.pumpAndSettle();
    expect(find.text('Forest Archive'), findsOneWidget);
    expect(find.byType(CollectionCard), findsWidgets);

    await tester.tap(find.text('Likes').last);
    await tester.pumpAndSettle();
    expect(find.text('Forest Archive'), findsNothing);
  });
}
