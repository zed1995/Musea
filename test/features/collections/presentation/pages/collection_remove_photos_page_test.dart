import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/domain/repositories/collection_repository.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/collections/presentation/pages/collection_remove_photos_page.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/search/domain/entities/search_result.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

class _FakeCollectionRepository implements CollectionRepository {
  int photoRequests = 0;
  int removePhotoCalls = 0;
  List<String> removedPhotoIds = [];
  List<Photo> photos = const [];

  @override
  Future<Either<Failure, Collection>> getCollection(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Collection>>> getCollections({int page = 1, int perPage = 20}) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Collection>>> getUserCollections(String username, {int page = 1, int perPage = 20}) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Photo>>> getCollectionPhotos(String id, {int page = 1, int perPage = 20}) async {
    photoRequests++;
    return Right(photos);
  }

  @override
  Future<Either<Failure, SearchCollectionsResult>> searchCollections(String query, {int page = 1, int perPage = 20}) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Collection>> createCollection({required String title, String? description, bool? private}) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> addPhotoToCollection({required String collectionId, required String photoId}) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Collection>> updateCollection(String id, {String? title, String? description, bool? private}) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> deleteCollection(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> removePhotoFromCollection({required String collectionId, required String photoId}) async {
    removePhotoCalls++;
    removedPhotoIds.add(photoId);
    return const Right(null);
  }
}

Photo _photo(String id) => Photo(
      id: id,
      createdAt: DateTime(2024),
      width: 800,
      height: 800,
      color: '#fff',
      urlRaw: 'https://ex.com/$id.jpg',
      urlFull: 'https://ex.com/$id.jpg',
      urlRegular: 'https://ex.com/$id.jpg',
      urlSmall: 'https://ex.com/$id.jpg',
      urlThumb: 'https://ex.com/$id.jpg',
      likes: 0,
      downloads: 0,
      altDescription: id,
      user: const User(
        id: 'u1',
        username: 'u',
        name: 'U',
        profileImageSmall: '',
        profileImageMedium: '',
        profileImageLarge: '',
        totalPhotos: 0,
        totalLikes: 0,
        totalCollections: 0,
      ),
    );

void main() {
  late _FakeCollectionRepository fakeRepository;

  setUp(() {
    fakeRepository = _FakeCollectionRepository();
  });

  Widget buildApp(List<Photo> photos) =>
      ProviderScope(
        overrides: [
          collectionRepositoryProvider.overrideWithValue(fakeRepository),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CollectionRemovePhotosPage(
            collectionId: 'col-1',
            collectionTitle: 'Test',
          ),
        ),
      );

  Future<void> setupPhotos(WidgetTester tester, List<Photo> photos) async {
    fakeRepository.photos = photos;
    await tester.pumpWidget(buildApp(photos));
    await tester.pumpAndSettle();
  }

  testWidgets('renders batch mode header', (tester) async {
    await setupPhotos(tester, [_photo('p1')]);
    expect(find.text('Batch Mode'), findsOneWidget);
    expect(find.text('Remove photos'), findsOneWidget);
  });

  testWidgets('selecting photos updates count', (tester) async {
    await setupPhotos(tester, [_photo('p1'), _photo('p2'), _photo('p3')]);
    expect(find.text('0 selected'), findsOneWidget);
    expect(find.text('Remove 0 photos'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('photo_tile_p1')));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('photo_tile_p2')));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
  });

  testWidgets('done button resets selection', (tester) async {
    await setupPhotos(tester, [_photo('p1'), _photo('p2')]);
    await tester.tap(find.byKey(const ValueKey('photo_tile_p1')));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('0 selected'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('0 selected'), findsOneWidget);
  });

  testWidgets('remove button calls repository for each selected photo',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final photos = [_photo('p1'), _photo('p2'), _photo('p3')];
    await setupPhotos(tester, photos);

    await tester.tap(find.byKey(const ValueKey('photo_tile_p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('photo_tile_p2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('photo_tile_p3')));
    await tester.pumpAndSettle();

    expect(find.text('3 selected'), findsOneWidget);
    expect(find.text('Remove 3 photos'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Remove 3 photos'));
    await tester.pumpAndSettle();

    expect(fakeRepository.removePhotoCalls, 3);
    expect(fakeRepository.removedPhotoIds, contains('p1'));
    expect(fakeRepository.removedPhotoIds, contains('p2'));
    expect(fakeRepository.removedPhotoIds, contains('p3'));
  });
}
