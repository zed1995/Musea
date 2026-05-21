import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:musea/features/auth/presentation/pages/auth_callback_page.dart';
import 'package:musea/features/collections/presentation/pages/collection_detail_page.dart';
import 'package:musea/features/collections/presentation/pages/collections_page.dart';
import 'package:musea/features/discover/presentation/pages/discover_page.dart';
import 'package:musea/features/photo_detail/presentation/pages/photo_detail_page.dart';
import 'package:musea/features/photo_detail/presentation/pages/photo_viewer_page.dart';
import 'package:musea/features/profile/presentation/pages/mine_page.dart';
import 'package:musea/features/profile/presentation/pages/profile_page.dart';
import 'package:musea/router/detail_route_extras.dart';
import 'package:musea/features/search/presentation/pages/search_page.dart';
import 'package:musea/shared/widgets/bottom_nav_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/discover',
  debugLogDiagnostics: true,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/discover',
          name: 'discover',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DiscoverPage(),
          ),
        ),
        GoRoute(
          path: '/collections',
          name: 'collections',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CollectionsPage(),
          ),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileTabPage(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/callback',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return AuthCallbackPage(callbackUri: state.uri);
      },
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final initialQuery = state.uri.queryParameters['q'] ?? '';
        return SearchPage(initialQuery: initialQuery);
      },
    ),
    GoRoute(
      path: '/photo/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PhotoDetailPage(
          photoId: id,
          initialPhoto: photoDetailFromExtra(state.extra),
          hydrateDeferredDetailsFromInitialPhoto:
              photoDetailShouldHydrateFromExtra(state.extra),
        );
      },
    ),
    GoRoute(
      path: '/photo/:id/viewer',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return CustomTransitionPage<void>(
          key: state.pageKey,
          opaque: false,
          barrierDismissible: false,
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          child: PhotoViewerPage(
            photoId: id,
            initialPhoto: photoViewerFromExtra(state.extra),
            heroTag: photoViewerHeroTagFromExtra(state.extra),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: fade,
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/profile/:username',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final username = state.pathParameters['username']!;
        return ProfilePage(username: username);
      },
    ),
    GoRoute(
      path: '/collection/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CollectionDetailPage(
          collectionId: id,
          initialCollection: collectionDetailFromExtra(state.extra),
        );
      },
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class ProfileTabPage extends StatelessWidget {
  const ProfileTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MinePage();
  }
}
