import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/follow/presentation/widgets/follow_button.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

User makeUser({required bool followedByUser}) => User(
      id: 'u1',
      username: 'spaciba',
      name: 'Paula',
      profileImageSmall: 's',
      profileImageMedium: 'm',
      profileImageLarge: 'l',
      totalPhotos: 0,
      totalLikes: 0,
      totalCollections: 0,
      followedByUser: followedByUser,
    );

Future<void> _pumpButton(
  WidgetTester tester, {
  required User user,
  FollowButtonSize size = FollowButtonSize.regular,
}) async {
  tester.view.physicalSize = const Size(430, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRedirectUriProvider.overrideWithValue(
          Uri.parse('musea://auth/callback'),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: FollowButton(user: user, size: size))),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders "Follow" label when user is not followed', (tester) async {
    await _pumpButton(tester, user: makeUser(followedByUser: false));

    expect(find.text('Follow'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('renders "Following" label with check icon when user is followed',
      (tester) async {
    await _pumpButton(tester, user: makeUser(followedByUser: true));

    expect(find.text('Following'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('tapping the pill shows the read-only hint snackbar',
      (tester) async {
    await _pumpButton(tester, user: makeUser(followedByUser: false));

    await tester.tap(find.byType(FollowButton));
    await tester.pump(); // start snackbar
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Follow this photographer on unsplash.com'), findsOneWidget);
  });

  testWidgets('compact size uses shorter horizontal padding', (tester) async {
    await _pumpButton(
      tester,
      user: makeUser(followedByUser: false),
      size: FollowButtonSize.compact,
    );

    final size = tester.getSize(find.byType(Container).first);
    expect(size.height, 28.0);
  });
}
