# Profile And Collection Detail Pages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the dedicated profile and collection detail pages so they match the prototype structure while continuing to use the current Flutter routes and providers.

**Architecture:** Keep the routing and provider graph unchanged, and concentrate the work inside the two page widgets plus targeted widget tests. Replace the generic detail layouts with page-specific private widgets, sticky sections, and honest fallback states for unsupported data areas.

**Tech Stack:** Flutter, Riverpod, GoRouter, widget tests

---

### Task 1: Add Failing Profile Detail Page Tests

**Files:**
- Create: `test/features/profile/presentation/pages/profile_page_test.dart`
- Modify: `lib/features/profile/presentation/pages/profile_page.dart`
- Test: `test/features/profile/presentation/pages/profile_page_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('ProfilePage renders prototype detail structure', (tester) async {
  final user = User(
    id: 'user-1',
    username: 'spaciba',
    name: 'Paula Poeira',
    bio: 'Visual storyteller',
    location: 'Costa da Caparica',
    profileImageSmall: 'https://example.com/small.jpg',
    profileImageMedium: 'https://example.com/medium.jpg',
    profileImageLarge: 'https://example.com/large.jpg',
    totalPhotos: 14,
    totalLikes: 114769,
    totalCollections: 58,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProfileProvider('spaciba').overrideWith((ref) => user),
        userPhotosProvider('spaciba').overrideWith((ref) => <Photo>[]),
      ],
      child: const MaterialApp(home: ProfilePage(username: 'spaciba')),
    ),
  );

  await tester.pump();

  expect(find.text('Paula Poeira'), findsOneWidget);
  expect(find.text('Follow'), findsOneWidget);
  expect(find.text('Photos'), findsAtLeastNWidgets(1));
  expect(find.text('Collections'), findsAtLeastNWidgets(1));
  expect(find.text('Likes'), findsAtLeastNWidgets(1));
  expect(find.textContaining('@spaciba'), findsOneWidget);
}

testWidgets('ProfilePage omits missing optional copy safely', (tester) async {
  final user = User(
    id: 'user-2',
    username: 'blank',
    name: 'Blank User',
    profileImageSmall: 'https://example.com/small.jpg',
    profileImageMedium: 'https://example.com/medium.jpg',
    profileImageLarge: 'https://example.com/large.jpg',
    totalPhotos: 0,
    totalLikes: 0,
    totalCollections: 0,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProfileProvider('blank').overrideWith((ref) => user),
        userPhotosProvider('blank').overrideWith((ref) => <Photo>[]),
      ],
      child: const MaterialApp(home: ProfilePage(username: 'blank')),
    ),
  );

  await tester.pump();

  expect(find.text('Blank User'), findsOneWidget);
  expect(find.text('No public photos yet'), findsOneWidget);
  expect(find.textContaining('@blank'), findsOneWidget);
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/profile/presentation/pages/profile_page_test.dart`
Expected: FAIL because the current page does not render the prototype detail structure or the new empty-state copy.

- [ ] **Step 3: Write minimal implementation**

```dart
class _ProfileContent extends StatefulWidget {
  const _ProfileContent({required this.user, required this.photosAsync});
}

enum _ProfileSegment { photos, collections, likes }

// Build a light hero, sticky segmented control, a real photos section,
// and shell sections for unsupported collections/likes data.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/profile/presentation/pages/profile_page_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/features/profile/presentation/pages/profile_page_test.dart lib/features/profile/presentation/pages/profile_page.dart
git commit -m "feat: align profile detail page with prototype"
```

### Task 2: Add Failing Collection Detail Page Tests

**Files:**
- Create: `test/features/collections/presentation/pages/collection_detail_page_test.dart`
- Modify: `lib/features/collections/presentation/pages/collection_detail_page.dart`
- Test: `test/features/collections/presentation/pages/collection_detail_page_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('CollectionDetailPage renders prototype detail sections', (tester) async {
  final curator = User(
    id: 'user-1',
    username: 'spaciba',
    name: 'Paula Poeira',
    profileImageSmall: 'https://example.com/small.jpg',
    profileImageMedium: 'https://example.com/medium.jpg',
    profileImageLarge: 'https://example.com/large.jpg',
    totalPhotos: 14,
    totalLikes: 10,
    totalCollections: 58,
  );

  final collection = Collection(
    id: 'collection-1',
    title: 'United States',
    description: 'Curated travel references.',
    totalPhotos: 316,
    previewPhotos: const [],
    user: curator,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        collectionDetailProvider('collection-1').overrideWith((ref) => collection),
        collectionPhotosProvider('collection-1').overrideWith((ref) => <Photo>[]),
      ],
      child: const MaterialApp(home: CollectionDetailPage(collectionId: 'collection-1')),
    ),
  );

  await tester.pump();

  expect(find.text('United States'), findsOneWidget);
  expect(find.text('Collection Summary'), findsOneWidget);
  expect(find.text('Preview'), findsOneWidget);
  expect(find.text('Collection Facts'), findsOneWidget);
  expect(find.text('Follow'), findsOneWidget);
}

testWidgets('CollectionDetailPage shows fallback copy when description is missing', (tester) async {
  final collection = Collection(
    id: 'collection-2',
    title: 'No Description',
    totalPhotos: 0,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        collectionDetailProvider('collection-2').overrideWith((ref) => collection),
        collectionPhotosProvider('collection-2').overrideWith((ref) => <Photo>[]),
      ],
      child: const MaterialApp(home: CollectionDetailPage(collectionId: 'collection-2')),
    ),
  );

  await tester.pump();

  expect(find.textContaining('No curator description'), findsOneWidget);
  expect(find.text('No photos in this collection yet'), findsOneWidget);
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/collections/presentation/pages/collection_detail_page_test.dart`
Expected: FAIL because the current page does not render the prototype cards or the new fallback copy.

- [ ] **Step 3: Write minimal implementation**

```dart
class CollectionDetailPage extends ConsumerWidget {
  // Build immersive hero, summary card, preview card, facts card,
  // and a detail-page-specific feed/empty state below.
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/collections/presentation/pages/collection_detail_page_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/features/collections/presentation/pages/collection_detail_page_test.dart lib/features/collections/presentation/pages/collection_detail_page.dart
git commit -m "feat: align collection detail page with prototype"
```

### Task 3: Run Focused Regression Checks

**Files:**
- Modify: `lib/features/profile/presentation/pages/profile_page.dart`
- Modify: `lib/features/collections/presentation/pages/collection_detail_page.dart`
- Test: `test/features/profile/presentation/pages/profile_page_test.dart`
- Test: `test/features/collections/presentation/pages/collection_detail_page_test.dart`
- Test: `test/features/collections/presentation/pages/collections_page_test.dart`

- [ ] **Step 1: Run the new page tests together**

```bash
flutter test \
  test/features/profile/presentation/pages/profile_page_test.dart \
  test/features/collections/presentation/pages/collection_detail_page_test.dart
```

Expected: PASS

- [ ] **Step 2: Run an adjacent regression test**

```bash
flutter test test/features/collections/presentation/pages/collections_page_test.dart
```

Expected: PASS

- [ ] **Step 3: Run formatter on modified Dart files**

```bash
dart format \
  lib/features/profile/presentation/pages/profile_page.dart \
  lib/features/collections/presentation/pages/collection_detail_page.dart \
  test/features/profile/presentation/pages/profile_page_test.dart \
  test/features/collections/presentation/pages/collection_detail_page_test.dart
```

Expected: files reformatted with no errors

- [ ] **Step 4: Re-run the focused test suite after formatting**

```bash
flutter test \
  test/features/profile/presentation/pages/profile_page_test.dart \
  test/features/collections/presentation/pages/collection_detail_page_test.dart \
  test/features/collections/presentation/pages/collections_page_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/profile/presentation/pages/profile_page.dart \
  lib/features/collections/presentation/pages/collection_detail_page.dart \
  test/features/profile/presentation/pages/profile_page_test.dart \
  test/features/collections/presentation/pages/collection_detail_page_test.dart
git commit -m "test: cover detail page prototype layouts"
```
