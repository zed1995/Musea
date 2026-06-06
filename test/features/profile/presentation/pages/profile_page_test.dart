import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/l10n/generated/app_localizations.dart';
import 'package:musea/features/profile/domain/repositories/profile_repository.dart';
import 'package:musea/features/profile/presentation/pages/profile_page.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockProfileRepository;

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

  Widget buildApp({
    required String username,
    User? initialUser,
    Object? profileValue,
  }) {
    final overrides = <Override>[
      profileRepositoryProvider.overrideWithValue(mockProfileRepository),
    ];

    if (profileValue is User) {
      overrides.add(
        userProfileProvider(username).overrideWith((ref) => profileValue),
      );
    } else if (profileValue is Future<User>) {
      overrides.add(
        userProfileProvider(username).overrideWith((ref) => profileValue),
      );
    }

    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfilePage(
          username: username,
          initialUser: initialUser,
        ),
      ),
    );
  }

  testWidgets('ProfilePage renders prototype detail structure', (tester) async {
    await tester.pumpWidget(
      buildApp(
        username: 'spaciba',
        profileValue: user,
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
      find.text('14 public photos · 58 curated collections'),
      findsNothing,
    );
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
      buildApp(
        username: 'blank',
        profileValue: blankUser,
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
    when(() => mockProfileRepository.getUserCollections(
          'spaciba',
          page: 1,
          perPage: 20,
        )).thenAnswer((_) async => const Right(<Collection>[collection]));
    when(() => mockProfileRepository.getUserLikes(
          'spaciba',
          page: 1,
          perPage: 20,
        )).thenAnswer((_) async => Right(<Photo>[likedPhoto]));

    await tester.pumpWidget(
      buildApp(
        username: 'spaciba',
        profileValue: user,
      ),
    );

    await tester.pump();
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
      buildApp(
        username: 'preview',
        initialUser: initialUser,
        profileValue: pendingUser.future,
      ),
    );

    expect(find.text('Preview Name'), findsOneWidget);
    expect(find.text('Preview bio'), findsOneWidget);
    expect(find.textContaining('@preview'), findsOneWidget);
    expect(find.textContaining('Preview City'), findsOneWidget);
    expect(find.byType(LoadingIndicator), findsNothing);
  });

  testWidgets('ProfilePage keeps initialUser when fetch fails', (tester) async {
    final failingUser = Completer<User>();
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
      buildApp(
        username: 'offline',
        initialUser: initialUser,
        profileValue: failingUser.future,
      ),
    );

    await tester.pump();
    failingUser.completeError(Exception('network error'));
    await tester.pump();

    expect(find.text('Offline User'), findsOneWidget);
    expect(find.textContaining('@offline'), findsOneWidget);
    expect(find.byType(LoadingIndicator), findsNothing);
  });

  testWidgets('ProfilePage shows loading when no initialUser', (tester) async {
    final pendingUser = Completer<User>();

    await tester.pumpWidget(
      buildApp(
        username: 'pending',
        profileValue: pendingUser.future,
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
      buildApp(
        username: 'replace',
        initialUser: initialUser,
        profileValue: pendingUser.future,
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

  testWidgets('ProfilePage shows error state for empty photo section errors',
      (tester) async {
    when(() => mockProfileRepository.getUserPhotos(
          'spaciba',
          page: 1,
          perPage: 20,
        )).thenAnswer(
      (_) async => const Left(Failure.unknown(message: 'photo failure')),
    );

    await tester.pumpWidget(
      buildApp(
        username: 'spaciba',
        profileValue: user,
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('Oops! Something went wrong'), findsOneWidget);
    expect(find.textContaining('photo failure'), findsOneWidget);
  });
}
