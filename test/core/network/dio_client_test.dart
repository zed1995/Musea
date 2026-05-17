import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:musea/core/network/dio_client.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late DioClient dioClient;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    dioClient = DioClient(mockDio);
  });

  group('DioClient', () {
    test('should perform GET request successfully', () async {
      final response = Response(
        data: {'test': 'data'},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/test'),
      );

      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => response);

      final result = await dioClient.get('/test');

      expect(result, equals({'test': 'data'}));
      verify(() => mockDio.get('/test')).called(1);
    });

    test('should throw ServerException on error status code', () async {
      when(() => mockDio.get(any()))
          .thenThrow(DioException(
            response: Response(
              statusCode: 404,
              requestOptions: RequestOptions(path: '/test'),
            ),
            requestOptions: RequestOptions(path: '/test'),
          ));

      expect(
        () => dioClient.get('/test'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
