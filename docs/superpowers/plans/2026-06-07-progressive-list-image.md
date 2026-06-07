# Progressive List Image Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a shared progressive list-image widget that renders `thumb -> regular` with a short saturation reveal, then wire it into shared photo card and grid surfaces.

**Architecture:** Keep image fetching on the existing `cached_network_image` stack, but move readiness orchestration into a dedicated shared widget. The widget listens to low-res and high-res `ImageProvider` streams, reveals the final image with a short saturation animation, and replaces the current one-step image rendering used by `PhotoCard` and `PhotoGrid`.

**Tech Stack:** Flutter, `cached_network_image`, Flutter widget tests, `flutter_test`

---

## File Structure

- Create: `lib/shared/widgets/progressive_network_photo.dart`
  - Shared widget that listens to `thumb` and `regular` image readiness, renders two temporary layers, and runs the saturation reveal.
- Create: `test/shared/widgets/progressive_network_photo_test.dart`
  - Focused widget tests for the new component using a controllable test `ImageProvider`.
- Modify: `lib/shared/widgets/photo_card.dart`
  - Replace direct `CachedNetworkImage` usage with the new progressive widget while keeping the existing card layout and overlay behavior.
- Modify: `lib/shared/widgets/photo_grid.dart`
  - Replace direct grid-tile image rendering with the new progressive widget.
- Modify: `test/shared/widgets/photo_card_test.dart`
  - Update expectations to prove `PhotoCard` integrates the shared progressive widget without regressing text and interaction behavior.
- Modify: `test/shared/widgets/photo_grid_test.dart`
  - Update expectations to prove `PhotoGrid` integrates the shared progressive widget and keeps like-state rendering intact.

## Task 1: Add failing tests for the progressive image widget

**Files:**
- Create: `test/shared/widgets/progressive_network_photo_test.dart`

- [ ] **Step 1: Write the failing widget tests**

```dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/shared/widgets/progressive_network_photo.dart';

void main() {
  testWidgets('shows thumb first and keeps final image hidden until ready',
      (tester) async {
    final thumbProvider = _ControlledImageProvider();
    final fullProvider = _ControlledImageProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProgressiveNetworkPhoto(
            thumbUrl: 'thumb',
            imageUrl: 'full',
            imageProviderBuilder: (url) =>
                url == 'thumb' ? thumbProvider : fullProvider,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('progressive-thumb-layer')), findsNothing);
    expect(find.byKey(const ValueKey('progressive-full-layer')), findsNothing);

    thumbProvider.complete();
    await tester.pump();

    expect(find.byKey(const ValueKey('progressive-thumb-layer')), findsOneWidget);
    expect(find.byKey(const ValueKey('progressive-full-layer')), findsNothing);
  });

  testWidgets('reveals the final image and removes thumb after animation',
      (tester) async {
    final thumbProvider = _ControlledImageProvider();
    final fullProvider = _ControlledImageProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProgressiveNetworkPhoto(
            thumbUrl: 'thumb',
            imageUrl: 'full',
            revealDuration: const Duration(milliseconds: 100),
            imageProviderBuilder: (url) =>
                url == 'thumb' ? thumbProvider : fullProvider,
          ),
        ),
      ),
    );

    thumbProvider.complete();
    await tester.pump();

    fullProvider.complete();
    await tester.pump();

    expect(find.byKey(const ValueKey('progressive-full-layer')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const ValueKey('progressive-thumb-layer')), findsNothing);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```bash
flutter test test/shared/widgets/progressive_network_photo_test.dart
```

Expected: FAIL with import or constructor errors because `ProgressiveNetworkPhoto` and the test-only provider hook do not exist yet.

- [ ] **Step 3: Add a controllable test provider inside the test file**

```dart
class _ControlledImageProvider extends ImageProvider<_ControlledImageProvider> {
  _ControlledImageProvider();

  late final ImageStreamCompleter _completer = OneFrameImageStreamCompleter(
    _future,
  );

  final Completer<ImageInfo> _imageCompleter = Completer<ImageInfo>();

  Future<ImageInfo> get _future => _imageCompleter.future;

  void complete() {
    if (_imageCompleter.isCompleted) return;
    _imageCompleter.complete(
      Future<ImageInfo>.sync(() async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 2, 2),
          Paint()..color = const Color(0xFFFFFFFF),
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(2, 2);
        return ImageInfo(image: image);
      }),
    );
  }

  @override
  Future<_ControlledImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_ControlledImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    _ControlledImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return _completer;
  }
}
```

- [ ] **Step 4: Re-run the tests after the helper is in place**

Run:

```bash
flutter test test/shared/widgets/progressive_network_photo_test.dart
```

Expected: still FAIL, but now the failure should point only to the missing widget implementation.

- [ ] **Step 5: Commit the test scaffold**

```bash
git add test/shared/widgets/progressive_network_photo_test.dart
git commit -m "test: add progressive network photo coverage"
```

## Task 2: Implement the shared progressive image widget

**Files:**
- Create: `lib/shared/widgets/progressive_network_photo.dart`
- Test: `test/shared/widgets/progressive_network_photo_test.dart`

- [ ] **Step 1: Write the minimal widget shell required by the tests**

```dart
typedef ProgressiveImageProviderBuilder = ImageProvider Function(String url);

class ProgressiveNetworkPhoto extends StatefulWidget {
  const ProgressiveNetworkPhoto({
    super.key,
    required this.thumbUrl,
    required this.imageUrl,
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor,
    this.enableSaturationReveal = true,
    this.revealDuration = const Duration(milliseconds: 220),
    this.imageProviderBuilder,
  });

  final String thumbUrl;
  final String imageUrl;
  final double? aspectRatio;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final bool enableSaturationReveal;
  final Duration revealDuration;
  final ProgressiveImageProviderBuilder? imageProviderBuilder;

  @override
  State<ProgressiveNetworkPhoto> createState() =>
      _ProgressiveNetworkPhotoState();
}
```

- [ ] **Step 2: Implement image-stream readiness tracking**

```dart
class _ProgressiveNetworkPhotoState extends State<ProgressiveNetworkPhoto>
    with SingleTickerProviderStateMixin {
  ImageStream? _thumbStream;
  ImageStream? _fullStream;
  ImageStreamListener? _thumbListener;
  ImageStreamListener? _fullListener;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.revealDuration,
  );
  late final Animation<double> _saturation = Tween<double>(
    begin: 0.12,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  bool _thumbReady = false;
  bool _fullReady = false;
  bool _hideThumbLayer = false;

  @override
  void initState() {
    super.initState();
    _attachStreams();
  }
}
```

- [ ] **Step 3: Render the two-layer stack and reveal**

```dart
@override
Widget build(BuildContext context) {
  Widget child = Stack(
    fit: StackFit.expand,
    children: [
      if (_thumbReady && !_hideThumbLayer)
        _buildLayer(
          key: const ValueKey('progressive-thumb-layer'),
          image: _providerFor(widget.thumbUrl),
          saturation: 0.12,
        ),
      if (_fullReady)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => _buildLayer(
            key: const ValueKey('progressive-full-layer'),
            image: _providerFor(widget.imageUrl),
            saturation:
                widget.enableSaturationReveal ? _saturation.value : 1,
          ),
        ),
    ],
  );

  if (widget.aspectRatio != null) {
    child = AspectRatio(aspectRatio: widget.aspectRatio!, child: child);
  }

  if (widget.borderRadius != null) {
    child = ClipRRect(borderRadius: widget.borderRadius!, child: child);
  }

  return ColoredBox(
    color: widget.backgroundColor ?? Colors.transparent,
    child: child,
  );
}
```

- [ ] **Step 4: Remove listeners correctly and finish the reveal by hiding the thumb**

```dart
Future<void> _startReveal() async {
  await _controller.forward(from: 0);
  if (!mounted) return;
  setState(() => _hideThumbLayer = true);
}

@override
void dispose() {
  _thumbStream?.removeListener(_thumbListener!);
  _fullStream?.removeListener(_fullListener!);
  _controller.dispose();
  super.dispose();
}
```

- [ ] **Step 5: Run the focused widget tests**

Run:

```bash
flutter test test/shared/widgets/progressive_network_photo_test.dart
```

Expected: PASS

- [ ] **Step 6: Commit the widget implementation**

```bash
git add lib/shared/widgets/progressive_network_photo.dart test/shared/widgets/progressive_network_photo_test.dart
git commit -m "feat: add progressive list image widget"
```

## Task 3: Integrate the shared widget into `PhotoCard`

**Files:**
- Modify: `lib/shared/widgets/photo_card.dart`
- Modify: `test/shared/widgets/photo_card_test.dart`

- [ ] **Step 1: Update `PhotoCard` test coverage before editing the widget**

```dart
testWidgets('PhotoCard uses the shared progressive photo widget',
    (tester) async {
  final photo = createTestPhoto();

  await tester.pumpWidget(wrapApp(PhotoCard(photo: photo)));

  expect(find.byType(ProgressiveNetworkPhoto), findsOneWidget);
});
```

- [ ] **Step 2: Run the `PhotoCard` tests to verify the new expectation fails**

Run:

```bash
flutter test test/shared/widgets/photo_card_test.dart
```

Expected: FAIL because `PhotoCard` still renders `CachedNetworkImage` directly.

- [ ] **Step 3: Replace the existing image block with `ProgressiveNetworkPhoto`**

```dart
return AspectRatio(
  aspectRatio: aspectRatio,
  child: ProgressiveNetworkPhoto(
    thumbUrl: photo.urlThumb,
    imageUrl: photo.urlRegular,
    fit: BoxFit.cover,
    backgroundColor: Color(
      int.parse(photo.color.replaceFirst('#', '0xFF')),
    ),
  ),
);
```

- [ ] **Step 4: Re-run `PhotoCard` tests**

Run:

```bash
flutter test test/shared/widgets/photo_card_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit the `PhotoCard` integration**

```bash
git add lib/shared/widgets/photo_card.dart test/shared/widgets/photo_card_test.dart
git commit -m "refactor: use progressive image widget in photo card"
```

## Task 4: Integrate the shared widget into `PhotoGrid`

**Files:**
- Modify: `lib/shared/widgets/photo_grid.dart`
- Modify: `test/shared/widgets/photo_grid_test.dart`

- [ ] **Step 1: Extend `PhotoGrid` tests with a progressive-widget assertion**

```dart
testWidgets('PhotoGrid tiles use the shared progressive photo widget',
    (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: PhotoGrid(
            photos: [_photo(likedByUser: false)],
          ),
        ),
      ),
    ),
  );

  expect(find.byType(ProgressiveNetworkPhoto), findsOneWidget);
});
```

- [ ] **Step 2: Run the `PhotoGrid` tests to verify the new expectation fails**

Run:

```bash
flutter test test/shared/widgets/photo_grid_test.dart
```

Expected: FAIL because `PhotoGridTile` still renders `CachedNetworkImage`.

- [ ] **Step 3: Replace grid-tile image rendering with the shared widget**

```dart
ProgressiveNetworkPhoto(
  thumbUrl: photo.urlThumb,
  imageUrl: photo.urlRegular,
  fit: BoxFit.cover,
  backgroundColor: AppColors.gray100,
)
```

- [ ] **Step 4: Re-run `PhotoGrid` tests**

Run:

```bash
flutter test test/shared/widgets/photo_grid_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit the `PhotoGrid` integration**

```bash
git add lib/shared/widgets/photo_grid.dart test/shared/widgets/photo_grid_test.dart
git commit -m "refactor: use progressive image widget in photo grid"
```

## Task 5: Final verification and cleanup

**Files:**
- Modify: `lib/shared/widgets/progressive_network_photo.dart`
- Modify: `lib/shared/widgets/photo_card.dart`
- Modify: `lib/shared/widgets/photo_grid.dart`
- Test: `test/shared/widgets/progressive_network_photo_test.dart`
- Test: `test/shared/widgets/photo_card_test.dart`
- Test: `test/shared/widgets/photo_grid_test.dart`

- [ ] **Step 1: Run the focused shared-widget test suite**

Run:

```bash
flutter test test/shared/widgets/progressive_network_photo_test.dart
flutter test test/shared/widgets/photo_card_test.dart
flutter test test/shared/widgets/photo_grid_test.dart
```

Expected: all PASS

- [ ] **Step 2: Run a broader regression pass for affected list surfaces**

Run:

```bash
flutter test test/features/discover/presentation/pages/discover_page_test.dart
flutter test test/features/search/presentation/pages/search_page_test.dart
```

Expected: PASS

- [ ] **Step 3: Run static analysis**

Run:

```bash
flutter analyze
```

Expected: no new issues in touched files

- [ ] **Step 4: Manually verify list rendering in the app**

Run:

```bash
flutter run
```

Manual checks:

- discover feed cards show low-res image quickly
- final image quietly takes over
- color reveal is visible but restrained
- grid tiles and list cards feel visually consistent
- scrolling remains smooth without obvious flicker

- [ ] **Step 5: Commit any final polish**

```bash
git add lib/shared/widgets/progressive_network_photo.dart lib/shared/widgets/photo_card.dart lib/shared/widgets/photo_grid.dart test/shared/widgets/progressive_network_photo_test.dart test/shared/widgets/photo_card_test.dart test/shared/widgets/photo_grid_test.dart
git commit -m "feat: add progressive list image loading"
```

## Self-Review

### Spec coverage

- Shared progressive widget: covered in Task 2
- `thumb -> regular` rendering model: covered in Task 2
- Saturation-led reveal: covered in Task 2
- Integration into `PhotoCard`: covered in Task 3
- Integration into `PhotoGrid`: covered in Task 4
- Stable list failure behavior and verification: covered in Tasks 2 and 5

No design requirement from the approved spec is left without a task.

### Placeholder scan

- No `TODO` / `TBD`
- No "implement later"
- Each code-changing step includes concrete code
- Each verification step includes concrete commands and expected outcomes

### Type consistency

- Widget name is consistently `ProgressiveNetworkPhoto`
- Readiness state is consistently `thumbReady` / `fullReady`
- Test-only hook is consistently `imageProviderBuilder`

