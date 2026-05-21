# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Workflow

### Feature Development (not bug fixes)

1. **Must invoke `superpowers` skill first** — before starting any feature work, use `/superpowers` to select the appropriate workflow
2. **TDD is mandatory** — all feature code must follow Red-Green-Refactor: write a failing test first, watch it fail, then implement minimal code to pass
3. **Spec and plan may be skipped** only with explicit user confirmation; the test-first requirement cannot be waived
4. **Bug fixes** — fix with a regression test; write a test that reproduces the bug, watch it fail, then fix

No production code without a failing test first. Code written before its test must be deleted and rewritten following TDD.

## Build & Test Commands

```bash
# Analyze all Dart files for issues
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/features/discover/presentation/pages/discover_page_test.dart

# Run a single test by name
flutter test --name "search bar"

# Run all tests in a feature directory
flutter test test/features/discover/

# Run code generation (freezed, json_serializable, riverpod_generator)
dart run build_runner build --delete-conflicting-outputs

# Run build_runner in watch mode
dart run build_runner watch
```

## Project Architecture

Unsplash API image discovery app built with Flutter. Feature-first clean architecture:

```
lib/
├── core/              # Shared concerns (network/Dio, theme, errors, constants)
├── router/            # GoRouter config (ShellRoute for bottom nav + full-screen routes)
├── features/          # Feature modules, each with clean architecture layers
│   ├── auth/          # OAuth (PKCE) authentication
│   ├── discover/      # Photo feed with topic filtering (homepage)
│   ├── photo_detail/  # Photo metadata, EXIF, color palette, fullscreen viewer
│   ├── collections/   # Curated photo collections
│   ├── profile/       # User profiles (own & others)
│   └── search/        # Search photos, collections, users
└── shared/widgets/    # Reusable widgets (PhotoCard, PhotoGrid, PhotoFeed, etc.)
```

### Data Flow

1. **Page** watches a Riverpod `FutureProvider` via `ref.watch()`
2. **Provider** calls a repository method
3. **Repository** delegates to remote (Dio) or local (Hive) datasource
4. **Remote datasource** communicates with Unsplash API

Results are wrapped in `dartz` `Either<Failure, T>`, with the `Failure` freezed union covering network/server/cache/notFound/unauthorized/rateLimit/unknown errors.

### Navigation

GoRouter with a `ShellRoute` wrapping three bottom-nav tabs (`/discover`, `/collections`, `/profile`). Full-screen routes (`/search`, `/photo/:id`, `/photo/:id/viewer`, `/profile/:username`, `/collection/:id`, `/callback`) are top-level routes using `_rootNavigatorKey`.

Route extras (for passing data between pages) are defined in `lib/router/detail_route_extras.dart` with typed helper functions.

### State Management

Riverpod with `FutureProvider` for async data and simple `Provider`/`StateNotifierProvider` for auth state. Providers are feature-scoped in `presentation/providers/`. No global or shared state store.

### Key Dependencies

- **flutter_riverpod** — state management
- **go_router** — declarative routing
- **dio** — HTTP client with auth interceptor
- **cached_network_image** — image caching
- **flutter_staggered_grid_view** — masonry photo grid
- **freezed** — immutable data classes (entities, failures)
- **hive** — local storage for auth session
- **flutter_dotenv** — .env for API keys
- **dartz** — Either type for error handling
- **mocktail** — test mocking

### Testing Patterns

- Widget tests use `ProviderScope` overrides to inject mock data:
  ```dart
  ProviderScope(
    overrides: [
      authBootstrapSessionProvider.overrideWithValue(null),
      photosProvider(1).overrideWith((ref) => <Photo>[...]),
      topicsProvider.overrideWith((ref) => <Topic>[...]),
    ],
    child: const MaterialApp(home: DiscoverPage()),
  ),
  ```
- Mock repositories via `MockPhotoRepository extends Mock implements PhotoRepository`
- Use `tester.view.physicalSize` / `devicePixelRatio` setup + tearDown reset
- Auth-conditional pages gate behind `authBootstrapSessionProvider.overrideWithValue(null)` for unauthenticated state

### Environment

Requires a `.env` file with Unsplash API credentials (`ACCESS_KEY`, `SECRET_KEY`). Hive is initialized at startup in `main.dart`. The auth interceptor (`api_interceptor.dart`) injects the `Accept-Version: v1` header and Bearer or client-credentials token on every request.
