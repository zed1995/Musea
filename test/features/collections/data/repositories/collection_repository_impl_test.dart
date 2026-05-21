import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/core/errors/exceptions.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/collections/data/datasources/collection_remote_datasource.dart';
import 'package:musea/features/collections/data/models/collection_model.dart';
import 'package:musea/features/collections/data/repositories/collection_repository_impl.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';

class MockCollectionRemoteDataSource extends Mock
    implements CollectionRemoteDataSource {}

void main() {
  late MockCollectionRemoteDataSource mockDataSource;
  late CollectionRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockCollectionRemoteDataSource();
    repository = CollectionRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('createCollection', () {
    test('returns Right with Collection on successful creation', () async {
      final model = CollectionModel(
        id: 'new-1',
        title: 'Test',
        totalPhotos: 0,
      );

      when(
        () => mockDataSource.createCollection(
          title: any(named: 'title'),
          description: any(named: 'description'),
          private: any(named: 'private'),
        ),
      ).thenAnswer((_) async => model);

      final result = await repository.createCollection(
        title: 'Test',
        description: 'desc',
        private: true,
      );

      expect(result, isA<Right<Failure, Collection>>());
      expect(result.getOrElse(() => throw 'unexpected').title, 'Test');
    });

    test('returns Left with ServerFailure on ServerException', () async {
      when(
        () => mockDataSource.createCollection(
          title: any(named: 'title'),
          description: any(named: 'description'),
          private: any(named: 'private'),
        ),
      ).thenThrow(
        ServerException(statusCode: 500, message: 'Server error'),
      );

      final result = await repository.createCollection(title: 'Test');

      expect(result, isA<Left<Failure, Collection>>());
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left with NetworkFailure on NetworkException', () async {
      when(
        () => mockDataSource.createCollection(
          title: any(named: 'title'),
          description: any(named: 'description'),
          private: any(named: 'private'),
        ),
      ).thenThrow(NetworkException(message: 'No internet'));

      final result = await repository.createCollection(title: 'Test');

      expect(result, isA<Left<Failure, Collection>>());
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
