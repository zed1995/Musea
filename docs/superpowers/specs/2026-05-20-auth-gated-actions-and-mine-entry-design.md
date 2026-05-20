# Auth-Gated Actions And Mine Entry Design

> **Date**: 2026-05-20
> **Status**: Approved for implementation

## Goal

Add a mixed login guidance experience for Unsplash OAuth so the app handles auth-required actions in a way that feels native to a content product:

- lightweight interception for in-flow actions like like and bookmark
- a dedicated unauthenticated `Mine` surface for account-oriented entry
- clear resume behavior after OAuth completes, cancels, or fails

## Current State

- The app is primarily a public browsing experience driven by Unsplash read APIs.
- `PhotoCard` and photo detail expose like and bookmark affordances, but there is no login state or auth gating yet.
- The bottom navigation includes a `Mine` tab that currently routes straight to `/profile`.
- The existing visual language already favors editorial, immersive content surfaces rather than utility-heavy account screens.

## Approved Interaction Model

This design uses a mixed approach:

- Tapping `Like` or `Bookmark` while signed out opens a login bottom sheet.
- Tapping the `Mine` tab while signed out opens a dedicated unauthenticated `Mine` page.
- Completing OAuth returns the user to the relevant context and, when reasonable, continues the intended action.

This keeps browse flow lightweight while giving the account entry point enough room to explain value.

## Scope

In scope:

- auth gating for like and bookmark entry points
- unauthenticated `Mine` tab experience
- OAuth entry copy, hierarchy, and action rules
- post-auth resume rules
- error, cancel, and retry states

Out of scope:

- final OAuth SDK wiring details
- server-side token persistence design
- adding new post-login account features beyond placeholders needed by the unauthenticated `Mine` page
- changing public profile detail pages such as `/profile/:username`

## Trigger Rules

### Flow actions

The following interactions should be treated as auth-required:

- photo card like
- photo card bookmark
- photo detail like
- photo detail bookmark

When the user is signed out, these actions do not navigate away immediately. They open a bottom sheet instead.

### Account destination

The `Mine` tab is treated as an account destination rather than a quick action.

- signed in: open the logged-in mine experience
- signed out: open an unauthenticated mine page inside the tab

## Entry Surface Design

### 1. Auth sheet for gated actions

The auth sheet is the lightweight interception surface for actions triggered from content.

#### Intent

- preserve the current browse context
- explain why login is needed for the specific action
- provide one obvious path into Unsplash OAuth

#### Presentation

- bottom sheet, not full-screen dialog
- medium height, ideally around 40% to 55% of the screen
- keep some of the underlying content visible
- rounded top corners and brand-consistent spacing

#### Content structure

1. Compact brand marker or icon lockup
2. Action-specific title
3. Short value-oriented support copy
4. Small benefit list
5. Primary CTA: `Continue with Unsplash`
6. Secondary action: `Not now`

#### Copy strategy

The sheet title should reflect the blocked action:

- like: `Sign in to like photos`
- bookmark: `Sign in to save photos`

Support copy should explain value instead of only permission:

- likes sync across devices
- saved inspiration is easier to revisit
- activity stays connected to the user's Unsplash account

#### Behavior

- dismiss on scrim tap, swipe, or `Not now`
- primary CTA starts OAuth immediately
- no tertiary links unless legal requirements force them

### 2. Unauthenticated Mine page

The signed-out `Mine` tab should feel like a real destination, not an oversized empty state.

#### Intent

- make the tab useful and branded even before login
- explain what users unlock by signing in
- provide a stable home for future account-related expansion

#### Page structure

1. Top hero area
2. Main sign-in card
3. Benefits section
4. Lightweight guest section
5. Footer support links or app metadata if needed

#### Hero area

- warm branded welcome rather than generic account chrome
- title direction: `Your visual archive, synced with Unsplash`
- supporting line that frames login as continuity and personalization

#### Main sign-in card

- one strong primary CTA: `Continue with Unsplash`
- short explanation that this powers likes, saves, and future personal surfaces
- optional microcopy for trust, such as `We use your Unsplash account to sync your activity`

#### Benefits section

Recommended three benefit blocks:

- `Liked photos` — revisit favorites you saved
- `Saved collections` — keep inspiration organized
- `Personal space` — access your archive and future preferences

Each benefit should use compact iconography and short copy.

#### Guest section

This section should reassure users they can still browse without logging in:

- `You can keep exploring as a guest`
- mention discover, search, collections, and public profiles

This reduces pressure and makes the login prompt feel respectful.

## OAuth Resume Rules

Resume behavior matters because the user did not begin with login intent.

### After login from a gated action

- return to the same visible screen when possible
- replay the blocked action once
- show immediate visual confirmation if the action succeeds

Examples:

- from `PhotoCard` like: close OAuth flow, stay on the current feed or detail route, then toggle like
- from `PhotoDetail` bookmark: return to the same photo detail route, then complete save if available

### After login from Mine

- stay in the `Mine` tab
- replace the unauthenticated page with the logged-in mine experience
- do not bounce the user back to another route

### Guardrails

- only replay a blocked action once
- if replay fails, keep the user in context and show a clear inline or snack feedback
- never create a loop where the same guard reopens immediately after successful auth

## Cancel And Failure States

### User cancels OAuth

- from sheet: dismiss OAuth callback handling and return to the original screen with no action applied
- from `Mine`: remain on the unauthenticated mine page

No error toast is required for a deliberate cancel unless the platform flow makes the result ambiguous.

### OAuth failure

Use context-sensitive recovery:

- from sheet: show a compact inline error in the sheet if still open, or a snack if the app already returned to content
- from `Mine`: show an inline retry module near the sign-in CTA

Recommended copy direction:

- `Couldn’t connect to Unsplash`
- `Please try again in a moment`

### Token expired / unauthorized during logged-in use

If the session later becomes invalid:

- preserve the current page
- show the same contextual auth sheet for gated actions
- fall back to unauthenticated mine page for the `Mine` tab

## Visual Rules

- The auth sheet should feel fast and calm, with more emphasis on the CTA than on explanatory text.
- The unauthenticated mine page should be more atmospheric and editorial, matching the app's content-first brand.
- Avoid generic enterprise login patterns such as dense forms, heavy dividers, or too many outlined secondary controls.
- Keep the login path single-provider and low-friction since Unsplash OAuth is the core identity system.

## Routing And State Rules

- Introduce an explicit auth state source that UI guards can read synchronously.
- `Mine` should route to a tab-owned surface that can branch between unauthenticated and authenticated content.
- Gated action UI should accept enough context to know:
  - which action was blocked
  - which route or entity triggered it
  - whether a replay should occur after login

## Implementation Shape

Likely files affected:

- `lib/shared/widgets/photo_card.dart`
- `lib/features/photo_detail/presentation/pages/photo_detail_page.dart`
- `lib/shared/widgets/bottom_nav_bar.dart`
- `lib/router/app_router.dart`
- `lib/features/profile/presentation/pages/profile_page.dart` or a new mine-specific tab page
- new auth presentation/state files for gate logic and sheet UI

Preferred structural direction:

- a small auth/session provider
- a reusable auth gate helper for action interception
- a dedicated unauthenticated mine widget rather than embedding all logic directly in the nav bar

## Acceptance Criteria

- Signed-out like and bookmark taps open an auth bottom sheet instead of silently failing or navigating away.
- The auth sheet copy changes based on the blocked action.
- Signed-out `Mine` tab opens a real unauthenticated mine page.
- OAuth success returns users to the right context and resumes at most one blocked action.
- OAuth cancel leaves the user in a predictable state with no accidental action applied.
- OAuth failure exposes a clear retry path.
- The solution fits the current visual language and does not turn login into a separate mandatory browsing flow.
