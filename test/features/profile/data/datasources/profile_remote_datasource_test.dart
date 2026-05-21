import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/core/network/dio_client.dart';
import 'package:musea/features/profile/data/datasources/profile_remote_datasource.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient dioClient;
  late ProfileRemoteDataSourceImpl dataSource;

  setUp(() {
    dioClient = MockDioClient();
    dataSource = ProfileRemoteDataSourceImpl(dioClient);
  });

  test('getUserLikes does not pass manual authorization options', () async {
    when(
      () => dioClient.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => <Map<String, dynamic>>[
        {
          'id': 'photo-1',
          'created_at': '2024-01-01T00:00:00Z',
          'width': 1200,
          'height': 1600,
          'color': '#AABBCC',
          'urls': {
            'raw': 'https://example.com/raw.jpg',
            'full': 'https://example.com/full.jpg',
            'regular': 'https://example.com/regular.jpg',
            'small': 'https://example.com/small.jpg',
            'thumb': 'https://example.com/thumb.jpg',
          },
          'likes': 80,
          'downloads': 20,
          'user': {
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
        },
      ],
    );

    await dataSource.getUserLikes('spaciba');

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
