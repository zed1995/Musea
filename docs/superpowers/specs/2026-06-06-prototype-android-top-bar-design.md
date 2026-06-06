# Prototype Android Top Bar Design

## Goal

Unify the `prototype/` HTML pages around a more native Android navigation language.
The main change is to remove extra decorative hierarchy in top bars and make headers feel closer to Android app bars instead of custom hero sections.

## Scope

This applies to all prototype pages with a visible top header, grouped into four navigation patterns:

1. Primary tab pages
   `home.html`, `explore.html`, `collections.html`, `mine-guest.html`, `profile.html`, `settings.html`
2. Standard secondary pages
   `search.html`, `search-users.html`, `search-collections.html`, `search-photos-filter.html`, `settings-language.html`, `settings-downloads.html`, `profile-detail.html`, `collection-remove-photos.html`
3. Immersive detail pages
   `photo-detail.html`, `photo-detail-download.html`, `collection-detail.html`, `collection-manage-sheet.html`, `collection-delete-sheet.html`
4. Sheet and modal-style flows with top controls
   `collection-create-sheet.html`, `collection-edit-sheet.html`, `collection-save-sheet.html`, `auth-sheet-like.html`

## Navigation Rules

### 1. Primary Tab Pages

Use a plain Android-style top app bar:

- Single-line page title only
- No kicker labels such as `Library` or `Workspace`
- No hero-shell framing for the header itself
- No oversized display title
- Right-side action only when it represents a real primary page action

Expected outcomes:

- `Collections` keeps a compact add action
- `Mine` removes decorative top controls when they are not essential
- `Settings` becomes a primary destination with a plain title bar rather than a back-style hero header
- `Home` and `Explore` keep functional search-first structures, but any top framing should stay flat and utilitarian

### 2. Standard Secondary Pages

Use a standard Android secondary app bar:

- Left-aligned back arrow
- Single-line title
- Flat background
- Thin divider or spacing only, no hero wrapper
- Right side empty unless a clear page action exists

This pattern should feel consistent across search results, settings subpages, profile detail, and selection/removal flows.

### 3. Immersive Detail Pages

Keep the image-first experience, but switch to a more native Android transparent app bar treatment:

- Top controls stay over the image
- Buttons become simpler and less ornamental
- Overlay gradients should support readability, not create a premium “glass” effect
- Title and metadata should not compete with floating chrome
- The top action row should read as a transparent app bar, not a custom hero overlay

This preserves immersion while aligning with Android detail-page behavior.

### 4. Sheet and Modal Flows

For sheet-like pages, simplify the top control row:

- Keep the back or close affordance obvious
- Reduce decorative blur, glass, and layered top overlays
- Use compact, utility-first control styling
- Let the sheet content carry the visual weight instead of the header treatment

## Visual Rules

- Remove `Library`, `Workspace`, and similar helper labels from page headers
- Prefer flat surfaces over hero headers for page-level navigation
- Reduce shadow, blur, frosted, and capsule-heavy top chrome
- Use spacing and alignment instead of stacked title treatments
- Keep titles readable, medium emphasis, and system-like in scale
- Maintain consistency between pages that belong to the same navigation depth

## Non-Goals

- No redesign of page body content beyond what is needed to support the new top bars
- No change to bottom tab bar structure in this pass unless needed for consistency with the updated headers
- No rewrite of flow logic or navigation destinations

## Implementation Notes

- Shared utility class names may be introduced independently per file if that is the fastest path for prototype consistency
- Header simplification takes priority over preserving existing decorative code
- When a page currently mixes two patterns, prefer the simpler Android interpretation

## Review Checklist

- No remaining `Library` or `Workspace` labels in top headers
- Primary pages use plain title bars
- Secondary pages use consistent back-arrow app bars
- Immersive pages keep transparent app bars without heavy ornament
- Sheet flows no longer feel like custom hero headers
