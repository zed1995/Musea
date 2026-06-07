# Progressive List Image Design

> **Date**: 2026-06-07
> **Status**: Approved in conversation, pending written spec review

## Goal

Bring a more natural progressive image-loading effect to list and card surfaces in the Flutter app, based on the reference implementation direction the user liked: show a low-resolution network image quickly, let the final image take over quietly, and use restrained color recovery instead of a flashy placeholder animation.

## Product Direction

The target feel is not "obvious loading animation." It is "the photo appears quickly, then settles into its final quality."

The effect should be driven by:

- `thumb` image appearing first
- `regular` image taking over once ready
- low saturation at the beginning of the sequence
- a short reveal back to normal color when the final image is ready

The effect should not be driven primarily by:

- BlurHash as the main placeholder
- heavy Gaussian blur animation
- long crossfades between multiple visual layers
- noticeable skeleton or shimmer treatment for image cells

## Scope

In scope:

- list and card surfaces that render feed images
- a shared Flutter widget for progressive network image display
- photo data-model exposure for `thumb` URLs where missing
- replacement of current one-step image loading in the shared list-card widgets

Out of scope:

- detail-page hero image transitions
- photo viewer / fullscreen transitions
- route semantics
- repository or API redesign beyond surfacing existing `thumb` fields
- BlurHash-first placeholders for list images

## Current State

The Flutter app already has the core building blocks:

- `cached_network_image`
- `flutter_blurhash`
- shared list widgets such as `photo_card.dart` and `photo_grid.dart`

Current list image behavior is mixed:

- `lib/shared/widgets/photo_card.dart` already uses `CachedNetworkImage` with `BlurHash` placeholder for some cards
- `lib/shared/widgets/photo_grid.dart` uses a single `CachedNetworkImage`

This creates two problems:

- the visual language is inconsistent across list surfaces
- the effect is still mostly "placeholder, then final image" rather than "photo gradually settles into place"

## Reference-Derived Direction

The reviewed reference project uses a lighter-weight strategy than a multi-stage blurhash pipeline:

- low-resolution thumbnail request first
- final image request second
- grayscale / low-saturation starting state
- short saturation animation back to normal once the final image is ready

The apparent "blur-to-sharp" feeling mostly comes from the thumbnail itself being low resolution and then being replaced by the final image, not from an explicit heavy blur animation.

This design adopts that direction for Flutter.

## Chosen Approach

Use a shared Flutter widget that renders:

1. a low-resolution `thumb` image as the first visible frame
2. a final `regular` image on top once ready
3. a short, restrained reveal animation focused on saturation recovery

The implementation should default to `thumb -> regular` for list surfaces.

This is preferred over a BlurHash-led pipeline because:

- it more closely matches the reference feel the user prefers
- it avoids drawing attention to the loading mechanic itself
- it is simpler to reuse across multiple list widgets
- it should behave more consistently across Flutter targets than a more effect-heavy layered system

## Widget Design

Introduce a shared widget:

- `lib/shared/widgets/progressive_network_photo.dart`

### Proposed API

```dart
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
  });

  final String thumbUrl;
  final String imageUrl;
  final double? aspectRatio;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final bool enableSaturationReveal;
  final Duration revealDuration;
}
```

### Responsibilities

- manage low-res and high-res image readiness independently
- render a first-frame image quickly without shimmer-like behavior
- keep the reveal subtle and short
- normalize image-loading behavior across shared list surfaces
- hide the low-res layer after the final image fully takes over

## Rendering Model

The widget should use two image layers in a `Stack`:

- bottom layer: `thumb`
- top layer: `regular`

Expected sequence:

1. start listening for both images
2. show `thumb` as soon as it can paint
3. when `regular` becomes paint-ready, show it above the `thumb`
4. run a short saturation reveal on the final image
5. remove the `thumb` layer after the reveal completes

There is no need for a three-stage state machine or a dedicated BlurHash stage in this list-focused implementation.

## State Model

Keep internal state intentionally small:

- `thumbReady`
- `imageReady`
- `hasPlayedReveal`

Animation state can be driven by a single `AnimationController` or a compact implicit-animation setup, but the control flow should remain:

- first frame available
- final frame available
- reveal completed

## Image Readiness Strategy

Do not rely on `placeholder` callbacks alone to orchestrate transitions.

Instead:

- create `CachedNetworkImageProvider(thumbUrl)`
- create `CachedNetworkImageProvider(imageUrl)`
- use `ImageProvider.resolve()` and `ImageStreamListener` to detect when each image can actually paint

Why this approach:

- it works cleanly with cache hits and network responses
- it gives precise control over when the final image is truly displayable
- it avoids coupling transition behavior to one package callback path

## Animation Rules

The reveal should be restrained.

Primary animation:

- saturation from low to normal on the final image

Secondary animation:

- optional very light opacity settling on the final image

Rules:

- keep reveal duration short, around 180-260ms
- avoid heavy blur as a primary visual effect
- do not run an obvious long crossfade
- let the low-res thumb provide most of the "soft first frame" feeling

The intended user impression is:

- quick appearance
- quiet improvement in fidelity
- natural return of color

## Caching And Performance Rules

This feature is for scrolling surfaces, so performance constraints are first-class.

Rules:

- keep only two image layers, and only briefly
- remove the thumb layer after reveal completes
- avoid expensive continuous filters on many visible items
- do not animate large blur radii across the list
- reuse the existing `cached_network_image` caching stack

Behavior by cache state:

- memory-cache hit: reveal may be very short
- disk-cache hit: reveal can stay short but present
- cold network load: full reveal duration is acceptable

The component should feel fast even when animation is present.

## Data Model Changes

The shared widget depends on a `thumbUrl`.

If the current Flutter `Photo` domain entity or data model does not already expose a thumb URL, implementation must surface it through:

- discover photo model parsing
- discover photo entity field exposure
- any affected search-result or related-photo mapping that shares the same photo shape

The goal is not to invent a new API, only to expose an already-available Unsplash URL variant.

## Integration Plan

Integrate in this order:

1. expose `thumb` in Flutter photo models/entities when the current Flutter photo shape does not already surface it
2. add `ProgressiveNetworkPhoto`
3. replace the main image area in `lib/shared/widgets/photo_card.dart`
4. replace the main image area in `lib/shared/widgets/photo_grid.dart`
5. verify the result on list-heavy screens such as discover and search

## Error Handling

- if `thumb` fails, fall back to configured background color or existing neutral fallback treatment
- if `regular` fails after `thumb` succeeded, keep the `thumb` visible instead of blanking the card
- if both fail, show the current broken-image fallback behavior

This keeps list cells visually stable under partial image failures.

## Testing Strategy

Add or update tests for:

- photo model/entity mapping for `thumb`
- widget behavior when `thumb` becomes ready before `regular`
- widget behavior when `regular` is immediately available
- widget behavior when the final image fails but the thumbnail succeeds
- card/grid integration so shared surfaces consistently use the progressive widget

Where image-stream behavior is difficult to fully simulate in widget tests, prioritize focused logic verification and manual device validation for final motion quality.

## Success Criteria

- list surfaces consistently use the same progressive image language
- users see a low-resolution photo quickly instead of a strong placeholder treatment
- final image takeover feels quiet and natural
- color reveal is visible but restrained
- scrolling performance remains stable on list-heavy screens
- the implementation does not depend on BlurHash as the primary list-image effect
