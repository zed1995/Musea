import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/core/network/dio_client.dart';
import 'package:musea/features/collections/data/datasources/collection_remote_datasource.dart';
import 'package:musea/features/collections/data/models/collection_model.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient dioClient;
  late CollectionRemoteDataSourceImpl dataSource;

  setUp(() {
    dioClient = MockDioClient();
    dataSource = CollectionRemoteDataSourceImpl(dioClient);
  });

  group('createCollection', () {
    test('sends POST with title, description, private and returns CollectionModel',
        () async {
      when(
        () => dioClient.post(
          '/collections',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{
            'id': 'new-collection-1',
            'title': 'Test Collection',
            'description': 'A test description',
            'private': true,
            'total_photos': 0,
          });

      final result = await dataSource.createCollection(
        title: 'Test Collection',
        description: 'A test description',
        private: true,
      );

      verify(
        () => dioClient.post(
          '/collections',
          data: {
            'title': 'Test Collection',
            'description': 'A test description',
            'private': true,
          },
        ),
      ).called(1);

      expect(result, isA<CollectionModel>());
      expect(result.title, 'Test Collection');
      expect(result.description, 'A test description');
      expect(result.isPrivate, isTrue);
    });

    test('sends POST with title only when optional params omitted', () async {
      when(
        () => dioClient.post(
          '/collections',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{
            'id': 'new-collection-2',
            'title': 'Minimal',
            'total_photos': 0,
          });

      final result = await dataSource.createCollection(title: 'Minimal');

      verify(
        () => dioClient.post(
          '/collections',
          data: {'title': 'Minimal'},
        ),
      ).called(1);

      expect(result.title, 'Minimal');
    });
  });

group('updateCollection', () {
    test('sends PUT with title, description, private and returns CollectionModel', () async {
      when(
        () => dioClient.put(
          '/collections/col-1',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{
            'id': 'col-1',
            'title': 'Updated Title',
            'description': 'Updated desc',
            'private': false,
            'total_photos': 5,
          });

      final result = await dataSource.updateCollection(
        'col-1',
        title: 'Updated Title',
        description: 'Updated desc',
        private: false,
      );

      verify(
        () => dioClient.put(
          '/collections/col-1',
          data: {
            'title': 'Updated Title',
            'description': 'Updated desc',
            'private': false,
          },
        ),
      ).called(1);

      expect(result, isA<CollectionModel>());
      expect(result.title, 'Updated Title');
    });

    test('sends PUT with partial fields when optional params omitted', () async {
      when(
        () => dioClient.put(
          '/collections/col-1',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{
            'id': 'col-1',
            'title': 'Just Title',
            'total_photos': 3,
          });

      final result = await dataSource.updateCollection(
        'col-1',
        title: 'Just Title',
      );

      verify(
        () => dioClient.put(
          '/collections/col-1',
          data: {'title': 'Just Title'},
        ),
      ).called(1);

      expect(result.title, 'Just Title');
    });
  });

  group('deleteCollection', () {
    test('sends DELETE and succeeds', () async {
      when(
        () => dioClient.delete('/collections/col-1'),
      ).thenAnswer((_) async => null);

      await dataSource.deleteCollection('col-1');

      verify(() => dioClient.delete('/collections/col-1')).called(1);
    });
  });

  group('removePhotoFromCollection', () {
    test('sends DELETE to /collections/{id}/remove with photo_id', () async {
      when(
        () => dioClient.delete(
          '/collections/col-1/remove',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => null);

      await dataSource.removePhotoFromCollection(
        collectionId: 'col-1',
        photoId: 'photo-123',
      );

      verify(
        () => dioClient.delete(
          '/collections/col-1/remove',
          data: {'photo_id': 'photo-123'},
        ),
      ).called(1);
    });
  });

group('addPhotoToCollection', () {
  test('sends POST to /collections/{id}/add with photo_id', () async {
    when(
      () => dioClient.post(
        '/collections/col-1/add',
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{'id': 'col-1'});

    await dataSource.addPhotoToCollection(
      collectionId: 'col-1',
      photoId: 'photo-123',
    );

    verify(
      () => dioClient.post(
        '/collections/col-1/add',
        data: {'photo_id': 'photo-123'},
      ),
    ).called(1);
  });
});
}
