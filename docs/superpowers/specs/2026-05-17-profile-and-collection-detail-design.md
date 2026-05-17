# Profile And Collection Detail Design

Date: 2026-05-17

## Goal

Implement a dedicated profile detail page and a collection detail page that match the UI structure and visual hierarchy of the `prototype` HTML files, while continuing to use the existing Flutter routing and data providers wherever possible.

This work explicitly does not merge the profile detail page with the `/profile` tab. The tab remains a separate "mine" surface.

## Scope

In scope:

- Rebuild `ProfilePage` at `/profile/:username` to match `prototype/profile-detail.html`
- Rebuild `CollectionDetailPage` at `/collection/:id` to match `prototype/collection-detail.html`
- Reuse existing providers, entities, and navigation where possible
- Add presentation-only helpers or private widgets inside the page files when needed
- Add widget tests covering the new page structures and critical fallback states

Out of scope:

- Reworking the `/profile` tab into the profile detail layout
- Adding new backend APIs for user likes or user collections
- Broad refactors of shared widgets that are unrelated to these two pages
- Persisting follow, save, or share actions

## Existing Constraints

- `prototype/profile.html` is the mine tab reference, not the profile detail page
- `prototype/profile-detail.html` is the reference for `/profile/:username`
- `prototype/collection-detail.html` is the reference for `/collection/:id`
- `ProfilePage` currently shows only a simple hero and a photo list
- `CollectionDetailPage` currently shows only a cover image, basic copy, and a photo feed
- The current data layer exposes:
  - user profile data
  - user photos
  - collection detail data
  - collection photos
- The current data layer does not expose:
  - user collections
  - user liked photos
  - collection save state
  - collection publish and update metadata beyond what is already present on the entity

## Approach

Use a page-level UI rebuild with minimal data-layer changes.

Why this approach:

- It preserves the current route model and provider graph
- It minimizes regression risk outside the two target pages
- It allows strict prototype alignment where the design matters most
- It avoids premature shared-component abstraction that could slow down pixel alignment

## Profile Detail Page Design

### Page Structure

The page will be rebuilt into these visual sections:

1. Top hero section with light background
2. Back and share circular action buttons
3. Centered avatar, name, username, location, bio, and follow button
4. Three metric cards for photos, collections, and likes
5. Summary text line below the metrics
6. Sticky segmented control for `Photos`, `Collections`, and `Likes`
7. Content sections below the segmented control

The page is a dedicated detail surface and should feel visually distinct from the mine tab.

### Data Mapping

- Name: `user.name`
- Username: `@${user.username}`
- Location: `user.location` when present, omitted when absent
- Bio: `user.bio` when present, omitted when absent
- Avatar: `user.profileImageLarge`, with medium or small variants as fallback if needed
- Photos metric: `user.totalPhotos`
- Collections metric: `user.totalCollections`
- Likes metric: `user.totalLikes`
- Photos content: `userPhotosProvider(username)`

### Content Strategy For Missing Data

The profile prototype contains three tabbed content families, but current live data only guarantees photo content.

To stay visually faithful without inventing fake product behavior:

- The segmented control will be rendered exactly as a visual control
- The first implementation will keep `Photos` selected
- The photos section will be fully real and driven by `userPhotosProvider`
- The `Collections` section will render a prototype-matching section shell with a graceful empty message because user collection data is not currently available
- The `Likes` section will render a prototype-matching section shell with a graceful empty message because liked-photo data is not currently available

This preserves the layout and interaction model without introducing fake records or unsupported network calls.

### Visual Rules

- Use a soft neutral hero background similar to the prototype
- Use rounded white action buttons with light borders
- Keep the avatar, name, and metrics centered
- Use compact uppercase labels and tighter tracking for secondary section labels
- Use rounded content tiles and cards with generous whitespace
- Keep the segmented control sticky while scrolling

### Error And Empty States

- Full-page loading and error behavior remains driven by `userProfileProvider`
- If photos fail while profile data succeeds, keep the profile hero visible and show an inline error state in the content area
- If the user has no photos, show a calmer in-page empty state instead of falling back to the old page layout

## Collection Detail Page Design

### Page Structure

The page will be rebuilt into these visual sections:

1. Immersive cover hero with overlay gradient
2. Floating back, save, and share buttons
3. Metadata chips above the title
4. Collection title
5. Curator row with avatar, username context, and follow button
6. Summary card
7. Preview card for the first four photos
8. Facts card
9. Feed section for the full photo list

### Data Mapping

- Cover image: `collection.coverPhoto?.urlRegular`, otherwise first preview photo, otherwise a neutral placeholder
- Title: `collection.title`
- Description: `collection.description` when present; otherwise use prototype-compatible fallback copy that indicates no description is available
- Photo count chip: `collection.totalPhotos`
- Curator name: `collection.user?.name`
- Curator username: `collection.user?.username`
- Curator avatar: `collection.user?.profileImageMedium`
- Curator collections count: `collection.user?.totalCollections` when available
- Preview images: first four items from `collection.previewPhotos`, then fallback to the first items from `collectionPhotosProvider`
- Feed content: `collectionPhotosProvider(collectionId)`

### Facts Strategy

The prototype shows publish and update facts. Existing entities may not contain the exact fields needed for a perfect one-to-one mapping.

Fallback rules:

- When a real date-like field exists on the entity, show it
- When no matching field exists, omit that fact pill or row instead of manufacturing data
- Keep the card structure intact even when only part of the facts set is available

### Visual Rules

- Keep the hero overlay dark enough for white text legibility
- Use frosted or translucent top action buttons
- Use rounded section cards with a subtle border and shadow
- Preserve the prototype order: summary first, preview second, facts third, feed last
- Use a denser image layout than the current generic feed so the page feels closer to the reference

### Error And Empty States

- Full-page loading and error behavior remains driven by `collectionDetailProvider`
- If the collection loads but the photo list fails, keep the hero and metadata sections visible and show an inline content error below
- If the collection contains no photos, keep the hero and cards visible and show a specific empty feed state

## Routing And Separation Rules

- `/profile` remains the mine tab surface
- `/profile/:username` remains the dedicated profile detail surface
- `/collection/:id` remains the dedicated collection detail surface
- Navigation from photos and collections continues to target these detail routes

No route semantics change in this work.

## Testing Strategy

Add or update widget tests to cover:

- `ProfilePage` renders the prototype-aligned hero with metrics and segmented control
- `ProfilePage` handles missing optional fields such as location or bio without layout breakage
- `CollectionDetailPage` renders the hero title, curator row, and section cards
- `CollectionDetailPage` handles missing description or missing cover gracefully
- Content-specific error states stay below the hero instead of replacing the whole page when only the secondary provider fails

These tests should focus on rendered structure and fallback behavior rather than screenshot precision.

## Implementation Plan Boundary

Implementation should stay local to the following likely files unless a small helper extraction is clearly justified:

- `lib/features/profile/presentation/pages/profile_page.dart`
- `lib/features/collections/presentation/pages/collection_detail_page.dart`
- related widget tests under `test/features/...`

Shared-component extraction is optional and should only happen if it materially improves clarity without weakening prototype accuracy.

## Risks And Mitigations

- Risk: trying to emulate unsupported tabs with fake data
  - Mitigation: render prototype-faithful section shells with honest empty states

- Risk: over-abstracting shared UI before the pages are visually correct
  - Mitigation: keep most helpers private to each page for this iteration

- Risk: existing generic photo feed may not match the detail-page visual density
  - Mitigation: allow the detail pages to own their feed layouts instead of forcing reuse

- Risk: long names, long descriptions, or missing images may break the visual balance
  - Mitigation: add ellipsis, safe wrapping, and neutral placeholders that preserve spacing

## Acceptance Criteria

- The profile detail page is visually and structurally aligned with `prototype/profile-detail.html`
- The collection detail page is visually and structurally aligned with `prototype/collection-detail.html`
- The mine tab remains separate from the profile detail page
- Real data continues to drive all supported content
- Unsupported content areas degrade gracefully instead of showing fake data or broken layouts
- Widget tests cover the main structure and fallback behavior
