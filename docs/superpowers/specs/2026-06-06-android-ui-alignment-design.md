# Android UI Alignment Design

> **Date**: 2026-06-06
> **Status**: Draft for review

## Goal

Align the Flutter app UI with the latest Android-oriented prototype refinements captured by commit `928e397`, without changing business logic, data flow, or route semantics.

This work should make the app feel closer to Android native language in three visible ways:

- simpler, more direct top app bars
- more Material-like immersive image headers
- flatter, cleaner collection sheet headers and action areas

## Source of Truth

The primary visual reference for this work is the `prototype` HTML updated in commit `928e397 Refine Android-style prototype app bars`.

That commit establishes these direction changes:

- remove extra hierarchy labels like `Library` and `Workspace`
- standardize secondary-page top bars around a true Android back affordance
- replace chevron-like back icons with `arrow_back` structure
- replace glassy floating hero buttons with transparent 48dp hit areas over a stronger top scrim
- reduce decorative chip density in immersive pages
- tighten top-right action sets:
  - photo detail keeps `Save` and `Share`
  - collection detail keeps `Share`
- flatten bottom sheet headers and unify close/back treatment

## Scope

In scope:

- update app bars and hero headers on existing Flutter pages that correspond to the revised prototype pages
- introduce shared presentation primitives for Android-style top bars and immersive hero action rows
- update collection-related bottom sheet headers to match the flatter Android Material direction
- adjust existing widget and router tests where titles, icons, or page structure change

Out of scope:

- any data-model, provider, repository, or API changes
- new user flows or new product capabilities
- changes to actual save, share, search, download, or auth behavior
- broad theme-system rewrites unrelated to the touched pages
- rebuilding the app to exactly mirror every prototype-only layout where no real app screen exists yet

## Product Direction

This is a UI language alignment pass, not a feature pass.

The app should keep all current functional behavior, but the surfaces that already exist in Flutter should visually converge on the prototype’s Android-native direction. The result should feel more consistent across entry pages, detail pages, and modal sheets instead of mixing iOS-like glass controls with Android-style content structure.

## Existing Constraints

- the real app already contains the main target surfaces:
  - settings
  - language settings
  - downloads settings
  - search
  - mine
  - profile detail
  - photo detail
  - collection detail
  - collection create/edit/manage/delete/save sheets
- these screens are already wired to real providers and routes
- current divergence is mostly presentational:
  - some pages use generic `AppBar`
  - some pages use chevron-like back icons
  - immersive detail pages still use more decorative floating controls and looser action sets
  - sheet headers vary by page and do not yet read as one cohesive Android family

## Design Approach

Use shared presentation primitives first, then recompose the affected pages around them.

Why this approach:

- the prototype changes are fundamentally about unifying language
- page-by-page patching would likely create multiple near-duplicate Android patterns
- extracting a small set of UI primitives makes the visual rules explicit and easier to maintain
- this keeps implementation local to presentation while avoiding logic churn

## Shared UI Primitives

### `AndroidTopBar`

Create a reusable top-bar widget for standard pages.

Responsibilities:

- render a direct page title with no extra hierarchy label
- optionally render a back affordance using an Android-style arrow
- provide balanced left and right action slots so titles stay visually stable
- use light Android-oriented surface treatment:
  - neutral light background
  - minimal or no elevation
  - optional bottom divider
  - transparent icon-button backgrounds
- preserve comfortable touch targets in the 40-48dp range

This primitive should cover:

- `Settings`
- `Language`
- `Downloads`
- `Search`
- `Profile detail`
- any other secondary page in this pass that should not have an immersive image header

### `ImmersiveHeroAppBar`

Create a reusable overlay app-bar layer for immersive image pages.

Responsibilities:

- apply a stronger top scrim for white-icon legibility
- render transparent 48dp action hit areas instead of glassy pills
- standardize back navigation affordance
- standardize spacing between top-right actions
- support optional hero title and subtitle content with restrained hierarchy

This primitive should cover:

- `PhotoDetailPage`
- `CollectionDetailPage`
- collection-related sheets that use a hero image area

### `SheetHeaderBar`

Create a flatter shared header treatment for collection-related sheets.

Responsibilities:

- provide a consistent close button style
- support optional back action for flows that return to an earlier sheet state
- reduce ornamental contrast compared with the current rounded floating controls
- preserve current sheet actions and copy while aligning spacing and hierarchy

## Page Mapping

### Standard top-bar pages

Apply `AndroidTopBar` to:

- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/features/settings/presentation/pages/settings_language_page.dart`
- `lib/features/settings/presentation/pages/settings_downloads_page.dart`
- `lib/features/search/presentation/pages/search_page.dart`
- `lib/features/profile/presentation/pages/profile_page.dart`
- `lib/features/profile/presentation/pages/mine_page.dart`

Expected visual changes:

- titles become more direct and less decorative
- back affordances use Android-style arrow treatment
- top spacing and icon-button treatment become consistent
- containers, shadows, and section contrast can be lightly softened where needed to better match the prototype updates

### Immersive detail pages

Apply `ImmersiveHeroAppBar` to:

- `lib/features/photo_detail/presentation/pages/photo_detail_page.dart`
- `lib/features/collections/presentation/pages/collection_detail_page.dart`

Expected visual changes:

- stronger hero top scrim
- transparent 48dp top actions
- reduced top-right action count
- flatter metadata language with less chip ornamentation
- tighter and more Android-like spacing around title and supporting info

### Collection-related sheets

Apply `ImmersiveHeroAppBar` and `SheetHeaderBar` patterns to:

- `lib/features/collections/presentation/widgets/save_to_collection_sheet.dart`
- `lib/features/collections/presentation/widgets/create_collection_sheet.dart`
- `lib/features/collections/presentation/widgets/collection_edit_sheet.dart`
- `lib/features/collections/presentation/widgets/collection_manage_sheet.dart`
- `lib/features/collections/presentation/widgets/collection_delete_sheet.dart`

Expected visual changes:

- hero-image sheets move away from glassy floating controls
- top bars use stronger scrim plus transparent touch targets
- sheet headers become flatter and calmer
- close and back treatments become uniform across the flow

## Per-Surface Design Rules

### Settings surfaces

For settings pages:

- use direct titles only
- keep the background in the light neutral family already implied by the prototype
- reduce heavy card/shadow feel where current groups are too decorative
- keep settings rows highly scannable and task-oriented

For `Downloads` specifically:

- keep current functional grouping
- align the header and surrounding page chrome to the revised prototype language
- preserve swipe-to-delete, retry, and menu actions
- only adjust grouping labels, spacing rhythm, and header presentation where needed

### Search surface

For `SearchPage`:

- keep the existing segmented content model and filters
- align the header to the Android back-bar treatment used in the prototype
- ensure search field, segment row, and filter panel feel like one coherent top region
- do not change search logic, debounce behavior, or result loading

### Mine and profile surfaces

For `MinePage` and `ProfilePage`:

- reduce any extra visual hierarchy that no longer matches the prototype direction
- prefer direct titles and cleaner top actions
- keep segmented content and current provider usage intact
- preserve signed-in and signed-out logic exactly as-is

### Photo detail surface

For `PhotoDetailPage`:

- hero actions should reduce to `Save` and `Share`
- back action should use the shared immersive pattern
- top scrim should be stronger and more intentional
- title and supporting metadata should feel slightly more restrained and Android-native
- existing save, like, download, and related-photo behavior stays unchanged

Important behavior note:

- if the current Flutter screen exposes `Like` separately from the prototype’s hero action set, keep the feature but move it out of the top-right hero-action emphasis if needed rather than deleting functionality

### Collection detail surface

For `CollectionDetailPage`:

- hero actions should reduce to `Share` for the top-right cluster
- owner-only management actions should remain available, but move out of the hero’s primary top-right emphasis when necessary
- hero copy should use simpler hierarchy with less decorative chip treatment
- supporting information such as photo count, visibility, or update context should read as supporting text rather than layered frosted pills

### Collection sheet surfaces

For collection sheets:

- standardize close buttons to a flatter Android-style presentation
- use back affordances only where the flow actually returns to a prior sheet state
- keep sheet copy and controls readable and calm
- reduce floating iOS-like circular chrome in favor of simpler header structure

## Architecture Direction

Keep this work inside presentation and shared UI layers.

Likely responsibility split:

- page files own page composition
- new shared widgets own top-bar and immersive-header language
- existing providers continue to own state and behavior
- existing routes stay unchanged

Shared widget extraction is justified here because the prototype change is explicitly about unifying a cross-page UI language. This is one of the cases where presentation abstraction improves fidelity rather than diluting it.

## Testing Focus

Update tests to reflect the new UI language without overfitting to pixel-perfect details.

### Shared widgets

Add focused widget tests for:

- `AndroidTopBar` title and back-affordance rendering
- `ImmersiveHeroAppBar` action rendering and scrim-dependent structure if practical

### Routing and navigation

Update existing router/widget tests where they currently expect:

- chevron-style icons
- older titles or header shapes

### Page coverage

Ensure key coverage remains for:

- settings navigation and row rendering
- search-page header and navigation affordance
- profile detail structure
- photo detail top actions
- collection detail hero structure
- collection sheet header actions where there is already test coverage or where new coverage is inexpensive and meaningful

### Verification command

At minimum, run:

- `flutter test`

If analyzer coverage remains reasonably fast and stable for these files, also run:

- `flutter analyze`

## Risks And Mitigations

- Risk: shared abstraction could accidentally flatten page-specific needs
  - Mitigation: keep the shared widgets narrow and composable, with page-level control over title, actions, and spacing

- Risk: removing hero actions could unintentionally hide owner-only management affordances
  - Mitigation: keep those actions available, but relocate them out of the primary hero-action cluster where needed

- Risk: tests may be brittle if they assert exact icon choices too aggressively
  - Mitigation: update tests to assert meaningful navigation affordances and structure rather than incidental implementation details where possible

- Risk: the app could drift from prototype by applying the pattern inconsistently
  - Mitigation: adopt shared primitives first and apply them across all mapped surfaces in the same pass

## Acceptance Criteria

- the targeted Flutter pages visually align with the Android-oriented prototype changes from `928e397`
- standard pages use a consistent direct-title Android-style top bar
- immersive detail pages use stronger top scrims and transparent 48dp hero actions
- photo detail top-right actions emphasize `Save` and `Share`
- collection detail top-right hero actions emphasize `Share`, while owner management remains available elsewhere
- collection-related sheets share one calmer header language
- no business logic or route semantics change
- automated tests are updated and pass for the affected surfaces
