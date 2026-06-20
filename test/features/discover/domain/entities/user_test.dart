import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/discover/domain/entities/user.dart';

void main() {
  User sampleUser() => const User(
        id: '1',
        username: 'spaciba',
        name: 'Paula Poeira',
        profileImageSmall: 'small',
        profileImageMedium: 'medium',
        profileImageLarge: 'large',
        totalPhotos: 10,
        totalLikes: 20,
        totalCollections: 3,
        followedByUser: false,
      );

  test('copyWith flips followedByUser without touching other fields', () {
    final original = sampleUser();
    final updated = original.copyWith(followedByUser: true);

    expect(updated.followedByUser, isTrue);
    expect(updated.id, original.id);
    expect(updated.username, original.username);
    expect(updated.name, original.name);
    expect(updated.totalPhotos, original.totalPhotos);
    expect(updated.profileImageMedium, original.profileImageMedium);
  });

  test('copyWith with no args returns a value-equal copy', () {
    final original = sampleUser();
    final copy = original.copyWith();

    expect(copy.followedByUser, original.followedByUser);
    expect(copy.username, original.username);
    expect(copy.totalLikes, original.totalLikes);
  });
}
