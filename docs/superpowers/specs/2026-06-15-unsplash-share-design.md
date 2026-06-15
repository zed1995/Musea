# Unsplash Share Design

Date: 2026-06-15

## Goal

Implement sharing for photo, collection, and user detail surfaces by sharing each entity's canonical Unsplash page URL, while keeping the UI behavior consistent across the app.

## Scope

In scope:

- Add share support to photo detail, collection detail, and profile detail pages
- Use Unsplash page URLs from entity data rather than Musea deep links
- Support both system share and copy-link actions from a shared interaction pattern
- Add the missing photo HTML link mapping from the Unsplash API model into the domain entity
- Add focused tests for data mapping, share interaction, and missing-link fallbacks

Out of scope:

- Sharing Musea deep links
- Sharing download links or download locations
- Adding server-side short links or any backend changes
- Reworking unrelated page layouts or navigation

## Confirmed API Facts

The design is based on both the Unsplash API documentation and live response samples.

- User responses include `links.html`, with values like `https://unsplash.com/@spaciba`
- Collection responses include `links.html`, with values like `https://unsplash.com/collections/2208769/united-states`
- Photo responses include `links.html`, with values like `https://unsplash.com/photos/brown-dock-beside-body-of-water-1uxvZU6-9Uc`

Current app state:

- `User` already exposes `links?.html`
- `Collection` already exposes `links?.html`
- `PhotoModel` already parses `links.html`
- `Photo` does not yet expose a corresponding HTML share link in the domain entity

## Approach

Use a lightweight shared share layer so all three surfaces behave the same way.

Why this approach:

- It keeps page widgets simple and focused on UI
- It avoids duplicating share and copy-link logic across three pages
- It gives the app one place to enforce the rule that only canonical Unsplash page URLs may be shared
- It leaves room for later additions such as analytics, richer share text, or alternate actions without rewriting each page

## Data Design

### Canonical Share Source

Every share action must resolve to the entity's Unsplash `links.html` value.

- Photo share source: `photo.htmlLink` mapped from `PhotoLinksModel.html`
- Collection share source: `collection.links?.html`
- User share source: `user.links?.html`

### Photo Entity Change

`Photo` should gain a dedicated field for the HTML page URL so that the presentation layer does not need to know about API model internals.

Recommended shape:

- Add `final String? htmlLink;` to `Photo`
- Include it in `toJson` and `fromJson`
- Map it in `PhotoModel.toEntity()` from `links?.html`

`Collection` and `User` do not need structural changes because the current entities already expose `links?.html`.

## Interaction Design

### Shared Entry Pattern

Each target page keeps its existing share button location:

- Photo detail: the hero app bar share icon
- Collection detail: the hero app bar share icon
- Profile detail: the `AndroidTopBar` trailing share icon

Tapping the share button opens a bottom sheet with two actions:

- `Share`
- `Copy link`

This pattern is preferred over immediate share because:

- It matches the requirement to support both system share and copy-link
- It keeps behavior consistent across all three entity types
- It gives the app a natural place for later actions without retraining the user

### Action Behavior

`Share`

- Open the native system share sheet
- Share the canonical Unsplash page URL as the primary payload
- Keep initial text minimal instead of generating verbose templates

`Copy link`

- Copy the canonical Unsplash page URL to the clipboard
- Show a success confirmation using the app's existing feedback pattern, such as a `SnackBar`

### Missing Link Fallback

If the target entity does not provide a usable HTML page URL:

- Do not attempt to share a download URL
- Do not attempt to derive a Musea route URL
- Show a user-facing fallback message such as "Current item can't be shared right now"

The share button remains visible even when the link is unavailable so the layout stays stable, but the action degrades honestly.

## Shared Share Layer Design

Introduce a small shared helper or service in a shared presentation-safe location.

Responsibilities:

- Resolve the canonical share URL for the specific entity type
- Expose an operation for system share
- Expose an operation for copy link
- Return a clear success or failure result so the page can show the right feedback

Non-responsibilities:

- It should not fetch missing data
- It should not navigate
- It should not know page layout details

This layer can start small. It does not need a heavy abstraction hierarchy as long as the public surface is consistent and testable.

## Dependency Strategy

Use a platform share package for native share sheet support.

Recommended dependency:

- `share_plus`

Reasoning:

- It is the standard Flutter choice for native share sheets
- It keeps platform code out of page widgets
- It works well alongside a separate clipboard action

Clipboard support can continue to use Flutter's built-in clipboard APIs.

## Testing Strategy

Add or update tests in three areas.

### Data Mapping

- Verify `PhotoModel` maps `links.html` into `Photo.htmlLink`
- Verify absent photo HTML links map to `null`

### Shared Share Logic

- Given a photo with `htmlLink`, the shared share layer resolves the correct URL
- Given a collection or user with `links?.html`, the shared share layer resolves the correct URL
- Given a missing URL, the shared share layer returns a failure state instead of falling back to another link type

### Widget Interaction

- Tapping the share button on each target page opens the action sheet
- Tapping `Copy link` triggers the copy path and success feedback
- Missing-link cases show the fallback message

Widget tests do not need to launch the real native share sheet. They only need to verify that the page delegates to the shared share layer correctly.

## Likely Implementation Boundary

Most of the work should stay within:

- `lib/features/discover/domain/entities/photo.dart`
- `lib/features/discover/data/models/photo_model.dart`
- a new shared share helper or service under `lib/shared/` or another existing shared location
- `lib/features/photo_detail/presentation/pages/photo_detail_page.dart`
- `lib/features/collections/presentation/pages/collection_detail_page.dart`
- `lib/features/profile/presentation/pages/profile_page.dart`
- related tests under `test/features/...` and `test/shared/...` if needed

No route changes are required for this work.

## Risks And Mitigations

- Risk: photo sharing is implemented differently from collection and user sharing
  - Mitigation: force all share entry points through one shared helper

- Risk: pages silently fall back to non-canonical URLs
  - Mitigation: explicitly restrict the share source to `links.html`

- Risk: missing-link behavior becomes inconsistent across pages
  - Mitigation: centralize success and failure handling in the shared share layer

- Risk: native share behavior makes widget tests brittle
  - Mitigation: keep the platform boundary behind an injectable helper and test delegation rather than native UI

## Acceptance Criteria

- Photo detail, collection detail, and profile detail all expose a share entry point
- All three surfaces offer both system share and copy-link actions
- Shared URLs always come from canonical Unsplash HTML links
- `Photo` exposes the missing HTML link needed for sharing
- Missing-link states fail gracefully with user feedback
- Tests cover the new photo mapping and the main share interactions
