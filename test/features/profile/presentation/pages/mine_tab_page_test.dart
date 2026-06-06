import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/l10n/generated/app_localizations.dart';
import 'package:musea/features/auth/domain/entities/auth_session.dart';
import 'package:musea/features/auth/domain/entities/auth_user.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/profile/domain/repositories/profile_repository.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/router/app_router.dart';
import 'package:musea/shared/widgets/collection_card.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

Widget _buildTestApp(Widget home) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

void main() {
  late MockProfileRepository mockProfileRepository;

  setUp(() {
    mockProfileRepository = MockProfileRepository();

    when(() => mockProfileRepository.getUserPhotos(
          any(),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        )).thenAnswer((_) async => const Right(<Photo>[]));
    when(() => mockProfileRepository.getUserCollections(
          any(),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        )).thenAnswer((_) async => const Right(<Collection>[]));
    when(() => mockProfileRepository.getUserLikes(
          any(),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        )).thenAnswer((_) async => const Right(<Photo>[]));
  });

  testWidgets('Mine tab shows sign-in surface when signed out', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(mockProfileRepository),
          authBootstrapSessionProvider.overrideWithValue(null),
          authClockProvider.overrideWithValue(() => DateTime(2026, 5, 20, 10)),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
        ],
        child: _buildTestApp(const ProfileTabPage()),
      ),
    );

    await tester.pump();

    expect(
      find.text('Your visual archive, synced with Unsplash'),
      findsOneWidget,
    );
    expect(
      find.text('You can keep exploring without signing in'),
      findsOneWidget,
    );
    expect(find.text('Continue with Unsplash'), findsAtLeastNWidgets(1));
    expect(find.text('What you unlock'), findsNothing);

    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    final scrollPadding = scrollView.padding as EdgeInsets? ?? EdgeInsets.zero;
    expect(scrollPadding.bottom, greaterThan(0));

    final topBarPadding =
        tester.widgetList<Padding>(find.byType(Padding)).firstWhere(
      (widget) {
        final padding = widget.padding;
        return padding is EdgeInsets &&
            padding.left == 12 &&
            padding.top == 12 &&
            padding.right == 12;
      },
    );
    expect((topBarPadding.padding as EdgeInsets).bottom, greaterThan(0));

    final collectionsChips = tester.widgetList<Text>(find.text('Collections'));
    expect(collectionsChips.any((widget) => widget.maxLines == 1), isTrue);

    expect(find.text('Browse profiles'), findsOneWidget);
    expect(find.text('Mine'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsNothing);
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
          profileRepositoryProvider.overrideWithValue(mockProfileRepository),
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
        ],
        child: _buildTestApp(const ProfileTabPage()),
      ),
    );

    await tester.pump();

    expect(find.text('Paula Poeira'), findsOneWidget);
    expect(find.textContaining('@spaciba'), findsOneWidget);
    expect(find.text('Photos'), findsWidgets);
    expect(find.text('Collections'), findsWidgets);
    expect(find.text('Likes'), findsWidgets);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.text('Edit profile'), findsNothing);
    expect(find.text('Continue with Unsplash'), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsNothing);
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

    when(() => mockProfileRepository.getUserPhotos(
          'spaciba',
          page: 1,
          perPage: 20,
        )).thenAnswer((_) async => Right(<Photo>[photo]));
    when(() => mockProfileRepository.getUserCollections(
          'spaciba',
          page: 1,
          perPage: 20,
        )).thenAnswer((_) async => const Right(<Collection>[collection]));
    when(() => mockProfileRepository.getUserLikes(
          'spaciba',
          page: 1,
          perPage: 20,
        )).thenAnswer((_) async => Right(<Photo>[photo]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(mockProfileRepository),
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
        ],
        child: _buildTestApp(const ProfileTabPage()),
      ),
    );

    await tester.pump();
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

  testWidgets('Mine tab exposes settings entry when signed in', (tester) async {
    const authUser = AuthUser(
      id: 'user-1',
      username: 'spaciba',
      displayName: 'Paula Poeira',
      profileImageMedium: 'https://example.com/avatar-medium.jpg',
      totalPhotos: 14,
      totalLikes: 114769,
      totalCollections: 58,
    );

    const publicUser = User(
      id: 'user-1',
      username: 'spaciba',
      name: 'Paula Poeira',
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
          profileRepositoryProvider.overrideWithValue(mockProfileRepository),
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
        ],
        child: _buildTestApp(const ProfileTabPage()),
      ),
    );

    await tester.pump();

    expect(
      find.byIcon(Icons.settings_outlined),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.tune_rounded), findsNothing);
  });
}
