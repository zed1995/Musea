import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/auth/presentation/widgets/auth_gate_sheet.dart';

class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}

void main() {
  testWidgets('auth gate sheet is presented on the root navigator',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final rootObserver = _RecordingNavigatorObserver();
    final nestedObserver = _RecordingNavigatorObserver();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authBootstrapSessionProvider.overrideWithValue(null),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
        ],
        child: MaterialApp(
          navigatorObservers: [rootObserver],
          home: Scaffold(
            bottomNavigationBar: const SizedBox(
              height: 64,
              child: ColoredBox(color: Colors.black12),
            ),
            body: Navigator(
              observers: [nestedObserver],
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (context) => Consumer(
                  builder: (context, ref, _) {
                    return Center(
                      child: ElevatedButton(
                        onPressed: () => showAuthGateSheet(context, ref),
                        child: const Text('Open sheet'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    expect(
      rootObserver.pushedRoutes.where((route) => route is PopupRoute).length,
      1,
    );
    expect(
      nestedObserver.pushedRoutes.where((route) => route is PopupRoute),
      isEmpty,
    );
  });
}
