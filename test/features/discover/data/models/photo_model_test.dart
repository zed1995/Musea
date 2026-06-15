import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';
import 'package:musea/features/discover/data/models/user_model.dart';

void main() {
  group('PhotoModel.toEntity', () {
    test('maps links.html to htmlLink', () {
      final model = _buildPhotoModel(
        links: const PhotoLinksModel(
          html: 'https://unsplash.com/photos/photo-1',
        ),
      );

      final entity = model.toEntity();

      expect(entity.htmlLink, 'https://unsplash.com/photos/photo-1');
    });

    test('keeps htmlLink null when links.html is missing', () {
      final model = _buildPhotoModel(
        links: const PhotoLinksModel(),
      );

      final entity = model.toEntity();

      expect(entity.htmlLink, isNull);
    });
  });
}

PhotoModel _buildPhotoModel({
  PhotoLinksModel? links,
}) {
  return PhotoModel(
    id: 'photo-1',
    createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
    width: 1200,
    height: 1600,
    color: '#AABBCC',
    urls: const UrlsModel(
      raw: 'https://example.com/raw.jpg',
      full: 'https://example.com/full.jpg',
      regular: 'https://example.com/regular.jpg',
      small: 'https://example.com/small.jpg',
      thumb: 'https://example.com/thumb.jpg',
    ),
    links: links,
    likes: 80,
    user: const UserModel(
      id: 'user-1',
      username: 'spaciba',
      name: 'Paula Poeira',
      profileImage: ProfileImageModel(
        small: 'https://example.com/profile-small.jpg',
        medium: 'https://example.com/profile-medium.jpg',
        large: 'https://example.com/profile-large.jpg',
      ),
      totalPhotos: 12,
      totalLikes: 30,
      totalCollections: 4,
    ),
  );
}
