# Detail Prefetch And Progressive Hydration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make photo and collection detail pages render immediately from list-known data, then progressively hydrate detail-only fields in the background without losing already-visible content on partial failures.

**Architecture:** Keep route paths unchanged and pass optional `Photo` / `Collection` objects through `GoRouter` extras for in-app navigation. Detail pages will accept optional initial entities, render a stable first frame from that data, then layer in async detail results and section-level skeleton/error states only for deferred content.

**Tech Stack:** Flutter, Riverpod, GoRouter, widget tests

---

## File Map

- Modify: `lib/router/app_router.dart`
  Route builders read typed extras and pass optional initial entities into detail pages.
- Modify: `lib/shared/widgets/photo_grid.dart`
  Photo grid navigation sends `Photo` through router `extra`.
- Modify: `lib/shared/widgets/collection_card.dart`
  Collection navigation sends `Collection` through router `extra`.
- Modify: `lib/features/discover/presentation/pages/discover_page.dart`
  Discover page photo taps pass the already-loaded `Photo`.
- Modify: `lib/features/profile/presentation/pages/profile_page.dart`
  Profile page photo and collection taps pass existing entities.
- Modify: `lib/features/photo_detail/presentation/pages/photo_detail_page.dart`
  Add optional initial photo support, section-level hydration, and local fallback states.
- Modify: `lib/features/collections/presentation/pages/collection_detail_page.dart`
  Add optional initial collection support, section-level hydration, and local fallback states.
- Create: `lib/router/detail_route_extras.dart`
  Small typed wrappers/helpers for router extras so pages do not parse raw `Object?`.
- Create: `test/features/photo_detail/presentation/pages/photo_detail_progressive_test.dart`
  New progressive hydration tests for photo detail.
- Modify: `test/router/app_router_test.dart`
  Add route-extra navigation assertions for photo and collection.
- Modify: `test/features/collections/presentation/pages/collection_detail_page_test.dart`
  Cover initial collection render, deep link loading, and partial-failure behavior.

---

### Task 1: Pass Initial Entities Through Routing

**Files:**
- Create: `lib/router/detail_route_extras.dart`
- Modify: `lib/router/app_router.dart`
- Modify: `lib/shared/widgets/photo_grid.dart`
- Modify: `lib/shared/widgets/collection_card.dart`
- Modify: `lib/features/discover/presentation/pages/discover_page.dart`
- Modify: `lib/features/profile/presentation/pages/profile_page.dart`
- Test: `test/router/app_router_test.dart`

- [ ] **Step 1: Write the failing router test for photo and collection extras**

```dart
testWidgets('router forwards photo and collection extras into detail pages',
    (tester) async {
  final router = buildTestRouter();

  router.go('/discover');
  await tester.pumpWidget(
    ProviderScope(
      overrides: buildHomeOverrides(photo: photo, collection: collection),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Forest Archive').first);
  await tester.pumpAndSettle();

  expect(find.text('Forest canopy'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/router/app_router_test.dart`
Expected: FAIL because route builders still ignore `state.extra`.

- [ ] **Step 3: Add typed route extras helper**

```dart
class PhotoDetailExtra {
  const PhotoDetailExtra({required this.photo});
  final Photo photo;
}

class CollectionDetailExtra {
  const CollectionDetailExtra({required this.collection});
  final Collection collection;
}
```

- [ ] **Step 4: Update route builders to pass optional initial entities**

```dart
final extra = state.extra;
final initialPhoto =
    extra is PhotoDetailExtra ? extra.photo : null;

return PhotoDetailPage(
  photoId: id,
  initialPhoto: initialPhoto,
);
```

```dart
onTap: () => context.push(
  '/photo/${photo.id}',
  extra: PhotoDetailExtra(photo: photo),
);
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/router/app_router_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/router/app_router.dart lib/router/detail_route_extras.dart lib/shared/widgets/photo_grid.dart lib/shared/widgets/collection_card.dart lib/features/discover/presentation/pages/discover_page.dart lib/features/profile/presentation/pages/profile_page.dart test/router/app_router_test.dart
git commit -m "feat: pass initial detail entities through routing"
```

---

### Task 2: Progressive Hydration For Photo Detail

**Files:**
- Modify: `lib/features/photo_detail/presentation/pages/photo_detail_page.dart`
- Create: `test/features/photo_detail/presentation/pages/photo_detail_progressive_test.dart`

- [ ] **Step 1: Write the failing photo progressive hydration tests**

```dart
testWidgets('photo detail renders initial photo immediately while detail hydrates',
    (tester) async {
  final pending = Completer<Photo>();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        photoDetailProvider('photo-1').overrideWith((ref) => pending.future),
      ],
      child: MaterialApp(
        home: PhotoDetailPage(
          photoId: 'photo-1',
          initialPhoto: initialPhoto,
        ),
      ),
    ),
  );

  expect(find.text(initialPhoto.user.name), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(find.byKey(const ValueKey('photo-detail-exif-skeleton')), findsOneWidget);
});
```

```dart
testWidgets('photo detail keeps initial content when hydration fails',
    (tester) async {
  await tester.pumpWidget(...);
  expect(find.text(initialPhoto.user.name), findsOneWidget);
  expect(find.text('Retry loading details'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/photo_detail/presentation/pages/photo_detail_progressive_test.dart`
Expected: FAIL because `PhotoDetailPage` requires a full async success before building the page.

- [ ] **Step 3: Add initial-photo and hydrated-photo merge flow**

```dart
class PhotoDetailPage extends ConsumerWidget {
  const PhotoDetailPage({
    super.key,
    required this.photoId,
    this.initialPhoto,
  });

  final String photoId;
  final Photo? initialPhoto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoAsync = ref.watch(photoDetailProvider(photoId));
    final resolvedPhoto = photoAsync.valueOrNull ?? initialPhoto;
    ...
  }
}
```

- [ ] **Step 4: Render section-level placeholders and local retry states**

```dart
if (resolvedPhoto == null && photoAsync.isLoading) {
  return const Scaffold(body: Center(child: LoadingIndicator()));
}

if (resolvedPhoto != null) {
  return _PhotoDetailContent(
    photo: resolvedPhoto,
    showExifSkeleton: photoAsync.isLoading && resolvedPhoto.exif == null,
    showTagSkeleton: photoAsync.isLoading && resolvedPhoto.tags.isEmpty,
    deferredError: photoAsync.hasError,
    onRetryDeferred: () => ref.invalidate(photoDetailProvider(photoId)),
  );
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/photo_detail/presentation/pages/photo_detail_progressive_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/photo_detail/presentation/pages/photo_detail_page.dart test/features/photo_detail/presentation/pages/photo_detail_progressive_test.dart
git commit -m "feat: progressively hydrate photo detail from initial route data"
```

---

### Task 3: Progressive Hydration For Collection Detail

**Files:**
- Modify: `lib/features/collections/presentation/pages/collection_detail_page.dart`
- Modify: `test/features/collections/presentation/pages/collection_detail_page_test.dart`

- [ ] **Step 1: Write the failing collection progressive hydration tests**

```dart
testWidgets('collection detail renders initial collection immediately',
    (tester) async {
  final pending = Completer<Collection>();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        collectionDetailProvider('collection-1').overrideWith((ref) => pending.future),
        collectionPhotosProvider('collection-1').overrideWith((ref) => <Photo>[]),
      ],
      child: const MaterialApp(
        home: CollectionDetailPage(
          collectionId: 'collection-1',
          initialCollection: initialCollection,
        ),
      ),
    ),
  );

  expect(find.text('United States'), findsOneWidget);
  expect(find.byKey(const ValueKey('collection-detail-facts-skeleton')), findsOneWidget);
});
```

```dart
testWidgets('collection detail keeps initial hero when hydration fails',
    (tester) async {
  await tester.pumpWidget(...);
  expect(find.text('United States'), findsOneWidget);
  expect(find.text('Retry loading details'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/collections/presentation/pages/collection_detail_page_test.dart`
Expected: FAIL because the page still uses full-page `when()` loading/error behavior.

- [ ] **Step 3: Add optional initial collection support and keep feed behavior separate**

```dart
class CollectionDetailPage extends ConsumerWidget {
  const CollectionDetailPage({
    super.key,
    required this.collectionId,
    this.initialCollection,
  });

  final String collectionId;
  final Collection? initialCollection;
}
```

```dart
final collectionAsync = ref.watch(collectionDetailProvider(collectionId));
final resolvedCollection = collectionAsync.valueOrNull ?? initialCollection;
```

- [ ] **Step 4: Introduce collection section skeletons and deferred retry**

```dart
if (resolvedCollection != null) {
  return _CollectionDetailContent(
    collection: resolvedCollection,
    photosAsync: photosAsync,
    showFactsSkeleton: collectionAsync.isLoading && !_hasCompleteFacts(resolvedCollection),
    deferredError: collectionAsync.hasError,
    onRetryDeferred: () => ref.invalidate(collectionDetailProvider(collectionId)),
  );
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/collections/presentation/pages/collection_detail_page_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/collections/presentation/pages/collection_detail_page.dart test/features/collections/presentation/pages/collection_detail_page_test.dart
git commit -m "feat: progressively hydrate collection detail from initial route data"
```

---

### Task 4: Integration Verification And Cleanup

**Files:**
- Modify: `test/router/app_router_test.dart`
- Modify: `test/features/collections/presentation/pages/collections_page_test.dart`
- Modify: `test/features/photo_detail/presentation/pages/photo_detail_page_test.dart`
- Modify: `test/features/photo_detail/presentation/pages/photo_detail_progressive_test.dart`
- Modify: `test/features/collections/presentation/pages/collection_detail_page_test.dart`

- [ ] **Step 1: Add deep-link regression coverage**

```dart
testWidgets('photo detail still shows full-page loading when no initial photo exists',
    (tester) async {
  final pending = Completer<Photo>();
  await tester.pumpWidget(...);
  expect(find.byType(LoadingIndicator), findsOneWidget);
});
```

```dart
testWidgets('collection detail still shows full-page error when no initial collection exists',
    (tester) async {
  await tester.pumpWidget(...);
  expect(find.byType(ErrorState), findsOneWidget);
});
```

- [ ] **Step 2: Run focused test suite**

Run:

```bash
flutter test test/router/app_router_test.dart test/features/photo_detail/presentation/pages/photo_detail_page_test.dart test/features/photo_detail/presentation/pages/photo_detail_progressive_test.dart test/features/collections/presentation/pages/collection_detail_page_test.dart test/features/collections/presentation/pages/collections_page_test.dart
```

Expected: PASS

- [ ] **Step 3: Run static analysis on touched files**

Run:

```bash
flutter analyze lib/router/app_router.dart lib/router/detail_route_extras.dart lib/shared/widgets/photo_grid.dart lib/shared/widgets/collection_card.dart lib/features/discover/presentation/pages/discover_page.dart lib/features/profile/presentation/pages/profile_page.dart lib/features/photo_detail/presentation/pages/photo_detail_page.dart lib/features/collections/presentation/pages/collection_detail_page.dart test/router/app_router_test.dart test/features/photo_detail/presentation/pages/photo_detail_progressive_test.dart test/features/collections/presentation/pages/collection_detail_page_test.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add test/router/app_router_test.dart test/features/photo_detail/presentation/pages/photo_detail_page_test.dart test/features/photo_detail/presentation/pages/photo_detail_progressive_test.dart test/features/collections/presentation/pages/collection_detail_page_test.dart test/features/collections/presentation/pages/collections_page_test.dart
git commit -m "test: cover progressive detail hydration flows"
```
