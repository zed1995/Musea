import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/auth/domain/entities/auth_session.dart';

void main() {
  test('fromJson accepts nested maps produced by Hive', () {
    final raw = <dynamic, dynamic>{
      'accessToken': 'token-123',
      'tokenType': 'bearer',
      'scope': 'public read_user',
      'createdAt': 123456,
      'user': <dynamic, dynamic>{
        'id': 'user-1',
        'username': 'spaciba',
        'displayName': 'Paula Poeira',
        'profileImageMedium': 'https://example.com/avatar-medium.jpg',
        'totalPhotos': 12,
        'totalLikes': 34,
        'totalCollections': 56,
      },
      'lastProfileRefreshAt': '2026-05-21T12:00:00.000',
    };

    final session = AuthSession.fromJson(Map<String, dynamic>.from(raw));

    expect(session.accessToken, 'token-123');
    expect(session.user.username, 'spaciba');
    expect(session.user.totalCollections, 56);
  });
}
