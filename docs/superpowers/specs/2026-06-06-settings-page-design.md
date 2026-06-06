# Settings Page Design

> **Date**: 2026-06-06
> **Status**: Draft for review

## Goal

Add a dedicated settings page reachable from the Mine tab, focused on practical first-version controls:

- Language selection
- Download over Wi-Fi only
- Cache visibility and clearing
- Download task management
- App version display
- Feedback shortcut to the project GitHub link
- Sign out

This first version should feel complete enough to use immediately, while keeping scope tight and leaving room for later expansion.

## Current State

- `Mine` already exists as a profile/personal space entry point with signed-in and signed-out variants.
- The signed-in Mine experience is content-oriented rather than settings-oriented.
- There is no dedicated settings route or settings feature module yet.
- Download behavior exists, but there is no centralized settings surface for download preferences or task management.

## Product Direction

The settings experience should be a separate page entered from `Mine`, not embedded inline in the existing Mine lists.

Why:

- `Mine` remains focused on identity, saved content, and personal activity.
- Settings are easier to scan when grouped into a dedicated utility page.
- Account actions like `Sign out` should be visually separated from regular profile content.

## Information Architecture

### Entry

- Add a `Settings` row inside the Mine tab
- Tapping the row pushes a dedicated `SettingsPage`

### SettingsPage groups

#### Preferences

- `Language`
- `Download over Wi-Fi only`

#### Storage

- `Cache`
- `Downloads`

#### About

- `Version`
- `Feedback`

### Bottom action

- A standalone red `Sign out` button pinned near the bottom of the page flow
- `Sign out` is not presented as a normal list item

## Interaction Design

### SettingsPage

- Standard top app bar with `Settings` title
- Grouped list sections with clear spacing between groups
- Utility-first visual language: calm, readable, easy to scan
- The page should prioritize task completion over decorative density

### Language

- Enters a secondary page
- Uses a single-choice list
- First-version options:
  - `Follow system`
  - `English`
  - `中文`
- The selected option shows an explicit check state
- Selection should persist locally
- UI should support immediate state update after selection

Note:
The page structure and persistence should be implemented even if full app-wide localization wiring is not finished in the same pass.

### Download over Wi-Fi only

- Inline switch on the main settings page
- Changes apply immediately
- Setting persists locally
- No confirmation dialog needed

### Cache

- Main row shows current cache size on the trailing side
- Tapping the row opens a lightweight confirmation flow or a minimal detail screen
- Primary action: `Clear cache`
- After clearing:
  - size refreshes
  - user gets lightweight success feedback

Important copy requirement:

- Clearly state that clearing cache does not remove completed downloads

### Downloads

- Enters a download management page
- First version supports three states:
  - `Downloading`
  - `Completed`
  - `Failed`
- Each item should show enough context to identify the task quickly
- Failed items should expose a `Retry` action
- Empty states should be explicit rather than leaving blank space

### Version

- Read-only display row
- Shows current app version on the trailing side
- No tap behavior in v1

### Feedback

- Tapping opens the project GitHub link
- This replaces a richer in-app feedback flow for the first version
- Label can remain `Feedback` as long as the affordance is clearly external

### Sign out

- Rendered as a standalone red button near the bottom
- Tapping opens a confirmation dialog
- Confirmation copy should explain that the current account session will be removed from this device
- Confirming signs the user out and returns Mine to its signed-out state

## State and Error Handling

### Page loading

- The settings page itself should render immediately when possible
- Individual trailing values may resolve after the initial frame
- Avoid full-page blocking loaders for small local state reads

### Setting updates

- Prefer immediate UI feedback for successful local updates
- Avoid noisy success messaging for simple toggles unless the action is destructive

### Failure handling

- Failures should stay localized to the relevant setting row or follow-up surface
- A cache-clear failure, for example, should not replace the whole settings page with an error screen

### Empty states

- Download manager needs explicit empty states
- Cache should still display meaningfully when the size is zero

## Architecture Direction

Create a dedicated `settings` feature rather than placing settings logic directly inside `profile`.

Suggested responsibility split:

- `Mine` feature: entry point only
- `settings` presentation: page layout, groups, rows, dialogs, detail pages
- `settings` providers/controllers: load and update settings state
- local persistence layer: stores language preference, download policy, and related values

This keeps Mine lightweight and prevents account/profile concerns from absorbing app-wide settings behavior.

## First-Version Scope

### In scope

- Settings entry from Mine
- Dedicated settings route/page
- Language selection page with local persistence
- Download over Wi-Fi only toggle with local persistence
- Cache size display and clear action
- Download management page with basic task states
- Version display
- Feedback external link to project GitHub
- Sign out confirmation and session clearing

### Intentionally out of scope

- Full multi-language rollout for every screen in the app
- Theme mode settings
- Advanced download filters, sorting, bulk actions, or batch deletion
- Detailed storage breakdown by cache type
- Notifications, privacy policy, experiments, or advanced account controls
- Rich in-app feedback composer

## Testing Focus

Add coverage for the new surface without overfitting implementation details.

### Mine

- shows a `Settings` entry
- navigates to `SettingsPage`

### SettingsPage

- renders the three groups
- renders all expected rows
- shows the standalone `Sign out` action

### Language

- selected state updates correctly
- persisted value is restored

### Download over Wi-Fi only

- switch reflects persisted state
- toggling updates state

### Cache

- cache size renders
- clear action triggers refresh
- destructive confirmation flow behaves correctly if used

### Downloads

- downloading/completed/failed states render
- failed task retry action is available
- empty state renders

### Sign out

- confirmation dialog appears
- confirming signs the user out
- Mine returns to signed-out presentation

## Open Follow-Up After Spec Approval

Before implementation planning, create a UI prototype for:

- the main `SettingsPage`
- the `Language` selection page
- the `Downloads` management page

The prototype should validate layout rhythm, section styling, row density, and the visual separation of the bottom `Sign out` action.
