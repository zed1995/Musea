import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/discover/domain/repositories/photo_repository.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/search/domain/entities/search_result.dart';
import 'package:musea/features/search/presentation/providers/search_controller.dart';

class MockPhotoRepository extends Mock implements PhotoRepository {}

Photo _fakePhoto(String id) => Photo(
      id: id,
      slug: id,
      createdAt: DateTime(2024, 1, 1),
      width: 100,
      height: 100,
      color: '#000000',
      blurHash: '',
      description: null,
      altDescription: null,
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
      views: null,
      exif: null,
      location: null,
      tags: const [],
    );

void main() {
  late MockPhotoRepository mockPhotoRepository;

  setUp(() {
    mockPhotoRepository = MockPhotoRepository();
  });

  group('SearchPhotosController', () {
    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          photoRepositoryProvider.overrideWithValue(mockPhotoRepository),
        ],
      );
    }

    test('initial state is empty with no loading', () {
      final container = createContainer();
      final state = container.read(searchPhotosControllerProvider);
      expect(state.items, isEmpty);
      expect(state.isLoading, false);
      expect(state.isLoadingMore, false);
      expect(state.hasMorePages, true);
      expect(state.page, 0);
    });

    test('search() loads first page and sets state', () async {
      final photos = [_fakePhoto('1'), _fakePhoto('2')];
      when(() => mockPhotoRepository.searchPhotos(
            'cats',
            page: 1,
            perPage: 20,
            orderBy: 'relevant',
            contentFilter: 'high',
          )).thenAnswer((_) async => Right(SearchPhotosResult(
            total: 50,
            totalPages: 3,
            results: photos,
          )));

      final container = createContainer();
      final controller =
          container.read(searchPhotosControllerProvider.notifier);

      await controller.search('cats');

      final state = container.read(searchPhotosControllerProvider);
      expect(state.items, photos);
      expect(state.page, 1);
      expect(state.isLoading, false);
      expect(state.hasMorePages, true);
    });

    test('loadMore() appends next page results', () async {
      final page1 = [_fakePhoto('1'), _fakePhoto('2')];
      final page2 = [_fakePhoto('3'), _fakePhoto('4')];

      when(() => mockPhotoRepository.searchPhotos(
            'cats',
            page: 1,
            perPage: 20,
            orderBy: 'relevant',
            contentFilter: 'high',
          )).thenAnswer((_) async => Right(SearchPhotosResult(
            total: 50,
            totalPages: 3,
            results: page1,
          )));
      when(() => mockPhotoRepository.searchPhotos(
            'cats',
            page: 2,
            perPage: 20,
            orderBy: 'relevant',
            contentFilter: 'high',
          )).thenAnswer((_) async => Right(SearchPhotosResult(
            total: 50,
            totalPages: 3,
            results: page2,
          )));

      final container = createContainer();
      final controller =
          container.read(searchPhotosControllerProvider.notifier);

      await controller.search('cats');
      await controller.loadMore();

      final state = container.read(searchPhotosControllerProvider);
      expect(state.items.length, 4);
      expect(state.page, 2);
      expect(state.hasMorePages, true);
    });

    test('loadMore() sets hasMorePages false on last page', () async {
      when(() => mockPhotoRepository.searchPhotos(
            'cats',
            page: 1,
            perPage: 20,
            orderBy: 'relevant',
            contentFilter: 'high',
          )).thenAnswer((_) async => Right(SearchPhotosResult(
            total: 2,
            totalPages: 1,
            results: [_fakePhoto('1'), _fakePhoto('2')],
          )));

      final container = createContainer();
      final controller =
          container.read(searchPhotosControllerProvider.notifier);

      await controller.search('cats');

      final state = container.read(searchPhotosControllerProvider);
      expect(state.hasMorePages, false);
    });

    test('search() resets state for new query', () async {
      when(() => mockPhotoRepository.searchPhotos(
            'cats',
            page: 1,
            perPage: 20,
            orderBy: 'relevant',
            contentFilter: 'high',
          )).thenAnswer((_) async => Right(SearchPhotosResult(
            total: 50,
            totalPages: 3,
            results: [_fakePhoto('1')],
          )));
      when(() => mockPhotoRepository.searchPhotos(
            'dogs',
            page: 1,
            perPage: 20,
            orderBy: 'relevant',
            contentFilter: 'high',
          )).thenAnswer((_) async => Right(SearchPhotosResult(
            total: 10,
            totalPages: 1,
            results: [_fakePhoto('d1')],
          )));

      final container = createContainer();
      final controller =
          container.read(searchPhotosControllerProvider.notifier);

      await controller.search('cats');
      await controller.search('dogs');

      final state = container.read(searchPhotosControllerProvider);
      expect(state.items.length, 1);
      expect(state.items.first.id, 'd1');
      expect(state.page, 1);
    });

    test('loadMore() does nothing when already loading', () async {
      when(() => mockPhotoRepository.searchPhotos(
            'cats',
            page: 1,
            perPage: 20,
            orderBy: 'relevant',
            contentFilter: 'high',
          )).thenAnswer((_) async => Right(SearchPhotosResult(
            total: 50,
            totalPages: 3,
            results: [_fakePhoto('1')],
          )));
      when(() => mockPhotoRepository.searchPhotos(
            'cats',
            page: 2,
            perPage: 20,
            orderBy: 'relevant',
            contentFilter: 'high',
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return Right(SearchPhotosResult(
          total: 50,
          totalPages: 3,
          results: [_fakePhoto('2')],
        ));
      });

      final container = createContainer();
      final controller =
          container.read(searchPhotosControllerProvider.notifier);

      await controller.search('cats');
      controller.loadMore();
      controller.loadMore();

      await Future.delayed(const Duration(milliseconds: 150));
      verify(() => mockPhotoRepository.searchPhotos(
            'cats',
            page: 2,
            perPage: 20,
            orderBy: 'relevant',
            contentFilter: 'high',
          )).called(1);
    });
  });
}
