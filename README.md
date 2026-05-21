<h1 align="center">Musea</h1>

<p align="center">
  A Flutter image discovery app powered by the <a href="https://unsplash.com/developers">Unsplash API</a>.
  <br>
  Browse curated photos, explore collections, search creators — all in a native mobile experience.
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

## Features

- **Discover** — Browse the latest photos from the Unsplash editorial feed, filtered by topic
- **Collections** — Explore curated photo collections with rich detail views
- **Search** — Find photos, collections, and users with real-time search
- **Photo Detail** — View photo metadata, EXIF data, color palette, and download options
- **User Profiles** — View photographer profiles with their photos, collections, and likes
- **Fullscreen Viewer** — Immersive full-screen photo viewer with pinch-to-zoom
- **Authentication** — OAuth-based Unsplash login for likes and downloads

## Architecture

The project follows a **feature-first** structure with clean architecture layers:

```
lib/
├── core/              # Shared concerns: network, theme, constants
│   ├── constants/
│   ├── errors/
│   ├── network/       # Dio client, auth interceptor, providers
│   ├── services/
│   ├── theme/         # Colors, text styles, app theme
│   └── utils/
├── router/            # GoRouter configuration & route extras
├── features/          # Feature modules
│   ├── auth/          # OAuth authentication
│   ├── discover/      # Photo discovery feed
│   ├── photo_detail/  # Photo detail & fullscreen viewer
│   ├── collections/   # Collection browsing & detail
│   ├── profile/       # User profiles (own & others)
│   └── search/        # Search photos, collections, users
└── shared/            # Reusable widgets
    └── widgets/
```

### State Management

State is managed with [Riverpod](https://riverpod.dev). Data flows are typically:

1. **Page** watches a provider via `ref.watch()`
2. **Provider** calls a repository method (returns `Future`)
3. **Repository** delegates to a remote or local data source
4. **Data source** communicates with the Unsplash API via Dio

Navigation uses **GoRouter** with a shell route for bottom navigation tabs and top-level routes for detail pages.

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter |
| Language | Dart |
| State Management | Riverpod |
| Routing | GoRouter |
| HTTP Client | Dio |
| Image Cache | cached_network_image |
| Local Storage | Hive |
| Code Generation | Freezed + JsonSerializable |

## Acknowledgments

- [Unsplash](https://unsplash.com) for their generous API and photography community
- [Flutter](https://flutter.dev) for the cross-platform framework
