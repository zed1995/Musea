import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/app.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/discover/presentation/providers/topics_provider.dart';

void main() {
  const user = User(
    id: 'user-1',
    username: 'forest',
    name: 'Forest Archive',
    bio: 'Shoots outdoors',
    location: 'Portland',
    profileImageSmall: 'https://example.com/small.jpg',
    profileImageMedium: 'https://example.com/medium.jpg',
    profileImageLarge: 'https://example.com/large.jpg',
    totalPhotos: 12,
    totalLikes: 44,
    totalCollections: 3,
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
    user: user,
  );

  testWidgets(
      'home keeps discover route and bottom nav shows discover collections and mine',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photosProvider(1).overrideWith((ref) => <Photo>[photo]),
          topicsProvider.overrideWith((ref) => <Topic>[]),
          collectionsProvider(1).overrideWith((ref) => <Collection>[]),
        ],
        child: const MuseaApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Collections'), findsOneWidget);
    expect(find.text('Mine'), findsOneWidget);
    expect(find.text('Search photos, collections, users...'), findsOneWidget);
  });

  testWidgets('tapping the home search entry opens the full search page',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photosProvider(1).overrideWith((ref) => <Photo>[photo]),
          topicsProvider.overrideWith((ref) => <Topic>[]),
          collectionsProvider(1).overrideWith((ref) => <Collection>[]),
        ],
        child: const MuseaApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Search photos, collections, users...'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Photos'), findsWidgets);
    expect(find.text('Users'), findsWidgets);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
  });
}
