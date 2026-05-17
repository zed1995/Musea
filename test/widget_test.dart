import 'package:flutter_test/flutter_test.dart';
import 'package:musea/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MuseaApp(),
      ),
    );
  });
}
