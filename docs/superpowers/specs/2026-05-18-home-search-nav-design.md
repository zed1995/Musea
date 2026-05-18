# Home Search And Nav Design

Date: 2026-05-18

## Goal

Align the home top area and bottom navigation with the approved prototype direction, and add a dedicated full-screen search page that feels complete using the current Flutter app structure.

## Scope

In scope:

- Keep `/discover` as the default home route
- Remove the discover item from the bottom tab bar
- Rebuild the home top area to match `prototype/home.html`
- Add a dedicated `/search` route and page based on `prototype/search.html`
- Implement search interactions and result rendering using the current providers and entities
- Add widget tests for the updated navigation and search behavior

Out of scope:

- Renaming `/discover` to `/home`
- Adding a new backend search API
- Reworking collections or mine page layouts beyond navigation integration

## Approved Interaction Model

- The app opens on `/discover`
- The bottom tab bar contains only `Collections` and `Mine`
- The home search pill is an entry point, not an inline editable field
- Tapping the home search pill opens a dedicated `/search` page
- The search page supports:
  - free text input
  - clearing input
  - switching segments between `Photos`, `Collections`, and `Users`
  - filter chip selection
  - returning to the previous page

## Data Strategy

- `Photos` search results use `photosProvider(1)` and filter locally by:
  - photo description
  - alt description
  - user name
  - user username
  - tag titles
- `Collections` search results use `collectionsProvider(1)` and filter locally by:
  - collection title
  - collection description
  - curator name
  - curator username
- `Users` search results are derived from the unique users attached to `photosProvider(1)` and filtered locally by:
  - user name
  - username
  - bio
  - location

This keeps the page functional now and leaves a clean seam for a future remote search endpoint.

## Visual Rules

- Home top area keeps the rounded search shell and compact random button from the prototype
- Search page uses a sticky search shell with:
  - back button
  - active text input
  - segment control
  - filter chips
- Search results keep separate rendering per segment:
  - photos in a rounded 2-column grid
  - collections as image cards with overlay copy
  - users as list rows with avatar and action button

## Routing Rules

- `/discover` remains part of the shell navigator and still shows the bottom bar
- `/search` is pushed on the root navigator so it behaves like a full page and does not show the bottom bar
- Existing detail routes remain unchanged

## Acceptance Criteria

- Bottom navigation shows only `Collections` and `Mine`
- Home search entry opens `/search`
- Search page supports input, clear, segment switching, and filtered results
- Search page renders empty states honestly when no items match
- Widget tests cover the revised navigation and the main search behaviors
