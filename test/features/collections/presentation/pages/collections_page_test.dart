import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/pages/collections_page.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A simple smoke test to verify the CollectionsPage renders without crashing.
/// The collectionsProvider is overridden with a synchronous function that
/// returns an empty list (not wrapped in a Future), avoiding real network
/// calls and their pending timers.
void main() {
  testWidgets('CollectionsPage renders with app bar title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionsProvider(1).overrideWith(
            (ref) => <Collection>[],
          ),
        ],
        child: const MaterialApp(
          home: CollectionsPage(),
        ),
      ),
    );

    // Verify the app bar title renders
    expect(find.text('Collections'), findsOneWidget);
  });
}
