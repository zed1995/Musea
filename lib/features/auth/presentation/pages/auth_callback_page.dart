import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';

class AuthCallbackPage extends ConsumerStatefulWidget {
  const AuthCallbackPage({
    super.key,
    required this.callbackUri,
  });

  final Uri callbackUri;

  @override
  ConsumerState<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends ConsumerState<AuthCallbackPage> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = ref.read(authControllerProvider.notifier);
      await controller.handleCallbackUri(_normalizedCallbackUri());
      if (!mounted) {
        return;
      }
      context.go('/profile');
    });
  }

  Uri _normalizedCallbackUri() {
    final uri = widget.callbackUri;
    if (uri.scheme.isNotEmpty) {
      return uri;
    }

    final expected = ref.read(authRedirectUriProvider);
    return expected.replace(query: uri.query);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      ),
    );
  }
}
