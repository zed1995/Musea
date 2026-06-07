import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/shared/widgets/photo_card.dart';
import 'package:musea/shared/widgets/progressive_network_photo.dart';

User createTestUser() => const User(
      id: 'user1',
      username: 'testuser',
      name: 'Test User',
      profileImageSmall: '',
      profileImageMedium: '',
      profileImageLarge: '',
      totalPhotos: 10,
      totalLikes: 100,
      totalCollections: 5,
    );

Photo createTestPhoto({
  int likes = 42,
  int downloads = 10,
  bool likedByUser = false,
}) =>
    Photo(
      id: 'photo1',
      createdAt: DateTime.now(),
      width: 4000,
      height: 3000,
      color: '#ABCDEF',
      blurHash: null,
      urlRaw: 'https://example.com/raw.jpg',
      urlFull: 'https://example.com/full.jpg',
      urlRegular: 'https://example.com/regular.jpg',
      urlSmall: 'https://example.com/small.jpg',
      urlThumb: 'https://example.com/thumb.jpg',
      likes: likes,
      downloads: downloads,
      likedByUser: likedByUser,
      user: createTestUser(),
    );

Widget wrapApp(Widget widget) => ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: widget)),
      ),
    );

void main() {
  testWidgets('PhotoCard displays user name and like count', (tester) async {
    final photo = createTestPhoto(likes: 1234);
    await tester.pumpWidget(wrapApp(PhotoCard(photo: photo)));

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('1.2k'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
  });

  testWidgets('PhotoCard displays bookmark icon', (tester) async {
    final photo = createTestPhoto(likes: 10);
    await tester.pumpWidget(wrapApp(
      PhotoCard(photo: photo),
    ));

    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
  });

  testWidgets('PhotoCard uses the shared progressive photo widget',
      (tester) async {
    final photo = createTestPhoto();

    await tester.pumpWidget(wrapApp(PhotoCard(photo: photo)));

    expect(find.byType(ProgressiveNetworkPhoto), findsOneWidget);
  });

  testWidgets('PhotoCard shows filled red like button for liked photo',
      (tester) async {
    final photo = createTestPhoto(likedByUser: true);

    await tester.pumpWidget(wrapApp(PhotoCard(photo: photo)));

    final likeIcon = tester.widget<Icon>(find.byIcon(Icons.favorite));

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
    expect(likeIcon.color, const Color(0xFFE11D48));
    expect(tester.widget<Text>(find.text('42')).style?.color, Colors.white);
  });

  testWidgets('PhotoCard triggers onPhotoTap on tap', (tester) async {
    final photo = createTestPhoto();
    bool tapped = false;
    await tester.pumpWidget(wrapApp(
      PhotoCard(
        photo: photo,
        onPhotoTap: () => tapped = true,
      ),
    ));

    await tester.tap(find.byType(GestureDetector).first);
    expect(tapped, isTrue);
  });
}
