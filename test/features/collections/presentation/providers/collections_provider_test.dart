import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/domain/repositories/collection_repository.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/search/domain/entities/search_result.dart';

void main() {
  test('collectionPhotosProvider refetches after autoDispose removes cache',
      () async {
    final repository = _FakeCollectionRepository();
    final container = ProviderContainer(
      overrides: [
        collectionRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final firstSub = container.listen(
      collectionPhotosProvider('collection-1'),
      (_, __) {},
      fireImmediately: true,
    );
    final firstResult =
        await container.read(collectionPhotosProvider('collection-1').future);

    expect(firstResult, hasLength(0));
    expect(repository.photoRequests, 1);

    firstSub.close();
    await container.pump();

    repository.photos = [_buildPhoto(id: 'photo-1', name: 'Refetched')];

    final secondSub = container.listen(
      collectionPhotosProvider('collection-1'),
      (_, __) {},
      fireImmediately: true,
    );
    final secondResult =
        await container.read(collectionPhotosProvider('collection-1').future);

    expect(secondResult, hasLength(1));
    expect(repository.photoRequests, 2);

    secondSub.close();
  });
}

class _FakeCollectionRepository implements CollectionRepository {
  int photoRequests = 0;
  List<Photo> photos = const [];

  @override
  Future<Either<Failure, Collection>> getCollection(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Collection>>> getCollections({
    int page = 1,
    int perPage = 20,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Photo>>> getCollectionPhotos(
    String id, {
    int page = 1,
    int perPage = 20,
  }) async {
    photoRequests++;
    return Right(photos);
  }

  @override
  Future<Either<Failure, SearchCollectionsResult>> searchCollections(
    String query, {
    int page = 1,
    int perPage = 20,
  }) {
    throw UnimplementedError();
  }
}

Photo _buildPhoto({
  required String id,
  required String name,
}) {
  return Photo(
    id: id,
    createdAt: DateTime(2024, 1, 1),
    width: 1200,
    height: 1600,
    color: '#FFFFFF',
    urlRaw: 'https://example.com/$id-raw.jpg',
    urlFull: 'https://example.com/$id-full.jpg',
    urlRegular: 'https://example.com/$id-regular.jpg',
    urlSmall: 'https://example.com/$id-small.jpg',
    urlThumb: 'https://example.com/$id-thumb.jpg',
    likes: 12,
    downloads: 0,
    altDescription: name,
    user: const User(
      id: 'user-1',
      username: 'forest',
      name: 'Forest Archive',
      profileImageSmall: 'https://example.com/small.jpg',
      profileImageMedium: 'https://example.com/medium.jpg',
      profileImageLarge: 'https://example.com/large.jpg',
      totalPhotos: 20,
      totalLikes: 10,
      totalCollections: 4,
    ),
  );
}
