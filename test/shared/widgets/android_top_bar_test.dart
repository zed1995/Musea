import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/shared/widgets/android_top_bar.dart';
import 'package:musea/shared/widgets/immersive_hero_app_bar.dart';

void _noop() {}

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

  testWidgets('ImmersiveHeroAppBar renders white icons when not scrolled',
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

    // Back IconButton's color is white when the bar is not scrolled.
    final backButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.arrow_back_rounded),
    );
    expect(backButton.color, Colors.white);
  });

  testWidgets('ImmersiveHeroAppBar switches icons to gray900 when scrolled',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Container(color: Colors.white),
              const ImmersiveHeroAppBar(
                scrolled: true,
                onBack: _noop,
                actions: [
                  IconButton(
                    onPressed: _noop,
                    icon: Icon(Icons.bookmark_border_rounded),
                  ),
                  IconButton(
                    onPressed: _noop,
                    icon: Icon(Icons.ios_share_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final backButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.arrow_back_rounded),
    );
    expect(backButton.color, AppColors.gray900);
  });

  testWidgets(
      'ImmersiveHeroAppBar hides title by default and shows it when scrolled',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Container(color: Colors.white),
              const ImmersiveHeroAppBar(
                progress: 0.0,
                scrolled: false,
                title: 'Quiet light along the coast at sunset',
                onBack: _noop,
                actions: [
                  IconButton(
                    onPressed: _noop,
                    icon: Icon(Icons.bookmark_border_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final titleFinder = find.text('Quiet light along the coast at sunset');
    expect(titleFinder, findsOneWidget);

    final titleOpacity = tester.widget<Opacity>(
      find.byKey(const ValueKey('immersive-hero-app-bar-title')),
    );
    expect(titleOpacity.opacity, 0.0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Container(color: Colors.white),
              const ImmersiveHeroAppBar(
                progress: 1.0,
                scrolled: true,
                title: 'Quiet light along the coast at sunset',
                onBack: _noop,
                actions: [
                  IconButton(
                    onPressed: _noop,
                    icon: Icon(Icons.bookmark_border_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final scrolledTitleOpacity = tester.widget<Opacity>(
      find.byKey(const ValueKey('immersive-hero-app-bar-title')),
    );
    expect(scrolledTitleOpacity.opacity, 1.0);

    // Title is constrained to one line and ellipsis-truncated.
    final titleWidget = tester.widget<Text>(titleFinder);
    expect(titleWidget.maxLines, 1);
    expect(titleWidget.overflow, TextOverflow.ellipsis);
  });
}
