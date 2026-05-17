import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/shared/widgets/photo_card.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';

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
}) => Photo(
  id: 'photo1',
  createdAt: DateTime.now(),
  width: 4000,
  height: 3000,
  color: '#ABCDEF',
  blurHash: null,
  urlRaw: '',
  urlFull: '',
  urlRegular: '',
  urlSmall: '',
  urlThumb: '',
  likes: likes,
  downloads: downloads,
  user: createTestUser(),
);

Widget wrapApp(Widget widget) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: widget)),
);

void main() {
  testWidgets('PhotoCard displays user name and like count', (tester) async {
    final photo = createTestPhoto(likes: 1234);
    await tester.pumpWidget(wrapApp(PhotoCard(photo: photo)));

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('1.2k'), findsOneWidget);
    expect(find.byIcon(Icons.download), findsOneWidget);
  });

  testWidgets('PhotoCard hides download button when showDownloadButton is false',
      (tester) async {
    final photo = createTestPhoto();
    await tester.pumpWidget(wrapApp(
      PhotoCard(photo: photo, showDownloadButton: false),
    ));

    expect(find.byIcon(Icons.download), findsNothing);
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
