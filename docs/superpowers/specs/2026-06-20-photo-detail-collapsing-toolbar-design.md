# Photo Detail Collapsing Toolbar

## Goal

Replace the static always-immersive top bar on the photo detail page with an Android-style collapsing toolbar. While the hero image is fully visible the top bar is transparent with white icons; as the user scrolls, the bar's background opacity grows linearly toward `gray50`, the icons switch to dark once the background is sufficiently opaque, the photo's description fades in centered, and a 1px bottom border appears once the image is fully scrolled away, at which point the bar is an opaque `gray50` strip with dark icons and the description ellipsis-truncated.

## Non-Goals

- No parallax, zoom, or other motion effects on the hero image itself.
- No changes to the underlying scroll content, business logic, or `Hero` animation between the grid and the detail page.
- No iOS/Android platform-specific widget branching beyond the existing `SystemUiOverlayStyle` handling.

## Visual Specification

| State (`progress`) | Bar background | Icons | Title | Status bar | Bottom border |
|---|---|---|---|---|---|
| `0.0` (initial) | transparent | `Colors.white` | hidden (alpha 0) | transparent | hidden |
| `0.0 → 0.5` | transparent → gray50 (linear lerp) | `Colors.white` | fading in (alpha 0 → 1) | transparent | hidden |
| `0.5` (border threshold) | ~50% gray50 | `AppColors.gray900` | fully visible | gray50 (matches bar) | opacity 0 |
| `0.5 → 1.0` | transparent → gray50 (continues) | `AppColors.gray900` | fully visible | gray50 (matches bar) | fades from 0 → 1 alpha |
| `1.0` (fully collapsed) | `AppColors.gray50` | `AppColors.gray900` | fully visible, ellipsis-truncated | `AppColors.gray50` | 1px `AppColors.gray200` |

Icons are **white** while the bar background is still largely transparent (so they remain readable against the dark hero image) and switch to **`AppColors.gray900`** at the same `progress >= 0.5` threshold that the bottom border and the opaque status bar appear at. The switch is a hard step (not a lerp) so the icons read cleanly against the gray50 background the moment the bar starts feeling solid.

The title (the photo's `description ?? altDescription`) is centered in the row between the back button and the trailing actions. It is **always mounted** (so the layout is stable) but its opacity follows the same `((progress - 0.5) * 2).clamp(0, 1)` curve as the bottom border. The text is constrained to a single line and is `TextOverflow.ellipsis`-truncated. The available width is whatever the `Expanded` slot between the 48dp back button and the trailing actions leaves (typically the screen width minus ~144dp). If `title` is `null` or empty, the slot is still rendered (with alpha 0) so the bar's layout does not shift when scrolling.

`progress` is a linear value:

```
progress = (scrollOffset / heroHeight).clamp(0.0, 1.0)
```

The hero height is the locked height used by `_PhotoHero` (a `double`). When it is unavailable (e.g., before first layout) the page falls back to `MediaQuery.sizeOf(context).height * 0.55` so the math still works.

### Bar height

When the bar is fully collapsed, its height is `topPadding + 56dp` (top padding from system insets, then 8dp top padding, then 48dp IconButton, then 1px Divider). This matches `AndroidTopBar`'s 56dp content height. There is **no extra bottom padding** — the 28dp bottom padding from the original gradient-based design has been removed.

## Architecture

### Components

1. **`ImmersiveHeroAppBar`** (`lib/shared/widgets/immersive_hero_app_bar.dart`) — gains a `progress` (0.0–1.0), a derived `scrolled` (`bool`), and a `title` (`String?`) parameter. It no longer paints a top dark gradient and now switches its back-button and action icon color from `Colors.white` to `AppColors.gray900` once `scrolled` is true. It computes its background with `Color.lerp(Colors.transparent, AppColors.gray50, progress)` and renders an `AnimatedOpacity` 1px `Divider` whose opacity is `((progress - 0.5) * 2).clamp(0.0, 1.0)`. The title sits in an `Expanded` slot between the back button and the actions: it is single-line, `TextOverflow.ellipsis`-truncated, centered, `AppColors.gray900`, and its opacity follows the same `((progress - 0.5) * 2).clamp(0.0, 1.0)` curve as the divider. The action set stays the same (`back`, `bookmark`, `share`). The bar's bottom padding is `0` so the total collapsed height matches `AndroidTopBar`'s 56dp.

2. **`_CollapsingPhotoDetailScrollView`** (new stateful widget inside `photo_detail_page.dart`) — owns a `ScrollController`, computes `progress` and `scrolled`, and renders a `Stack` whose bottom layer is the existing `CustomScrollView` (with `_PhotoHero` as the first sliver) and whose top layer is a `Positioned` `ImmersiveHeroAppBar` pinned to the top. It also wraps the body in an `AnnotatedRegion<SystemUiOverlayStyle>` that switches overlay style when `scrolled` flips.

3. **`_PhotoHero`** — simplified to render only the `Hero` + `CachedNetworkImage`. The `Stack` and `ImmersiveHeroAppBar` previously nested inside it are removed because the bar now lives at the page level.

### Data Flow

```
ScrollController (from CustomScrollView)
  └── AnimatedBuilder
        ├── progress  → ImmersiveHeroAppBar (drives bg + border)
        ├── scrolled  → ImmersiveHeroAppBar (controls divider opacity)
        └── scrolled  → AnnotatedRegion<SystemUiOverlayStyle>
```

### Scroll Math

- `heroHeight` is captured once via `WidgetsBinding.instance.addPostFrameCallback` after first build, similar to the existing `_lockedHeight` logic in `_PhotoHero`. If still null when scroll happens, use the media-query fallback.
- `progress` is recomputed on every scroll tick inside `AnimatedBuilder`.
- The bar rebuilds every frame during scroll, but its render output is cheap (`Container` color + opacity) so this is acceptable.

### Status Bar

`AnnotatedRegion<SystemUiOverlayStyle>` switches between two styles:

- `progress < 0.5`: `SystemUiOverlayStyle.dark` (dark icons on a transparent system bar) — matches the current behavior.
- `progress >= 0.5`: `SystemUiOverlayStyle.dark` with `statusBarColor: AppColors.gray50` — dark icons on the same `gray50` as the bar.

On Android, `statusBarColor` paints the system bar background. On iOS, the bar uses the overlay style to drive icon contrast; we keep icons dark throughout per the agreed design.

## Files

### Modify

- `lib/shared/widgets/immersive_hero_app_bar.dart` — add `progress` + `scrolled`, remove dark gradient, switch icons to dark.
- `lib/features/photo_detail/presentation/pages/photo_detail_page.dart` — extract `_CollapsingPhotoDetailScrollView` stateful widget, simplify `_PhotoHero`, remove the inner `Stack`/`ImmersiveHeroAppBar`.
- `test/features/photo_detail/presentation/pages/photo_detail_page_test.dart` — update assertions for the new icon colors and add a scroll-driven progress test.
- `test/features/photo_detail/presentation/pages/photo_detail_progressive_test.dart` (if assertions reference the old `ImmersiveHeroAppBar` placement) — update to match the new structure.

### No-Op

- The hero `Stack` in `_PhotoHero` becomes a single widget; the `Hero` tag and `CachedNetworkImage` are unchanged.
- All providers, route extras, share/save/download flows remain untouched.

## Error Handling

- If the hero never lays out (`heroHeight == null`), the page uses the media-query fallback so `progress` is still in `[0, 1]`.
- If scroll is overscrolled (bounce), `progress` is clamped to `1.0` so the bar never gets a darker shade than `gray50`.
- The `ScrollController` is disposed in `State.dispose`.

## Testing

Widget tests for `photo_detail_page.dart` should cover:

1. Initial state: `progress == 0.0`, no bottom border rendered, `ImmersiveHeroAppBar` background is transparent.
2. Mid-scroll state: scroll to `heroHeight * 0.5`; bottom border opacity is 0, background is roughly halfway between transparent and `gray50`.
3. Fully collapsed state: scroll past `heroHeight`; background is `gray50`, bottom border opacity is 1, status bar overlay uses `gray50`.
4. Existing behavior tests (back button pop, share action, like toggle) still pass.

Existing tests that look for the old white icons or the dark gradient should be updated to assert dark icons and no gradient.

## Open Questions

None at design time.
