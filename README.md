<h1 align="center">Musea</h1>

<p align="center">
  A Flutter image discovery app powered by the <a href="https://unsplash.com/developers">Unsplash API</a>.
  <br>
  Browse curated photos, explore collections, search creators, and save what inspires you — all in a native mobile experience.
</p>

<p align="center">
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter&logoColor=white" alt="Flutter 3.0+">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License">
  </a>
</p>

<br>

## Screenshots

> Add screenshots of Discover, Photo Detail, Search, and Mine here.

## Features

### Discovery
- **Discover feed** — Browse the latest photos from the Unsplash editorial feed, filtered by topic with per-topic scroll-state memory
- **Collections** — Explore curated photo collections with rich detail views
- **Search** — Find photos, collections, likes, and users in a unified search with debounced queries, sort options, color / orientation / content-safety filters

### Photos
- **Photo detail** — Collapsing hero toolbar, EXIF metadata, color palette, tags, and a "More from photographer" rail
- **Deferred hydration** — Tags and EXIF stream in after the page renders, with skeletons, placeholders, and a retry banner
- **Fullscreen viewer** — Immersive full-screen photo viewer with pinch-to-zoom (powered by `photo_view`)
- **Downloads** — Save photos to the device gallery in multiple resolutions, with progress, retry, local notifications, and Wi-Fi-only preference
- **Share** — Share via the system share sheet or copy a deep link, with graceful failure handling

### Personal workspace
- **Collections management** — Create, rename, delete collections, and add / remove photos from them
- **Likes** — Like / unlike photos (auth-gated) with optimistic updates
- **Profile & Mine** — View your own profile (photos, collections, likes) or browse any photographer's portfolio
- **Guest mode** — Browse Discover, Search, Collections, and public profiles without signing in

### System
- **Settings** — Language, download-over-Wi-Fi-only, cache size & clear, downloads manager, app version, feedback link, sign out
- **Authentication** — Unsplash OAuth (PKCE) login with deep-link callback handling
- **Localization** — English and Simplified Chinese via Flutter ARB files
- **Theming** — Material 3 with light & dark color schemes

## Architecture

The project follows a **feature-first** structure with clean architecture layers:

```
lib/
├── core/                 # Shared concerns: network, theme, constants, services
│   ├── constants/        # API & app constants
│   ├── errors/           # Exceptions & freezed Failure union
│   ├── network/          # Dio client, auth interceptor, providers
│   ├── services/         # Download notifier, cache summary, providers
│   ├── theme/            # Colors, text styles, app theme
│   └── utils/            # Color palette, helpers
├── l10n/                 # ARB localization files + generated delegates
│   ├── app_en.arb
│   ├── app_zh.arb
│   └── generated/
├── router/               # GoRouter configuration & typed route extras
├── features/             # Feature modules
│   ├── auth/             # OAuth (PKCE) authentication + callback
│   ├── discover/         # Photo feed with topic filtering (homepage)
│   ├── photo_detail/     # Photo detail, EXIF, color palette, fullscreen viewer
│   ├── collections/      # Collections, save / manage / edit / remove photos
│   ├── profile/          # User profiles (Mine tab + other photographers)
│   ├── search/           # Search photos, collections, users with filters
│   └── settings/         # App settings, language, downloads, cache, sign out
├── shared/               # Reusable widgets & services
│   ├── share/            # Share action sheet + share service
│   └── widgets/          # PhotoCard, PhotoGrid, PhotoFeed, immersive app bar, etc.
├── app.dart              # MaterialApp.router root
└── main.dart             # Bootstraps Hive, dotenv, notifications
```

### Data flow

1. **Page** watches a Riverpod `FutureProvider` (or scoped controller) via `ref.watch()`
2. **Provider** calls a repository method
3. **Repository** delegates to a remote (Dio) or local (Hive) datasource
4. **Remote datasource** talks to the Unsplash API; results are wrapped in `dartz` `Either<Failure, T>`

The `Failure` freezed union covers `network`, `server`, `cache`, `notFound`, `unauthorized`, `rateLimit`, and `unknown` errors.

### Navigation

GoRouter with a `ShellRoute` wrapping three bottom-nav tabs (`/discover`, `/collections`, `/profile`). Top-level routes (`/settings`, `/search`, `/photo/:id`, `/photo/:id/viewer`, `/profile/:username`, `/collection/:id`, `/collection/:id/remove`, `/callback`) use the root navigator for full-screen transitions.

Route extras are typed via `lib/router/detail_route_extras.dart` to keep navigation data flow explicit and testable.

### State management

- [Riverpod](https://riverpod.dev) with `FutureProvider` for async data
- `StateNotifier` / `AsyncNotifier` controllers for mutating flows (likes, downloads, settings, auth)
- No global store — providers are feature-scoped under `presentation/providers/`

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter |
| Language | Dart |
| State Management | Riverpod (+ riverpod_generator, riverpod_annotation) |
| Routing | GoRouter |
| HTTP Client | Dio (+ custom auth interceptor) |
| Image Cache | cached_network_image, flutter_blurhash |
| Local Storage | Hive |
| Code Generation | Freezed, JsonSerializable, build_runner |
| Image Zoom | photo_view |
| System Share | share_plus |
| Local Notifications | flutter_local_notifications |
| Gallery Save | gal, flutter_cache_manager |
| Deep Links | app_links |
| Connectivity | connectivity_plus |
| App Info | package_info_plus |
| Config | flutter_dotenv |
| Functional Types | dartz (`Either`) |
| Layout | flutter_staggered_grid_view, shimmer |
| Localization | flutter_localizations + ARB files |
| Testing | flutter_test, mocktail |

## Project Structure

```
.
├── android/              # Android platform shell
├── ios/                  # iOS platform shell
├── assets/               # Branding & icon assets
├── docs/                 # Specs, plans, design system
│   ├── musea/            # Master design + business PRD
│   ├── superpowers/      # Implementation specs & plans
│   └── ENV_SETUP.md      # Environment variable guide
├── lib/                  # Application source (see Architecture)
├── prototype/            # HTML prototypes for each surface
├── test/                 # Widget, unit, and provider tests mirroring `lib/`
├── .env.example          # Template for required env vars
├── pubspec.yaml          # Dependencies & asset declarations
└── README.md
```

## Getting Started

### Prerequisites

- Flutter 3.0+ / Dart 3.3+
- iOS 13+ / Android API 21+
- An [Unsplash developer](https://unsplash.com/developers) application (Client ID + Secret)

### Setup

1. **Clone & install dependencies**
   ```bash
   git clone https://github.com/your-org/musea.git
   cd musea
   flutter pub get
   ```

2. **Configure environment variables**
   ```bash
   cp .env.example .env
   ```
   Fill in your Unsplash credentials. See [docs/ENV_SETUP.md](docs/ENV_SETUP.md) for the full walkthrough.
   ```env
   UNSPLASH_CLIENT_ID=...
   UNSPLASH_SECRET_KEY=...
   UNSPLASH_REDIRECT_URI=musea://auth/callback
   ```

3. **Run code generation** (freezed, json_serializable, riverpod)
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Development

### Common commands

```bash
# Static analysis
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/features/discover/presentation/pages/discover_page_test.dart

# Run a single test by name
flutter test --name "search bar"

# Run all tests in a feature
flutter test test/features/collections/

# Run code generation in watch mode
dart run build_runner watch

# Localization (after editing .arb files)
flutter gen-l10n
```

### Testing patterns

- Widget tests inject mocked state via `ProviderScope.overrides`
- Repositories are mocked with `MockPhotoRepository extends Mock implements PhotoRepository`
- Auth-conditional pages gate behind `authBootstrapSessionProvider.overrideWithValue(null)` for the unauthenticated flow
- Use `tester.view.physicalSize` + `devicePixelRatio` for layout-sensitive tests, with tear-down reset

### Workflow

- Feature work is TDD-first: write a failing test, watch it fail, then implement the minimum to pass
- One commit per feature or bugfix
- Run `flutter analyze` and `flutter test` before opening a PR

## Roadmap

See [docs/superpowers/plans/](docs/superpowers/plans/) for active plans and [docs/superpowers/specs/](docs/superpowers/specs/) for design specs. The product roadmap lives in [docs/musea-business-prd.md](docs/musea-business-prd.md).

## License

MIT — see [LICENSE](LICENSE).

## Acknowledgments

- [Unsplash](https://unsplash.com) for their generous API and photography community
- [Flutter](https://flutter.dev) for the cross-platform framework
