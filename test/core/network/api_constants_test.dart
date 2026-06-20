import 'package:flutter_test/flutter_test.dart';
import 'package:musea/core/constants/api_constants.dart';

void main() {
  test('userPhotos returns /users/:username/photos', () {
    expect(ApiConstants.userPhotos('spaciba'), '/users/spaciba/photos');
  });

  test('userLikes returns /users/:username/likes', () {
    expect(ApiConstants.userLikes('spaciba'), '/users/spaciba/likes');
  });

  test('userCollections returns /users/:username/collections', () {
    expect(
      ApiConstants.userCollections('spaciba'),
      '/users/spaciba/collections',
    );
  });
}
