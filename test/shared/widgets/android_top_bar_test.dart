import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/shared/widgets/android_top_bar.dart';
import 'package:musea/shared/widgets/immersive_hero_app_bar.dart';

void main() {
  testWidgets('AndroidTopBar renders title and back affordance',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: AndroidTopBar(
            titleText: 'Settings',
            showBackButton: true,
          ),
        ),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('AndroidTopBar keeps title stable with trailing action slot',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AndroidTopBar(
            titleText: 'Search',
            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Search'), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
  });

  testWidgets('ImmersiveHeroAppBar renders back and action buttons',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Container(color: Colors.black),
              ImmersiveHeroAppBar(
                onBack: () {},
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.bookmark_border_rounded),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.ios_share_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
  });
}
