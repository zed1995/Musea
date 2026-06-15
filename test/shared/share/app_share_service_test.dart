import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/shared/share/app_share_service.dart';

void main() {
  const user = User(
    id: 'user-1',
    username: 'spaciba',
    name: 'Paula Poeira',
    profileImageSmall: 'https://example.com/small.jpg',
    profileImageMedium: 'https://example.com/medium.jpg',
    profileImageLarge: 'https://example.com/large.jpg',
    totalPhotos: 3,
    totalLikes: 4,
    totalCollections: 5,
    links: UserLinks(
      html: 'https://unsplash.com/@spaciba',
    ),
  );

  final photo = Photo(
    id: 'photo-1',
    createdAt: DateTime(2024, 1, 1),
    width: 1000,
    height: 1200,
    color: '#ffffff',
    urlRaw: 'https://example.com/raw.jpg',
    urlFull: 'https://example.com/full.jpg',
    urlRegular: 'https://example.com/regular.jpg',
    urlSmall: 'https://example.com/small.jpg',
    urlThumb: 'https://example.com/thumb.jpg',
    likes: 1,
    downloads: 2,
    user: user,
    htmlLink: 'https://unsplash.com/photos/photo-1',
  );

  const collection = Collection(
    id: 'collection-1',
    title: 'United States',
    totalPhotos: 4,
    links: CollectionLinks(
      html: 'https://unsplash.com/collections/2208769/united-states',
    ),
  );

  test('resolvePhotoUrl returns canonical html link', () {
    expect(
      AppShareService.resolvePhotoUrl(photo),
      'https://unsplash.com/photos/photo-1',
    );
  });

  test('resolveCollectionUrl returns canonical html link', () {
    expect(
      AppShareService.resolveCollectionUrl(collection),
      'https://unsplash.com/collections/2208769/united-states',
    );
  });

  test('resolveUserUrl returns canonical html link', () {
    expect(
      AppShareService.resolveUserUrl(user),
      'https://unsplash.com/@spaciba',
    );
  });

  test('missing link resolves to failure result', () {
    final result = AppShareService.validateUrl(null);

    expect(result, const ShareResolutionFailure.missingUrl());
  });

  test('shareUrl shares validated url', () async {
    final sharePlus = _FakeSharePlusProxy();
    final service = AppShareService(sharePlus: sharePlus);

    final result =
        await service.shareUrl('https://unsplash.com/photos/photo-1');

    expect(
      result,
      isA<ShareResolutionSuccess>().having(
          (value) => value.url, 'url', 'https://unsplash.com/photos/photo-1'),
    );
    expect(
      sharePlus.sharedTexts,
      ['https://unsplash.com/photos/photo-1'],
    );
  });

  test('copyUrl copies validated url', () async {
    final clipboard = _FakeClipboardProxy();
    final service = AppShareService(clipboard: clipboard);

    final result = await service.copyUrl('https://unsplash.com/@spaciba');

    expect(
      result,
      isA<ShareResolutionSuccess>()
          .having((value) => value.url, 'url', 'https://unsplash.com/@spaciba'),
    );
    expect(clipboard.copiedTexts, ['https://unsplash.com/@spaciba']);
  });
}

class _FakeSharePlusProxy extends SharePlusProxy {
  final List<String> sharedTexts = <String>[];

  @override
  Future<void> share(String text) async {
    sharedTexts.add(text);
  }
}

class _FakeClipboardProxy extends ClipboardProxy {
  final List<String> copiedTexts = <String>[];

  @override
  Future<void> setData(String text) async {
    copiedTexts.add(text);
  }
}
