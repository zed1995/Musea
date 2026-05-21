class AuthTokenStore {
  AuthTokenStore._();

  static final AuthTokenStore instance = AuthTokenStore._();

  String? _accessToken;

  String? get accessToken => _accessToken;

  void setAccessToken(String? accessToken) {
    final normalized = accessToken?.trim();
    _accessToken = (normalized == null || normalized.isEmpty)
        ? null
        : normalized;
  }

  void clear() {
    _accessToken = null;
  }
}
