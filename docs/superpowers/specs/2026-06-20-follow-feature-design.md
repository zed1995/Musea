# Follow Feature Design

Date: 2026-06-20

## Goal

Make the existing static `Follow` text in Photo Detail and Profile Page interactive. Tapping the button calls the Unsplash `follow` / `unfollow` API, persists the resulting follow status via the `User.followedByUser` field (already present on the domain entity and already mapped from `followed_by_user` in the API response), and shows an optimistic loading state while the request is in flight. Unauthenticated taps open the existing auth gate sheet.

## Non-Goals

- No follower / following **count** UI (counts are already on `User`; surfacing them is a separate workstream).
- No "Following" list page under Mine.
- No push notifications for followed photographers.
- No set-as-wallpaper work (deferred — see dark mode spec for the active scope).

## Confirmed API Facts

The design is based on the live Unsplash API.

- `POST /users/:username/follow` — body contains the updated user object; the server's response **flips `followed_by_user`** and adjusts `followers_count` accordingly. Requires OAuth Bearer token.
- `DELETE /users/:username/follow` — same response shape, flips back to `false`.
- `GET /users/:username` and all photo endpoints already return `followed_by_user` when the request is authenticated. The mapping is already implemented in `UserModel.fromJson` → `User.followedByUser`.

Current app state:

- `User.followedByUser` (`bool?`) — **already present** on the domain entity
- `UserModel.followedByUser` — **already present**, mapped from `followed_by_user`
- `Photo.user.followedByUser` — **already present** via `user.toEntity()`
- `ProfileRemoteDataSource.getUserProfile` — already returns a `UserModel` carrying the field
- `AuthRemoteDataSource.getCurrentUser` — uses a hand-rolled `AuthUser.fromJson` (see "Auth scope" below)
- `_UserRow` in `photo_detail_page.dart` — static `Container` styled text, no interaction
- Profile Page hero — has a static `Follow` text in the existing prototype but **the production code does not yet render a follow button**; we'll add it as a new widget slot

## Approach

Three small, isolated pieces:

1. A new `follow` feature module that owns the RPC data source and the controller.
2. A reusable `FollowButton` widget that all surfaces consume.
3. Light touch-ups at the call sites: Photo Detail `_UserRow` and Profile Page hero region.

Why a dedicated `follow` feature:

- It has no UI surface of its own; it is purely a domain/data layer that other features plug into.
- It is testable in isolation (mock the data source, assert controller state transitions).
- It avoids polluting `auth` or `profile` with cross-feature responsibilities.

Why a dedicated `FollowButton` widget:

- Photo Detail and Profile Page want different sizes / visual weights.
- The widget owns the optimistic-update + revert logic so callers don't have to.
- Auth-gate logic lives in one place and is impossible to forget.

## Architecture

### New module: `lib/features/follow/`

```
follow/
├── data/
│   ├── datasources/
│   │   └── follow_remote_datasource.dart   # follow(username), unfollow(username)
│   └── repositories/
│       └── follow_repository_impl.dart    # Either<Failure, User> wrapper
├── domain/
│   ├── repositories/
│   │   └── follow_repository.dart         # interface
│   └── usecases/                          # (intentionally empty for v1)
├── presentation/
│   ├── controllers/
│   │   └── follow_controller.dart         # AsyncNotifier-style state machine
│   ├── providers/
│   │   └── follow_providers.dart          # followRepositoryProvider, followControllerProvider(username)
│   └── widgets/
│       └── follow_button.dart             # public widget consumed by Photo Detail & Profile
└── README.md                              # feature overview
```

#### `follow_remote_datasource.dart`

```dart
abstract class FollowRemoteDataSource {
  Future<User> follow(String username);
  Future<User> unfollow(String username);
}

class FollowRemoteDataSourceImpl implements FollowRemoteDataSource {
  FollowRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<User> follow(String username) async {
    final response = await _dioClient.post(
      ApiConstants.userFollow(username),  // /users/:username/follow
    );
    return UserModel.fromJson(response).toEntity();
  }

  @override
  Future<User> unfollow(String username) async {
    final response = await _dioClient.delete(
      ApiConstants.userFollow(username),
    );
    return UserModel.fromJson(response).toEntity();
  }
}
```

The data source returns the **updated `User`** rather than `void` so callers can use the response to overwrite their local `User` (which now has the flipped `followedByUser` and the updated `followers_count`).

#### `api_constants.dart` addition

```dart
static String userFollow(String username) => '$users/$username/follow';
```

#### `follow_repository_impl.dart`

Thin wrapper that converts `DioException` / `ServerException` into `Failure`, mirroring the pattern used by every other repository in the app. Returns `Either<Failure, User>`.

#### `follow_controller.dart`

State machine per `username`:

```dart
sealed class FollowState {
  const FollowState();
}
class FollowIdle extends FollowState { final User user; const FollowIdle(this.user); }
class FollowInFlight extends FollowState { final User user; const FollowInFlight(this.user); }
class FollowFailed extends FollowState { final User user; final Failure failure; const FollowFailed(this.user, this.failure); }
```

The controller exposes a single `toggle(User user)` method. The toggle does, in order:

1. Read `authControllerProvider`. If unauthenticated, call `showAuthGateSheet(context, ref)` and return early without mutating state.
2. If a request is already in flight for this user, no-op (idempotent).
3. Flip `user.followedByUser` locally (optimistic) and emit `FollowInFlight`.
4. Call `followRepository.follow(username)` or `unfollow(username)` based on the desired new state.
5. On success, emit `FollowIdle` with the **response `User`** (overrides the optimistic guess with the server's truth — `followers_count` is now correct too).
6. On failure, emit `FollowFailed` with the **original** `user` (revert), then show a SnackBar `followUpdateFailed`.

Note on the auth gate: the controller is a plain `AsyncNotifier`-style class, so it cannot reach `BuildContext` on its own. The `showAuthGateSheet` call must happen in the widget layer. The pattern is identical to what Photo Detail's `_StatsStrip` already does for like — the widget reads the auth state and dispatches to the controller only if the user is authenticated.

#### `follow_button.dart`

```dart
enum FollowButtonSize { compact, regular }

class FollowButton extends ConsumerWidget {
  const FollowButton({super.key, required this.user, this.size = FollowButtonSize.regular});

  final User user;
  final FollowButtonSize size;
  ...
}
```

- Reads `followControllerProvider(user.username)` for the current `FollowState`.
- If the state is `FollowInFlight` for the same `user`, renders a small `CircularProgressIndicator` inside the existing pill (button still has the same shape, but the label is replaced by a 14dp spinner; the pill is non-tappable while in flight).
- Otherwise renders the pill with label `following` when `user.followedByUser == true`, else `follow`.
- On tap: read `authControllerProvider`; if unauthenticated, call `showAuthGateSheet(context, ref, title: ..., body: ...)` and return. Otherwise call `ref.read(followControllerProvider(user.username).notifier).toggle(user)`.
- Visual:
  - `compact` — height 28, horizontal padding 12, font 11 (matches the existing static `_UserRow` Follow pill).
  - `regular` — height 36, horizontal padding 18, font 13 (used on the Profile Page hero).
  - Unfollowed: filled black (`AppColors.primary`), white label.
  - Followed: filled `AppColors.gray100`, `AppColors.gray900` label with a checkmark icon. Tapping unfollows.

### Call sites

#### Photo Detail — `_UserRow`

Replace the trailing static `Container` Follow pill with `FollowButton(user: photo.user, size: FollowButtonSize.compact)`. No other changes.

#### Profile Page — hero region

The Profile Page already has a header area. Add a `FollowButton` to the right of the user info, sized `regular`. Only render the button when the viewed profile is **not** the signed-in user (compare `user.username` to `authControllerProvider.session?.user.username`).

#### Mine — `mine_page.dart`

Out of scope for v1: the signed-in Mine page does not get a follow button (you cannot follow yourself) and does **not** surface Followers / Following counts. The existing `_SignedInMineView` stat strip stays as it is today. Adding the counts is a separate workstream — see "Auth scope" below for the data prerequisite.

### Auth scope

`AuthRemoteDataSource.getCurrentUser` builds an `AuthUser` by hand-rolling a JSON map; it does **not** go through `UserModel`. This means the auth user is missing the `followedByUser`, `followers_count`, and `following_count` fields today.

For v1, we accept this limitation:

- Follow buttons only render for **other users** (Photo Detail's `photo.user` and Profile Page's `user`), which always come from `UserModel` paths. So the missing fields on `AuthUser` are not blocking.
- Followers / Following counts on the Mine page are a follow-up.

If the user asks for "Following" count on Mine in v1, we add a new `parseUserFromMap` helper that `AuthRemoteDataSource` shares with `UserModel`, then surface the counts. The design stays the same.

## Data Design

No new entity. The follow status lives on the existing `User.followedByUser` field. The controller's `FollowState` carries a `User` so callers can rebuild with the latest data (and the updated `followers_count`).

## Interaction Design

### Follow flow

```
tap FollowButton
  ├── unauthenticated
  │     └── showAuthGateSheet(...) → return
  └── authenticated
        └── if in-flight: ignore
              else: optimistic flip → FollowInFlight
                       → POST/DELETE /users/:username/follow
                            ├── success: FollowIdle(response.user)
                            └── failure: FollowFailed(original.user) + SnackBar
```

The optimistic flip is performed by **constructing a new `User`** with `followedByUser: !user.followedByUser` rather than mutating the entity (`User` is immutable). All other fields of `User` carry over unchanged.

### Unfollow flow

Identical shape, just with `unfollow` and a `true` → `false` flip. The button label changes from "Following ✓" to "Follow" on the same tap.

### Auth gate

Reuses `showAuthGateSheet(context, ref, title: ..., body: ...)` from `lib/features/auth/presentation/widgets/auth_gate_sheet.dart`. The `title` and `body` are localized via new keys `followSignInTitle` / `followSignInBody` (en + zh).

## Error Handling

- **Network / server error**: revert to the previous `User` (in-memory only — no need to re-fetch the profile), show `followUpdateFailed` SnackBar.
- **401 Unauthorized**: this should not happen because the auth gate runs first, but if it does (token expired between auth check and request), revert and show `followUpdateFailed`. The interceptor's 401 path will also trigger a sign-out; the SnackBar message in that case is generic.
- **In-flight dedup**: if the user mashes the button, only the first request is dispatched; subsequent taps are no-ops until the request completes.
- **Stale state**: if the user is on Photo Detail and a follow was performed there, then the user navigates to that photographer's Profile Page, the Profile Page will read the profile (which may still be cached) — the follow state is **already on the cached `User.followedByUser`**, so no mismatch. If the user navigates to a different surface that fetches a fresh `User`, the new fetch carries the new `followedByUser` from the server.

## Files

### New

- `lib/features/follow/data/datasources/follow_remote_datasource.dart`
- `lib/features/follow/data/repositories/follow_repository_impl.dart`
- `lib/features/follow/domain/repositories/follow_repository.dart`
- `lib/features/follow/presentation/controllers/follow_controller.dart`
- `lib/features/follow/presentation/providers/follow_providers.dart`
- `lib/features/follow/presentation/widgets/follow_button.dart`
- `test/features/follow/data/datasources/follow_remote_datasource_test.dart`
- `test/features/follow/data/repositories/follow_repository_impl_test.dart`
- `test/features/follow/presentation/controllers/follow_controller_test.dart`
- `test/features/follow/presentation/widgets/follow_button_test.dart`

### Modify

- `lib/core/constants/api_constants.dart` — add `userFollow(String)`.
- `lib/features/photo_detail/presentation/pages/photo_detail_page.dart` — replace the static Follow `Container` in `_UserRow` with `FollowButton(photo.user, size: compact)`.
- `lib/features/profile/presentation/pages/profile_page.dart` — add a `FollowButton` to the hero region when viewing someone other than the signed-in user.
- `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb` — add `follow`, `following`, `followUpdateFailed`, `followSignInTitle`, `followSignInBody`.
- `test/features/photo_detail/presentation/pages/photo_detail_page_test.dart` — assert the FollowButton renders the correct label.
- `test/features/profile/presentation/pages/profile_page_test.dart` — assert the FollowButton renders (or is hidden) based on whether the viewed user is the signed-in user.

### No-Op

- `User`, `UserModel`, `PhotoModel` — already carry the field.
- `ProfileRemoteDataSource.getUserProfile` — already returns the field.
- All other features, routing, settings.

## Testing

### Unit

- `follow_remote_datasource_test.dart`
  - `POST /users/:username/follow` returns the `User` parsed from the response.
  - `DELETE` returns the `User` parsed from the response.
  - 4xx / 5xx throws `ServerException` with the right message.
- `follow_repository_impl_test.dart`
  - `DioException` is converted to `Failure.network`.
  - `ServerException` is converted to `Failure.server`.
  - Success path returns `Right(User)`.
- `follow_controller_test.dart`
  - Initial state is `FollowIdle(user)`.
  - `toggle` flips `user.followedByUser` immediately (optimistic).
  - `toggle` ignores a second tap while `FollowInFlight`.
  - Successful follow emits `FollowIdle(response.user)`.
  - Failure emits `FollowFailed(original.user)` (revert).
- `follow_button_test.dart`
  - Renders `follow` label when `user.followedByUser == false`.
  - Renders `following` label (with check) when `user.followedByUser == true`.
  - Tap while unauthenticated calls `showAuthGateSheet` and does not call the controller.
  - Tap while authenticated calls the controller's `toggle`.
  - Renders spinner when state is `FollowInFlight`.

### Widget

- `photo_detail_page_test.dart` — `_UserRow` shows a `FollowButton` and not the old `Container`.
- `profile_page_test.dart` — `FollowButton` is shown for a different user and hidden when the user is signed in.

## Rollout

- TDD-first per `CLAUDE.md`: each new file has its failing test written before the implementation.
- One commit per logical unit (data source, controller, button, call-site wiring).
- Final pass: `flutter analyze` + `flutter test` clean.
