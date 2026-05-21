import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/core/network/dio_client.dart';
import 'package:musea/features/auth/data/datasources/auth_remote_datasource.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient dioClient;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    dioClient = MockDioClient();
    dataSource = AuthRemoteDataSourceImpl(dioClient);
  });

  test('getCurrentUser does not pass manual authorization options', () async {
    when(
      () => dioClient.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'id': 'user-1',
        'username': 'spaciba',
        'name': 'Paula Poeira',
        'profile_image': {
          'small': 'https://example.com/small-profile.jpg',
          'medium': 'https://example.com/medium-profile.jpg',
          'large': 'https://example.com/large-profile.jpg',
        },
        'total_photos': 12,
        'total_likes': 30,
        'total_collections': 4,
      },
    );

    await dataSource.getCurrentUser();

    final captured = verify(
      () => dioClient.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: captureAny(named: 'options'),
      ),
    ).captured.single;

    expect(captured, isNull);
  });
}
