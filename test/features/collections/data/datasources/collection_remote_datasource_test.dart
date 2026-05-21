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
}
