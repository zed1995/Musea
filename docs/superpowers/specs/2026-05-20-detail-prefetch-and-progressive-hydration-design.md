# Detail Prefetch And Progressive Hydration Design

> **Date**: 2026-05-20
> **Status**: Approved in conversation, pending written spec review

## Goal

Improve the transition from photo and collection list surfaces into detail pages by rendering list-known data immediately, then progressively filling in detail-only sections after the detail request completes.

## Current State

- Photo cards and collection cards navigate by id only.
- Photo detail and collection detail both wait for full detail requests before rendering the page body.
- Direct navigation, in-app navigation, and retry flows all use the same full-page loading/error states.

This makes the app feel slower than it needs to, especially when users already saw a usable subset of the content on the previous screen.

## Product Direction

Use a staged detail loading model:

- If navigation comes from a list/grid/card that already has a `Photo` or `Collection` object, pass that object through routing as the initial detail payload.
- Render all fields that are already known from the initial object immediately.
- Fetch the canonical detail payload in the background and replace/extend the initial content when the request resolves.
- For fields that are not yet available from the initial object, render section-level skeleton placeholders instead of blocking the whole page.
- If the background detail request fails, keep the already-rendered content on screen and show local retry affordances only for the missing sections.
- If the user opens a detail page through a deep link or any path with no initial object, keep the existing full-page loading/error behavior.

## Scope

This change applies to:

- Photo detail opened from photo list/grid surfaces
- Collection detail opened from collection list surfaces

This change does not introduce:

- Persistent local caches
- New repository APIs
- Offline support
- Prefetching separate from normal navigation

## Data Model Strategy

The existing domain entities already contain most of the fields needed for above-the-fold rendering.

### Photo

List surfaces already know enough to render these detail regions immediately:

- Hero image
- User row
- Stats strip
- Description when present
- Basic color section
- Download button

These areas may still need deferred hydration:

- EXIF rows
- Tags when absent from the list payload
- "More from photographer" if that section depends on separate requests

### Collection

List surfaces already know enough to render these detail regions immediately:

- Hero cover image
- Title
- Curator name
- Total photo count
- Featured/private state
- Preview image strip
- Summary text when present
- Fact rows that depend on list-known fields

These areas may still need deferred hydration:

- Any detail-only collection metadata that the list payload does not include
- Sections whose content depends on the collection detail request rather than the already-loaded collection photos feed

## Routing Strategy

Route paths remain the same:

- `/photo/:id`
- `/collection/:id`

Navigation callers will pass the list object through router extras when they have one available.

Detail pages will accept:

- required id
- optional initial entity from route extra

This keeps deep links stable while allowing richer in-app transitions.

## Screen Behavior

### In-app navigation with initial entity

1. Push detail route with `extra`
2. Detail page renders immediately from the initial entity
3. Background request starts
4. Missing regions show skeleton placeholders until hydrated
5. Background success swaps in full sections
6. Background failure keeps current content and shows local retry for missing sections

### Deep link / no initial entity

1. Open detail route by id only
2. Show full-page loading
3. Show full-page error on failure
4. Show full detail content on success

## UI Rules

### Photo detail

- Do not replace the entire page with a spinner if an initial photo is present.
- Only deferred sections may show skeletons.
- The hero image and top content should remain stable while late data arrives.
- If EXIF or tags are unavailable initially, reserve their space with lightweight skeleton rows/chips only when those sections are expected to appear after hydration.

### Collection detail

- Keep the hero, summary, preview, and fact layout visible immediately from the initial collection.
- Show skeletons only in sections whose data is still unknown.
- Do not blank the already-rendered hero or summary because a late request failed.

## Error Handling

- Background hydration failure is a partial failure, not a page failure.
- Show inline retry UI for the missing section or a compact page-level banner/message near deferred content.
- Retry should invalidate the detail provider without discarding the initial entity already on screen.
- Direct-load failure with no initial entity remains a full-page error state.

## Testing Strategy

- Routing tests for passing `extra` objects into photo and collection detail pages
- Widget tests proving detail pages render initial content without waiting for the async detail response
- Widget tests proving deep-link behavior still shows full loading/error when no initial entity exists
- Widget tests proving partial failure keeps initial content visible and exposes retry UI for deferred sections

## Success Criteria

- Tapping a photo or collection card opens a visually complete first frame immediately when list data is available
- Detail-only fields appear progressively without reflowing the entire page into loading/error states
- Deep-link behavior remains correct
- Partial network failure no longer destroys already-known content
