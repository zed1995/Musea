import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/pages/collections_page.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

/// A simple smoke test to verify the CollectionsPage renders without crashing.
void main() {
  /// Shared provider overrides for auth dependencies.
  List<Override> _authOverrides() => [
        authBootstrapSessionProvider.overrideWithValue(null),
        authRedirectUriProvider.overrideWithValue(
          Uri.parse('musea://auth/callback'),
        ),
      ];

  testWidgets('CollectionsPage shows empty state when no collections',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._authOverrides(),
          collectionsProvider(1).overrideWith(
            (ref) => <Collection>[],
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CollectionsPage(),
        ),
      ),
    );

    // Verify the empty state message renders
    expect(find.text('No collections yet.'), findsOneWidget);
  });

  testWidgets('CollectionsPage uses the simplified prototype header',
      (tester) async {
    const user = User(
      id: 'user-1',
      username: 'curator',
      name: 'Curator',
      profileImageSmall: '',
      profileImageMedium: '',
      profileImageLarge: '',
      totalPhotos: 0,
      totalLikes: 0,
      totalCollections: 0,
    );

    final photo = Photo(
      id: 'photo-1',
      createdAt: DateTime(2024, 1, 1),
      width: 1200,
      height: 800,
      color: '#ABCDEF',
      urlRaw: '',
      urlFull: '',
      urlRegular: '',
      urlSmall: '',
      urlThumb: '',
      likes: 10,
      downloads: 5,
      user: user,
    );

    final collections = [
      Collection(
        id: 'collection-1',
        title: 'Travel Inspiration',
        totalPhotos: 24,
        coverPhoto: photo,
        previewPhotos: const [],
        user: user,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._authOverrides(),
          collectionsProvider(1).overrideWith((ref) => collections),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CollectionsPage(),
        ),
      ),
    );

    expect(find.text('Collections'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('+ button shows auth sheet when unauthenticated',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const user = User(
      id: 'user-1',
      username: 'curator',
      name: 'Curator',
      profileImageSmall: '',
      profileImageMedium: '',
      profileImageLarge: '',
      totalPhotos: 0,
      totalLikes: 0,
      totalCollections: 0,
    );

    final collections = [
      Collection(
        id: 'collection-1',
        title: 'Travel Inspiration',
        totalPhotos: 24,
        previewPhotos: const [],
        user: user,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._authOverrides(),
          collectionsProvider(1).overrideWith((ref) => collections),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CollectionsPage(),
        ),
      ),
    );

    // Tap the + button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Auth gate sheet should appear with Unsplash content
    expect(find.textContaining('Unsplash'), findsWidgets);
  });
}
