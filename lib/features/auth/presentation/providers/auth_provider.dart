import 'dart:async';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:musea/core/constants/api_constants.dart';
import 'package:musea/core/network/providers.dart';
import 'package:musea/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:musea/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:musea/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:musea/features/auth/domain/entities/auth_session.dart';
import 'package:musea/features/auth/domain/repositories/auth_repository.dart';

final authBootstrapSessionProvider = Provider<AuthSession?>((ref) => null);
final authClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
final authRedirectUriProvider = Provider<Uri>((ref) {
  return Uri.parse(ApiConstants.redirectUri);
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    localDataSource: ref.watch(authLocalDataSourceProvider),
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

abstract class AuthLauncher {
  Future<void> launch(Uri uri);
}

class ExternalAuthLauncher implements AuthLauncher {
  @override
  Future<void> launch(Uri uri) async {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw Exception('Could not open Unsplash login');
    }
  }
}

final authLauncherProvider = Provider<AuthLauncher>((ref) {
  return ExternalAuthLauncher();
});

abstract class AuthLinkService {
  Future<Uri?> getInitialLink();
  Stream<Uri> get uriStream;
}

class AppLinksAuthLinkService implements AuthLinkService {
  AppLinksAuthLinkService([AppLinks? appLinks])
      : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Future<Uri?> getInitialLink() => _appLinks.getInitialLink();

  @override
  Stream<Uri> get uriStream => _appLinks.uriLinkStream;
}

final authLinkServiceProvider = Provider<AuthLinkService>((ref) {
  return AppLinksAuthLinkService();
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    repository: ref.watch(authRepositoryProvider),
    launcher: ref.watch(authLauncherProvider),
    now: ref.watch(authClockProvider),
    expectedRedirectUri: ref.watch(authRedirectUriProvider),
    initialSession: ref.watch(authBootstrapSessionProvider),
  );
});

final authLinkListenerProvider = Provider<void>((ref) {
  final linkService = ref.watch(authLinkServiceProvider);
  final controller = ref.read(authControllerProvider.notifier);

  unawaited(() async {
    final initialUri = await linkService.getInitialLink();
    if (initialUri != null) {
      await controller.handleCallbackUri(initialUri);
    }
  }());

  final subscription = linkService.uriStream.listen((uri) async {
    await controller.handleCallbackUri(uri);
  });

  ref.onDispose(subscription.cancel);
});

class AuthState {
  const AuthState({
    this.session,
    this.isAuthorizing = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  final AuthSession? session;
  final bool isAuthorizing;
  final bool isRefreshing;
  final String? errorMessage;

  bool get isAuthenticated => session != null;

  AuthState copyWith({
    AuthSession? session,
    bool? isAuthorizing,
    bool? isRefreshing,
    Object? errorMessage = _sentinel,
  }) {
    return AuthState(
      session: session ?? this.session,
      isAuthorizing: isAuthorizing ?? this.isAuthorizing,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _sentinel = Object();

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthRepository repository,
    required AuthLauncher launcher,
    required DateTime Function() now,
    required Uri expectedRedirectUri,
    AuthSession? initialSession,
  })  : _repository = repository,
        _launcher = launcher,
        _now = now,
        _expectedRedirectUri = expectedRedirectUri,
        super(AuthState(session: initialSession));

  static const Duration refreshThrottle = Duration(minutes: 10);

  final AuthRepository _repository;
  final AuthLauncher _launcher;
  final DateTime Function() _now;
  final Uri _expectedRedirectUri;
  final Set<String> _inFlightCallbackFingerprints = <String>{};
  final Set<String> _completedCallbackFingerprints = <String>{};

  Future<void> beginSignIn() async {
    final pendingState = _generatePendingState();
    final authorizationUri =
        _repository.buildAuthorizationUri(state: pendingState);

    await _repository.savePendingOAuthState(pendingState);
    state = state.copyWith(
      isAuthorizing: true,
      errorMessage: null,
    );

    try {
      await _launcher.launch(authorizationUri);
    } catch (error) {
      await _repository.savePendingOAuthState(null);
      state = state.copyWith(
        isAuthorizing: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> handleCallbackUri(Uri uri) async {
    if (!_isExpectedCallback(uri)) {
      return;
    }

    final fingerprint = _callbackFingerprint(uri);
    if (_completedCallbackFingerprints.contains(fingerprint) ||
        _inFlightCallbackFingerprints.contains(fingerprint)) {
      return;
    }
    _inFlightCallbackFingerprints.add(fingerprint);

    try {
      final error = uri.queryParameters['error'];
      if (error != null) {
        await _repository.savePendingOAuthState(null);
        state = state.copyWith(
          isAuthorizing: false,
          errorMessage: error == 'access_denied'
              ? null
              : (uri.queryParameters['error_description'] ?? error),
        );
        _completedCallbackFingerprints.add(fingerprint);
        return;
      }

      final code = uri.queryParameters['code'];
      final callbackState = uri.queryParameters['state'];
      final storedState = await _repository.getPendingOAuthState();
      if (code == null ||
          callbackState == null ||
          storedState != callbackState) {
        state = state.copyWith(
          isAuthorizing: false,
          errorMessage: 'Could not verify the Unsplash sign-in callback.',
        );
        return;
      }

      final token = await _repository.exchangeCodeForToken(code);
      final user = await _repository.fetchCurrentUser(token.accessToken);
      final session = AuthSession(
        accessToken: token.accessToken,
        tokenType: token.tokenType,
        scope: token.scope,
        createdAt: token.createdAt,
        user: user,
        lastProfileRefreshAt: _now(),
      );
      await _repository.saveSession(session);
      await _repository.savePendingOAuthState(null);
      _completedCallbackFingerprints.add(fingerprint);
      state = AuthState(session: session);
    } catch (error) {
      state = state.copyWith(
        isAuthorizing: false,
        errorMessage: error.toString(),
      );
    } finally {
      _inFlightCallbackFingerprints.remove(fingerprint);
    }
  }

  Future<void> refreshIfNeeded({bool force = false}) async {
    final session = state.session;
    if (session == null || state.isRefreshing) {
      return;
    }

    final staleEnough =
        _now().difference(session.lastProfileRefreshAt) >= refreshThrottle;
    if (!force && !staleEnough) {
      return;
    }

    state = state.copyWith(
      isRefreshing: true,
      errorMessage: null,
    );

    try {
      final user = await _repository.fetchCurrentUser(session.accessToken);
      final refreshedSession = session.copyWith(
        user: user,
        lastProfileRefreshAt: _now(),
      );
      await _repository.saveSession(refreshedSession);
      state = state.copyWith(
        session: refreshedSession,
        isRefreshing: false,
      );
    } catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await _repository.clearSession();
    await _repository.savePendingOAuthState(null);
    state = const AuthState();
  }

  String _generatePendingState() {
    final random = Random();
    return '${_now().microsecondsSinceEpoch}-${random.nextInt(1 << 32)}';
  }

  bool _isExpectedCallback(Uri uri) {
    return uri.scheme == _expectedRedirectUri.scheme &&
        uri.host == _expectedRedirectUri.host &&
        uri.path == _expectedRedirectUri.path;
  }

  String _callbackFingerprint(Uri uri) {
    final code = uri.queryParameters['code'] ?? '';
    final state = uri.queryParameters['state'] ?? '';
    final error = uri.queryParameters['error'] ?? '';
    return '${uri.scheme}://${uri.host}${uri.path}?code=$code&state=$state&error=$error';
  }
}
