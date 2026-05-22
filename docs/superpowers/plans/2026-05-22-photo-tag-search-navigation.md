# Photo Tag → Search Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make tags on the photo detail page tappable, navigating to the search page with the tag as the query.

**Architecture:** Add `onTap` to the existing `_TagChip` private widget in `photo_detail_page.dart`, wrap it with `GestureDetector`, and navigate via `context.push('/search?q=<tag>')`. Follow the GoRouter pattern already used by the hero viewer test.

**Tech Stack:** Flutter, GoRouter, Riverpod, mocktail

---

### Task 1: Add onTap to _TagChip and write failing test

**Files:**
- Modify: `lib/features/photo_detail/presentation/pages/photo_detail_page.dart` (lines 178, 642-665)
- Test: `test/features/photo_detail/presentation/pages/photo_detail_page_test.dart`

- [ ] **Step 1: Write the failing test** — Add after the hero viewer test (line 394):

```dart
  testWidgets('PhotoDetailPage tag chip navigates to search page',
      (tester) async {
    final photo = buildPhoto(
      id: 'photo-tags',
      username: 'paula',
      name: 'Paula Poeira',
      color: '#5B7B9A',
      tags: const [
        {'title': 'Kyoto'},
        {'title': 'Temple'},
      ],
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => PhotoDetailPage(
            photoId: photo.id,
            initialPhoto: photo,
          ),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) {
            final query = state.uri.queryParameters['q'] ?? '';
            return MaterialPage(
              key: const ValueKey('search-page'),
              child: Text('SearchPage: $query'),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider(photo.id).overrideWith((ref) => photo),
          userPhotosProvider('paula').overrideWith((ref) => <Photo>[]),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pump();

    // Find the "Kyoto" tag and tap it
    await tester.tap(find.text('Kyoto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify navigation to search page with the tag as query
    expect(find.byKey(const ValueKey('search-page')), findsOneWidget);
    expect(find.text('SearchPage: Kyoto'), findsOneWidget);
  });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/photo_detail/presentation/pages/photo_detail_page_test.dart --name "tag chip" -v`

Expected: FAIL — `_TagChip` has no `onTap`, tapping does nothing, navigation never happens

- [ ] **Step 3: Implement _TagChip onTap and navigation**

In `_TagChip` (line 642-665):
- Add `VoidCallback? onTap` parameter
- Wrap existing `Container` with `GestureDetector`

```dart
class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF555555),
          ),
        ),
      ),
    );
  }
}
```

At the call site (line 178), change:
```dart
.map((tag) => _TagChip(label: tag.title))
```
to:
```dart
.map((tag) => _TagChip(
  label: tag.title,
  onTap: () => context.push(
    '/search?q=${Uri.encodeComponent(tag.title)}',
  ),
))
```

Add `import 'package:go_router/go_router.dart';` at the top of the file if not already present.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/photo_detail/presentation/pages/photo_detail_page_test.dart --name "tag chip" -v`

Expected: PASS

- [ ] **Step 5: Run flutter analyze**

Run: `flutter analyze`

Expected: No issues

- [ ] **Step 6: Run full test suite**

Run: `flutter test`

Expected: All tests pass
