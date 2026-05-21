import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/shared/widgets/photo_grid.dart';

User _user() => const User(
      id: 'user-1',
      username: 'spaciba',
      name: 'Paula Poeira',
      profileImageSmall: '',
      profileImageMedium: '',
      profileImageLarge: '',
      totalPhotos: 10,
      totalLikes: 20,
      totalCollections: 3,
    );

Photo _photo({required bool likedByUser, int likes = 42}) => Photo(
      id: 'photo-1',
      createdAt: DateTime(2024, 1, 1),
      width: 1200,
      height: 1600,
      color: '#AABBCC',
      urlRaw: '',
      urlFull: '',
      urlRegular: '',
      urlSmall: '',
      urlThumb: '',
      likes: likes,
      downloads: 20,
      likedByUser: likedByUser,
      user: _user(),
    );

void main() {
  testWidgets('PhotoGrid keeps like count text white for liked photos',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PhotoGrid(
              photos: [_photo(likedByUser: true)],
              showLikes: true,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final likeIcon = tester.widget<Icon>(find.byIcon(Icons.favorite));
    final likeCount = tester.widget<Text>(find.text('42'));

    expect(likeIcon.color, const Color(0xFFE11D48));
    expect(likeCount.style?.color, Colors.white);
  });
}
