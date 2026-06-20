# Photo Detail Collapsing Toolbar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the always-immersive top bar on the photo detail page with an Android-style collapsing toolbar that fades to an opaque `gray50` bar with a 1px bottom border as the hero image scrolls out of view, without disturbing the existing `Hero` animation or scroll content.

**Architecture:** Keep the hero image as the first `SliverToBoxAdapter` (so the `Hero` tag and image aspect ratio stay untouched). Extract a new `_CollapsingPhotoDetailScrollView` stateful widget that owns a `ScrollController`, recomputes `progress = (offset / heroHeight).clamp(0, 1)`, and renders the `ImmersiveHeroAppBar` in a `Stack` `Positioned` over the `CustomScrollView`. Update `ImmersiveHeroAppBar` to accept `progress` + `scrolled` so it can drive its own background and border opacity; remove its dark gradient and switch its icon color from white to `AppColors.gray900`. Wrap the body in `AnnotatedRegion<SystemUiOverlayStyle>` to flip the status bar once `progress >= 0.5`.

**Tech Stack:** Flutter, Riverpod, GoRouter, existing widget test patterns (no new dependencies).

**Commit policy:** Do **not** commit any changes during execution. The user wants a single batch commit after all tasks are complete.

---

## File Map

### Modify

- `lib/shared/widgets/immersive_hero_app_bar.dart` — add `progress` + `scrolled` + `title` (`String?`), remove dark gradient, drive icon color from `Colors.white` → `AppColors.gray900` based on `scrolled` (a hard step at `progress >= 0.5`), drive background via `Color.lerp`, add a 1px `Divider` whose opacity is `((progress - 0.5) * 2).clamp(0, 1)`, add a centered `Text` in an `Expanded` slot between the back button and the actions with `maxLines: 1` + `overflow: ellipsis` + opacity = `((progress - 0.5) * 2).clamp(0, 1)`, drop the 28dp bottom padding so the collapsed height matches `AndroidTopBar`'s 56dp.
- `lib/features/photo_detail/presentation/pages/photo_detail_page.dart` — convert `_PhotoDetailContent` to a stateful `_CollapsingPhotoDetailScrollView` with a `ScrollController` + progress computation, wrap the body in `Stack` with the `ImmersiveHeroAppBar` in a `Positioned`, add an `AnnotatedRegion<SystemUiOverlayStyle>`, drop the inner `Stack`/`ImmersiveHeroAppBar` from `_PhotoHero`, and pipe the locked hero height from `_PhotoHero` to the scroll view via an `onHeightLocked` callback. Also remove `Colors.white` from the action icons at the bar call site.
- `test/shared/widgets/android_top_bar_test.dart` — update the existing `ImmersiveHeroAppBar` test to pass the new `progress`/`scrolled` parameters and assert the new icon color.
- `test/features/photo_detail/presentation/pages/photo_detail_page_test.dart` — add scroll-driven progress tests; update the icon-color assertion to `AppColors.gray900`.
- `test/features/photo_detail/presentation/pages/photo_detail_progressive_test.dart` — add an override (or `MediaQuery` data) so the scroll view has a non-zero `heroHeight` when computing progress; the existing assertions still pass once the new tree is in place.

---

### Task 1: Refactor `ImmersiveHeroAppBar` to accept scroll progress

**Files:**
- Modify: `lib/shared/widgets/immersive_hero_app_bar.dart`
- Modify: `test/shared/widgets/android_top_bar_test.dart`

- [ ] **Step 1: Write the failing test for the new signature**

Open `test/shared/widgets/android_top_bar_test.dart` and replace the existing `ImmersiveHeroAppBar` test (the third `testWidgets` in the file) with:

```dart
void _noop() {}

testWidgets('ImmersiveHeroAppBar renders back and action buttons in gray900',
    (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Container(color: Colors.black),
            ImmersiveHeroAppBar(
              onBack: _noop,
              actions: [
                IconButton(
                  onPressed: _noop,
                  icon: const Icon(Icons.bookmark_border_rounded),
                ),
                IconButton(
                  onPressed: _noop,
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

  final backIcon = tester.widget<Icon>(find.byIcon(Icons.arrow_back_rounded));
  expect(backIcon.color, AppColors.gray900);
});
```

Also add at the top of the file (under the existing imports):

```dart
import 'package:musea/core/theme/colors.dart';
```

(`_noop` is a top-level function reference, which is required because non-const `IconButton` instances cannot be passed to a `const` `ImmersiveHeroAppBar`. The test was previously written with non-const lambdas; this update switches to a stable top-level function so the assertions are deterministic.)

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/shared/widgets/android_top_bar_test.dart`
Expected: FAIL with a compile error — `ImmersiveHeroAppBar` does not accept `const` with no `progress`/`scrolled`, and (once compiled) the icon color is still `Colors.white`.

- [ ] **Step 3: Rewrite `ImmersiveHeroAppBar` with the new API**

Replace the entire contents of `lib/shared/widgets/immersive_hero_app_bar.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:musea/core/theme/colors.dart';

class ImmersiveHeroAppBar extends StatelessWidget {
  const ImmersiveHeroAppBar({
    super.key,
    this.onBack,
    this.actions = const [],
    this.topPadding,
    this.progress = 0.0,
    this.scrolled = false,
  });

  final VoidCallback? onBack;
  final List<Widget> actions;
  final double? topPadding;
  final double progress;
  final bool scrolled;

  @override
  Widget build(BuildContext context) {
    final resolvedTopPadding = topPadding ?? MediaQuery.paddingOf(context).top;
    final background =
        Color.lerp(Colors.transparent, AppColors.gray50, progress)!;
    final borderOpacity = ((progress - 0.5) * 2.0).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.only(
        top: resolvedTopPadding + 8,
        left: 4,
        right: 4,
        bottom: 0,
      ),
      decoration: BoxDecoration(color: background),
      child: IconTheme(
        data: const IconThemeData(color: AppColors.gray900),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  const Spacer(),
                  for (final action in actions)
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(child: action),
                    ),
                ],
              ),
            ),
            IgnorePointer(
              child: Opacity(
                opacity: borderOpacity,
                child: const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.gray200,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/shared/widgets/android_top_bar_test.dart`
Expected: PASS with 3 tests, the new one asserting `AppColors.gray900`.

- [ ] **Step 5: Do not commit yet** (deferred to the end of the plan).

---

### Task 2: Add a scroll-driven progress test for the photo detail page

**Files:**
- Modify: `test/features/photo_detail/presentation/pages/photo_detail_page_test.dart`

- [ ] **Step 1: Append the failing scroll-progress test**

Append the following to `test/features/photo_detail/presentation/pages/photo_detail_page_test.dart` (inside `void main()`, after the closing brace of the last `testWidgets` block but before the file-closing brace):

```dart
testWidgets('PhotoDetailPage bar background lerps as the hero scrolls out',
    (tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final photo = buildPhoto(
    id: 'photo-collapse',
    username: 'paula',
    name: 'Paula Poeira',
    color: '#5B7B9A',
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        photoDetailProvider('photo-collapse')
            .overrideWith((ref) => photo),
        userPhotosProvider('paula').overrideWith((ref) => <Photo>[]),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PhotoDetailPage(photoId: 'photo-collapse'),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  ImmersiveHeroAppBar bar() => tester.widget<ImmersiveHeroAppBar>(
        find.byType(ImmersiveHeroAppBar),
      );

  expect(bar().progress, 0.0);
  expect(bar().scrolled, isFalse);

  // Drag upward by half the placeholder hero height (320 / 2) so progress hits 0.5.
  await tester.drag(
    find.byType(PhotoDetailPage),
    const Offset(0, -160),
  );
  await tester.pump();

  expect(bar().progress, closeTo(0.5, 0.05));
  expect(bar().scrolled, isTrue);

  // Drag the rest of the way so progress hits 1.0.
  await tester.drag(
    find.byType(PhotoDetailPage),
    const Offset(0, -160),
  );
  await tester.pump();

  expect(bar().progress, 1.0);
  expect(bar().scrolled, isTrue);
});
```

Add the import at the top of the test file:

```dart
import 'package:musea/shared/widgets/immersive_hero_app_bar.dart';
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/photo_detail/presentation/pages/photo_detail_page_test.dart --plain-name "PhotoDetailPage bar background lerps as the hero scrolls out"`
Expected: FAIL because `_PhotoDetailContent` is not yet a stateful widget and does not provide a `ScrollController`, so the `ImmersiveHeroAppBar` cannot be driven by scroll position.

- [ ] **Step 3: Do not commit yet**.

---

### Task 3: Extract `_CollapsingPhotoDetailScrollView` and wire up scroll progress

**Files:**
- Modify: `lib/features/photo_detail/presentation/pages/photo_detail_page.dart`

This is the largest task. It moves the bar from inside `_PhotoHero` to a `Positioned` on top of the `CustomScrollView`, introduces a `ScrollController` and progress computation, and adds `AnnotatedRegion<SystemUiOverlayStyle>`.

- [ ] **Step 1: Add the imports**

At the top of `lib/features/photo_detail/presentation/pages/photo_detail_page.dart`, ensure these imports exist (add any that are missing):

```dart
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:musea/core/theme/colors.dart' show AppColors;
```

(`flutter/services.dart` is the standard source for `SystemUiOverlayStyle`. `musea/core/theme/colors.dart` already exists and provides `AppColors.gray50` / `gray200` / `gray900`.)

- [ ] **Step 2: Update the action icons in the existing `ImmersiveHeroAppBar` call site**

In the `_PhotoHero` widget's `build` method (the `Stack` inside `_PhotoHeroState`), remove the `Stack` and the `ImmersiveHeroAppBar`. The widget should return **only** the image (wrapped in the `Hero` + `CachedNetworkImage`). Concretely, replace the entire `build` of `_PhotoHeroState` with:

```dart
@override
Widget build(BuildContext context) {
  return _HeroFrame(
    key: _frameKey,
    onHeightLocked: _onHeightLocked,
    child: Hero(
      tag: widget.photo.id,
      child: GestureDetector(
        key: const ValueKey('photo-detail-hero-tap-target'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: CachedNetworkImage(
          imageUrl: widget.photo.urlRegular,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 320,
            color: Color(
              int.parse(widget.photo.color.replaceFirst('#', '0xFF')),
            ),
            child: const Center(child: LoadingIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            height: 320,
            color: AppColors.gray200,
            child: const Icon(Icons.broken_image, size: 48),
          ),
        ),
      ),
    ),
  );
}

void _onHeightLocked(double height) {
  if (_lockedHeight == null && height > 0) {
    setState(() {
      _lockedHeight = height;
    });
    widget.onHeightLocked?.call(height);
  }
}
```

Update the `_PhotoHero` widget declaration to accept the new callback and remove the now-unused `onBookmarkTap` / `onShareTap`:

```dart
class _PhotoHero extends StatefulWidget {
  const _PhotoHero({
    required this.photo,
    this.onTap,
    this.onHeightLocked,
  });

  final Photo photo;
  final VoidCallback? onTap;
  final ValueChanged<double>? onHeightLocked;

  @override
  State<_PhotoHero> createState() => _PhotoHeroState();
}
```

- [ ] **Step 3: Add the `_HeroFrame` widget (private to the file)**

Add the following widget at the bottom of the file (just before the final `}`):

```dart
class _HeroFrame extends StatefulWidget {
  const _HeroFrame({
    super.key,
    required this.child,
    required this.onHeightLocked,
  });

  final Widget child;
  final ValueChanged<double> onHeightLocked;

  @override
  State<_HeroFrame> createState() => _HeroFrameState();
}

class _HeroFrameState extends State<_HeroFrame> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_reportHeight);
  }

  @override
  void didUpdateWidget(covariant _HeroFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback(_reportHeight);
  }

  void _reportHeight(Duration _) {
    if (!mounted) return;
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    final height = box?.size.height;
    if (height != null && height > 0) {
      widget.onHeightLocked(height);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: _key,
      width: double.infinity,
      child: widget.child,
    );
  }
}
```

(We extract the size-locking logic from `_PhotoHero` so the bar's `Positioned` does not have to know about image layout. `_PhotoHero` keeps its `_lockedHeight` state for the existing SizedBox wrap-if-locked behaviour — but with the new design, the bar sits on top of the `Stack` and the `Hero` image no longer needs to be height-locked for the bar. We can therefore drop the `SizedBox(height: _lockedHeight, …)` wrap and the `_lockedHeight` state from `_PhotoHero`.)

Drop the `_lockedHeight` state, the `_scheduleHeightLock` method, and the conditional `SizedBox` in `_PhotoHeroState.build` — the new `_HeroFrame` handles all sizing.

- [ ] **Step 4: Convert `_PhotoDetailContent` into `_CollapsingPhotoDetailScrollView`**

Replace the existing `_PhotoDetailContent` class with the stateful version below. The content (slivers, business logic) stays identical; only the wrapper changes.

```dart
class _CollapsingPhotoDetailScrollView extends ConsumerStatefulWidget {
  const _CollapsingPhotoDetailScrollView({
    required this.photo,
    required this.heroPhoto,
    this.onHeroTap,
    this.isHydratingDeferredContent = false,
    this.showDeferredRetry = false,
    this.onRetryDeferred,
  });

  final Photo photo;
  final Photo heroPhoto;
  final VoidCallback? onHeroTap;
  final bool isHydratingDeferredContent;
  final bool showDeferredRetry;
  final VoidCallback? onRetryDeferred;

  @override
  ConsumerState<_CollapsingPhotoDetailScrollView> createState() =>
      _CollapsingPhotoDetailScrollViewState();
}

class _CollapsingPhotoDetailScrollViewState
    extends ConsumerState<_CollapsingPhotoDetailScrollView> {
  final ScrollController _controller = ScrollController();
  double? _heroHeight;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScroll);
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!mounted) return;
    setState(() {});
  }

  double get _progress {
    final heroHeight = _heroHeight ?? MediaQuery.sizeOf(context).height * 0.55;
    if (heroHeight <= 0) return 0.0;
    return (_controller.offset / heroHeight).clamp(0.0, 1.0);
  }

  bool get _scrolled => _progress >= 0.5;

  void _onHeroHeightLocked(double height) {
    if (_heroHeight == null && height > 0) {
      setState(() {
        _heroHeight = height;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final likeState = ref.watch(photoLikeStateProvider(widget.photo));
    final showTagSkeleton =
        widget.isHydratingDeferredContent && widget.photo.tags.isEmpty;
    final showExifSkeleton =
        widget.isHydratingDeferredContent && widget.photo.exif == null;
    final showDeferredError = widget.showDeferredRetry &&
        (widget.photo.tags.isEmpty || widget.photo.exif == null);
    final l10n = AppLocalizations.of(context)!;
    final progress = _progress;
    final scrolled = _scrolled;

    void handleBookmark() {
      final authState = ref.read(authControllerProvider);
      if (!authState.isAuthenticated) {
        showAuthGateSheet(
          context,
          ref,
          title: l10n.signInToSavePhotos,
          body: l10n.signInToSavePhotosBody,
        );
      }
      showSaveToCollectionSheet(context, photoId: widget.photo.id);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: scrolled
          ? const SystemUiOverlayStyle(
              statusBarColor: AppColors.gray50,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              controller: _controller,
              slivers: [
                SliverToBoxAdapter(
                  child: _PhotoHero(
                    photo: widget.heroPhoto,
                    onTap: widget.onHeroTap,
                    onHeightLocked: _onHeroHeightLocked,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _UserRow(photo: widget.photo),
                        const SizedBox(height: 16),
                        _StatsStrip(
                          photo: widget.photo,
                          likeState: likeState,
                          onLikeTap: () async {
                            final authState = ref.read(authControllerProvider);
                            if (!authState.isAuthenticated) {
                              await showAuthGateSheet(context, ref);
                              return;
                            }

                            final success = await ref
                                .read(photoLikeControllerProvider.notifier)
                                .toggle(photo: widget.photo);
                            if (!context.mounted || success) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.likeError)),
                            );
                          },
                        ),
                        if (_description case final description?) ...[
                          const SizedBox(height: 16),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.55,
                              color: Color(0xFF52525B),
                            ),
                          ),
                        ],
                        if (showDeferredError) ...[
                          const SizedBox(height: 16),
                          _DeferredRetryBanner(onRetry: widget.onRetryDeferred),
                        ],
                        if (widget.photo.tags.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.photo.tags
                                .map((tag) => _TagChip(
                                      label: tag.title,
                                      onTap: () => context.push(
                                        '/search?q=${Uri.encodeComponent(tag.title)}',
                                      ),
                                    ))
                                .toList(),
                          ),
                        ] else if (showTagSkeleton) ...[
                          const SizedBox(height: 16),
                          _DeferredSectionSkeleton(
                            key: const ValueKey('photo-detail-tags-skeleton'),
                            title: l10n.tags,
                            lines: 2,
                          ),
                        ] else if (showDeferredError) ...[
                          const SizedBox(height: 16),
                          _DeferredSectionPlaceholder(
                            title: l10n.tags,
                            message: l10n.tagsUnavailable,
                          ),
                        ],
                        if (_exifItems(l10n).isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const _SectionDivider(),
                          const SizedBox(height: 6),
                          Text(
                            l10n.cameraInfo,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF71717A),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 0),
                          _ExifGrid(items: _exifItems(l10n)),
                        ] else if (showExifSkeleton) ...[
                          const SizedBox(height: 18),
                          _DeferredSectionSkeleton(
                            key: const ValueKey('photo-detail-exif-skeleton'),
                            title: l10n.cameraInfo,
                            lines: 3,
                          ),
                        ] else if (showDeferredError) ...[
                          const SizedBox(height: 18),
                          _DeferredSectionPlaceholder(
                            title: l10n.cameraInfo,
                            message: l10n.cameraDetailsUnavailable,
                          ),
                        ],
                        if (widget.photo.color.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const _SectionDivider(),
                          const SizedBox(height: 18),
                          ColorPaletteSection(hexColor: widget.photo.color),
                        ],
                        const SizedBox(height: 18),
                        _DownloadButton(
                          onTap: () async {
                            await DownloadSheet.show(context, widget.photo);
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _MoreFromPhotographer(photo: widget.photo),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ImmersiveHeroAppBar(
                progress: progress,
                scrolled: scrolled,
                onBack: () => Navigator.maybePop(context),
                actions: [
                  IconButton(
                    onPressed: handleBookmark,
                    icon: const Icon(Icons.bookmark_border_rounded),
                  ),
                  IconButton(
                    onPressed: () => showShareActionSheet(
                      context,
                      ref,
                      shareUrl: AppShareService.resolvePhotoUrl(widget.photo),
                    ),
                    icon: const Icon(Icons.ios_share_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? get _description => widget.photo.description ?? widget.photo.altDescription;

  List<_ExifItem> _exifItems(AppLocalizations l10n) {
    final exif = widget.photo.exif;
    if (exif == null) return const [];

    final items = <_ExifItem>[];
    final camera = _join(exif.make, exif.model);
    if (camera != null) {
      items.add(_ExifItem(l10n.exifCamera, camera));
    }
    if (exif.aperture != null) {
      items.add(_ExifItem(l10n.exifAperture, exif.aperture!));
    }
    if (exif.exposureTime != null) {
      items.add(_ExifItem(l10n.exifShutter, exif.exposureTime!));
    }
    if (exif.iso != null) {
      items.add(_ExifItem(l10n.exifIso, exif.iso.toString()));
    }
    if (exif.focalLength != null) {
      items.add(_ExifItem(l10n.exifFocal, exif.focalLength!));
    }
    if (widget.photo.location != null &&
        (widget.photo.location!.city?.isNotEmpty == true ||
            widget.photo.location!.country?.isNotEmpty == true)) {
      items.add(_ExifItem(l10n.exifLocation, widget.photo.location!.displayName));
    }
    if (widget.photo.width > 0 && widget.photo.height > 0) {
      items.add(_ExifItem(
        l10n.exifSize,
        '${widget.photo.width}\u00d7${widget.photo.height}',
      ));
    }
    return items;
  }

  String? _join(String? a, String? b) {
    if (a == null && b == null) return null;
    return [a, b].where((x) => x != null && x.isNotEmpty).join(' ');
  }
}
```

- [ ] **Step 5: Update the `PhotoDetailPage` build to use the new widget**

In `PhotoDetailPage.build`, replace both `_PhotoDetailContent(...)` call sites with `_CollapsingPhotoDetailScrollView(...)`. The argument lists are identical; the rename is the only change. Concretely, search for `_PhotoDetailContent(` (two occurrences) and replace each with `_CollapsingPhotoDetailScrollView(`.

- [ ] **Step 6: Run the scroll progress test to verify it passes**

Run: `flutter test test/features/photo_detail/presentation/pages/photo_detail_page_test.dart --plain-name "PhotoDetailPage bar background lerps as the hero scrolls out"`
Expected: PASS. The widget tree now hosts a `ScrollController`; the `ImmersiveHeroAppBar` rebuilds on each scroll tick with a `progress` value; after a 320px drag (the placeholder hero height), `progress` reaches `1.0` and `scrolled` is `true`.

- [ ] **Step 7: Do not commit yet**.

---

### Task 4: Update icon color assertion and clean up the rest of the test suite

**Files:**
- Modify: `test/features/photo_detail/presentation/pages/photo_detail_page_test.dart`
- Modify: `test/features/photo_detail/presentation/pages/photo_detail_progressive_test.dart`

- [ ] **Step 1: Run the full photo-detail test files to surface any other breakage**

Run:
```bash
flutter test \
  test/features/photo_detail/presentation/pages/photo_detail_page_test.dart \
  test/features/photo_detail/presentation/pages/photo_detail_progressive_test.dart
```

Expected: failures concentrated on the old white-icon assertion and the `Stack`-vs-`Positioned` lookup in any test that used `find.descendant(of: find.byType(Stack), ...)`. List each failure.

- [ ] **Step 2: Update icon-color assertions to `AppColors.gray900`**

In `test/features/photo_detail/presentation/pages/photo_detail_page_test.dart`, locate the existing assertion that uses the `Icon` color. There is no explicit `Colors.white` assertion today (the original design assumed the gradient hid the icons), but the new design guarantees dark icons. Add the following assertion to the first test (`PhotoDetailPage tolerates null numeric fields from detail payload`), immediately after `expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);`:

```dart
expect(
  tester.widget<Icon>(find.byIcon(Icons.arrow_back_rounded)).color,
  AppColors.gray900,
);
```

Add the import at the top of the file (if not already present):

```dart
import 'package:musea/core/theme/colors.dart' show AppColors;
```

Apply the same `AppColors.gray900` assertion to the other photo-detail test files if any test queries icon colors. (For the `photo_detail_progressive_test.dart` file, the only relevant test is `photo detail back button is safe when route cannot pop`; that test only checks that the back button does not throw — it does not query the icon color, so no edit is needed there.)

- [ ] **Step 3: Re-run the photo-detail tests**

Run:
```bash
flutter test \
  test/features/photo_detail/presentation/pages/photo_detail_page_test.dart \
  test/features/photo_detail/presentation/pages/photo_detail_progressive_test.dart
```

Expected: PASS (all tests in both files). If any test fails, fix the assertion to match the new structure (e.g., if a test used `find.descendant(of: find.byType(Stack), matching: find.byType(ImmersiveHeroAppBar))`, change it to `find.byType(ImmersiveHeroAppBar)` since the bar is no longer inside a `Stack`).

- [ ] **Step 4: Do not commit yet**.

---

### Task 5: Verify the full project still passes

**Files:**
- Modify: any test that breaks as a side effect (not anticipated, but possible)

- [ ] **Step 1: Run the full test suite**

Run: `flutter test`
Expected: PASS. If any test outside the photo detail area fails because of an icon-color change or a renamed class, update the assertion (e.g., a test that checks for `Colors.white` on a photo detail action icon now expects `AppColors.gray900`).

- [ ] **Step 2: Run the analyzer**

Run: `flutter analyze`
Expected: PASS with no new issues. The two new public-API changes (`progress`, `scrolled` on `ImmersiveHeroAppBar`) are optional with defaults, so no other call site needs to change.

- [ ] **Step 3: Do not commit yet**.

---

### Task 6: Hand off for a single batched commit

**Files:** none

- [ ] **Step 1: Verify the worktree is clean apart from intended changes**

Run: `git status`
Expected: 5 modified files (`immersive_hero_app_bar.dart`, `photo_detail_page.dart`, `android_top_bar_test.dart`, `photo_detail_page_test.dart`, `photo_detail_progressive_test.dart`) plus 1 new spec/plan pair (untracked at the repo root's `docs/superpowers/`). The new spec at `docs/superpowers/specs/2026-06-20-photo-detail-collapsing-toolbar-design.md` and the plan at `docs/superpowers/plans/2026-06-20-photo-detail-collapsing-toolbar.md` are the design artifacts.

- [ ] **Step 2: Hand off to the user for the batched commit**

Report the file list and the new spec/plan paths; the user will compose a single `git commit` (or a small sequence) covering everything.
