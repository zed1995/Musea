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

    expect(
        find.text('Your visual archive, synced with Unsplash'), findsOneWidget);
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
    expect(find.text('Visual storyteller'), findsOneWidget);
    expect(find.text('Continue with Unsplash'), findsNothing);
  });
}
