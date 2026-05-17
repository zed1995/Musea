import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/profile/presentation/pages/profile_page.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';

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
    expect(find.text('Latest uploads'), findsOneWidget);
    expect(
        find.text('14 public photos · 58 curated collections'), findsNothing);
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

    expect(find.text('Latest uploads'), findsOneWidget);
    expect(find.text('Curated groupings'), findsNothing);
    expect(find.text('Saved inspiration'), findsNothing);

    await tester.tap(find.text('Collections').last);
    await tester.pumpAndSettle();

    expect(find.text('Latest uploads'), findsNothing);
    expect(find.text('Curated groupings'), findsOneWidget);
    expect(find.text('Venezuela'), findsOneWidget);
    expect(find.text('Saved inspiration'), findsNothing);

    await tester.tap(find.text('Likes').last);
    await tester.pumpAndSettle();

    expect(find.text('Latest uploads'), findsNothing);
    expect(find.text('Curated groupings'), findsNothing);
    expect(find.text('Saved inspiration'), findsOneWidget);
    expect(find.text('No liked photos yet'), findsNothing);
  });
}
