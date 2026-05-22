import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/profile/domain/repositories/profile_repository.dart';
import 'package:musea/features/profile/presentation/providers/profile_controller.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

Photo _fakePhoto(String id) => Photo(
      id: id,
      slug: id,
      createdAt: DateTime(2024, 1, 1),
      width: 100,
      height: 100,
      color: '#000000',
      urlRaw: 'https://example.com/raw.jpg',
      urlFull: 'https://example.com/full.jpg',
      urlRegular: 'https://example.com/regular.jpg',
      urlSmall: 'https://example.com/small.jpg',
      urlThumb: 'https://example.com/thumb.jpg',
      user: const User(
        id: 'u1',
        username: 'user1',
        name: 'User One',
        firstName: 'User',
        lastName: 'One',
        bio: null,
        location: null,
        profileImageSmall: 'https://example.com/s.jpg',
        profileImageMedium: 'https://example.com/m.jpg',
        profileImageLarge: 'https://example.com/l.jpg',
        totalPhotos: 10,
        totalLikes: 5,
        totalCollections: 2,
      ),
      likes: 0,
      likedByUser: false,
      downloads: 0,
    );

List<Photo> _fullPage(int startId) =>
    List.generate(20, (i) => _fakePhoto('${startId + i}'));

List<Collection> _fullCollectionPage(int startId) =>
    List.generate(20, (i) => Collection(
          id: 'c${startId + i}',
          title: 'Collection ${startId + i}',
          totalPhotos: 5,
        ));

void main() {
  late MockProfileRepository mockProfileRepository;

  setUp(() {
    mockProfileRepository = MockProfileRepository();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepository),
      ],
    );
  }

  group('UserPhotosController', () {
    test('loadInitial fetches first page', () async {
      final photos = _fullPage(1);
      when(() => mockProfileRepository.getUserPhotos('user1',
              page: 1, perPage: 20))
          .thenAnswer((_) async => Right(photos));

      final container = createContainer();
      final controller =
          container.read(userPhotosControllerProvider('user1').notifier);

      await controller.loadInitial();

      final state = container.read(userPhotosControllerProvider('user1'));
      expect(state.items.length, 20);
      expect(state.page, 1);
      expect(state.isLoading, false);
      expect(state.hasMorePages, true);
    });

    test('loadMore appends next page', () async {
      when(() => mockProfileRepository.getUserPhotos('user1',
              page: 1, perPage: 20))
          .thenAnswer((_) async => Right(_fullPage(1)));
      when(() => mockProfileRepository.getUserPhotos('user1',
              page: 2, perPage: 20))
          .thenAnswer((_) async => Right(_fullPage(21)));

      final container = createContainer();
      final controller =
          container.read(userPhotosControllerProvider('user1').notifier);

      await controller.loadInitial();
      await controller.loadMore();

      final state = container.read(userPhotosControllerProvider('user1'));
      expect(state.items.length, 40);
      expect(state.page, 2);
    });

    test('loadMore sets hasMorePages false when partial result', () async {
      when(() => mockProfileRepository.getUserPhotos('user1',
              page: 1, perPage: 20))
          .thenAnswer((_) async => Right(_fullPage(1)));
      when(() => mockProfileRepository.getUserPhotos('user1',
              page: 2, perPage: 20))
          .thenAnswer((_) async => Right([_fakePhoto('last')]));

      final container = createContainer();
      final controller =
          container.read(userPhotosControllerProvider('user1').notifier);

      await controller.loadInitial();
      await controller.loadMore();

      final state = container.read(userPhotosControllerProvider('user1'));
      expect(state.hasMorePages, false);
      expect(state.items.length, 21);
    });
  });

  group('UserCollectionsController', () {
    test('loadInitial fetches first page', () async {
      final collections = _fullCollectionPage(1);
      when(() => mockProfileRepository.getUserCollections('user1',
              page: 1, perPage: 20))
          .thenAnswer((_) async => Right(collections));

      final container = createContainer();
      final controller = container
          .read(userCollectionsControllerProvider('user1').notifier);

      await controller.loadInitial();

      final state =
          container.read(userCollectionsControllerProvider('user1'));
      expect(state.items.length, 20);
      expect(state.page, 1);
      expect(state.hasMorePages, true);
    });

    test('loadMore appends next page', () async {
      when(() => mockProfileRepository.getUserCollections('user1',
              page: 1, perPage: 20))
          .thenAnswer((_) async => Right(_fullCollectionPage(1)));
      when(() => mockProfileRepository.getUserCollections('user1',
              page: 2, perPage: 20))
          .thenAnswer((_) async => Right(_fullCollectionPage(21)));

      final container = createContainer();
      final controller = container
          .read(userCollectionsControllerProvider('user1').notifier);

      await controller.loadInitial();
      await controller.loadMore();

      final state =
          container.read(userCollectionsControllerProvider('user1'));
      expect(state.items.length, 40);
      expect(state.page, 2);
    });
  });

  group('UserLikesController', () {
    test('loadInitial fetches first page', () async {
      final photos = _fullPage(1);
      when(() => mockProfileRepository.getUserLikes('user1',
              page: 1, perPage: 20))
          .thenAnswer((_) async => Right(photos));

      final container = createContainer();
      final controller =
          container.read(userLikesControllerProvider('user1').notifier);

      await controller.loadInitial();

      final state = container.read(userLikesControllerProvider('user1'));
      expect(state.items.length, 20);
      expect(state.page, 1);
      expect(state.hasMorePages, true);
    });

    test('loadMore appends and detects end', () async {
      when(() => mockProfileRepository.getUserLikes('user1',
              page: 1, perPage: 20))
          .thenAnswer((_) async => Right(_fullPage(1)));
      when(() => mockProfileRepository.getUserLikes('user1',
              page: 2, perPage: 20))
          .thenAnswer((_) async => const Right([]));

      final container = createContainer();
      final controller =
          container.read(userLikesControllerProvider('user1').notifier);

      await controller.loadInitial();
      await controller.loadMore();

      final state = container.read(userLikesControllerProvider('user1'));
      expect(state.items.length, 20);
      expect(state.hasMorePages, false);
    });
  });
}
