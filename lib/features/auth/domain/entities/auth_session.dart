import 'package:musea/features/auth/domain/entities/auth_user.dart';

class OAuthToken {
  const OAuthToken({
    required this.accessToken,
    required this.tokenType,
    required this.scope,
    required this.createdAt,
  });

  final String accessToken;
  final String tokenType;
  final String scope;
  final int createdAt;
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.scope,
    required this.createdAt,
    required this.user,
    required this.lastProfileRefreshAt,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    return AuthSession(
      accessToken: json['accessToken'] as String? ?? '',
      tokenType: json['tokenType'] as String? ?? 'bearer',
      scope: json['scope'] as String? ?? '',
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      user: AuthUser.fromJson(
        rawUser is Map ? Map<String, dynamic>.from(rawUser) : const {},
      ),
      lastProfileRefreshAt: DateTime.tryParse(
            json['lastProfileRefreshAt'] as String? ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String accessToken;
  final String tokenType;
  final String scope;
  final int createdAt;
  final AuthUser user;
  final DateTime lastProfileRefreshAt;

  AuthSession copyWith({
    String? accessToken,
    String? tokenType,
    String? scope,
    int? createdAt,
    AuthUser? user,
    DateTime? lastProfileRefreshAt,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      tokenType: tokenType ?? this.tokenType,
      scope: scope ?? this.scope,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
      lastProfileRefreshAt: lastProfileRefreshAt ?? this.lastProfileRefreshAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'tokenType': tokenType,
      'scope': scope,
      'createdAt': createdAt,
      'user': user.toJson(),
      'lastProfileRefreshAt': lastProfileRefreshAt.toIso8601String(),
    };
  }
}
