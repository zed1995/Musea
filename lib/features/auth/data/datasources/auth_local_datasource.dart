import 'package:hive_flutter/hive_flutter.dart';
import 'package:musea/features/auth/domain/entities/auth_session.dart';

abstract class AuthLocalDataSource {
  Future<AuthSession?> readSession();
  Future<void> saveSession(AuthSession session);
  Future<void> clearSession();
  Future<String?> readPendingOAuthState();
  Future<void> savePendingOAuthState(String? state);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _boxName = 'auth_session';
  static const String _sessionKey = 'session';
  static const String _pendingStateKey = 'pending_oauth_state';

  Box<dynamic>? _box;

  Future<Box<dynamic>> get box async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  @override
  Future<void> clearSession() async {
    final authBox = await box;
    await authBox.delete(_sessionKey);
  }

  @override
  Future<String?> readPendingOAuthState() async {
    final authBox = await box;
    return authBox.get(_pendingStateKey) as String?;
  }

  @override
  Future<AuthSession?> readSession() async {
    final authBox = await box;
    final raw = authBox.get(_sessionKey);
    if (raw is! Map) return null;
    return AuthSession.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> savePendingOAuthState(String? state) async {
    final authBox = await box;
    if (state == null) {
      await authBox.delete(_pendingStateKey);
      return;
    }
    await authBox.put(_pendingStateKey, state);
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    final authBox = await box;
    await authBox.put(_sessionKey, session.toJson());
  }
}
