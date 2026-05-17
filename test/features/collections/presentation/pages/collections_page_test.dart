import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/pages/collections_page.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A simple smoke test to verify the CollectionsPage renders without crashing.
void main() {
  testWidgets('CollectionsPage shows empty state when no collections', (tester) async {
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

    // Verify the empty state message renders
    expect(find.text('No collections'), findsOneWidget);
  });
}
