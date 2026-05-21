# Musea MVP Implementation Roadmap

> **Version**: v1.0
> **Date**: 2026-05-17
> **Based on**: [Functional Design](../musea-functional-design.md)
> **Tech Stack**: Flutter 3.x, Riverpod, GoRouter, Hive, Dio, CachedNetworkImage

---

## Overall Strategy

Three-phase iteration, each delivering a usable vertical feature slice.

| Phase | Delivered Value | Dependencies |
|-------|----------------|--------------|
| Phase 1 | Users browse photos → view details → download | No external dependencies |
| Phase 2 | Browse Unsplash official collections | Phase 1 reusable components (PhotoCard) |
| Phase 3 | Search images | Phase 1 reusable components (PhotoCard) |

Post-MVP (outside this spec): OAuth login + Profile tab (settings/stats/about) + collection write operations + like sync.

---

## Phase 1: Core Experience Loop

### Goal

Users browse photos from the Discover page, tap to enter the detail page for full information, and can download original images.

### Component Extraction

Extract reusable components from the existing `DiscoverPage`:

| Component | Location | Description |
|-----------|----------|-------------|
| `PhotoCard` | `shared/widgets/photo_card.dart` | Full-featured photo card: BlurHash placeholder, adaptive height, bottom gradient overlay, like/download buttons, avatar+username (tappable) |
| `PhotoFeed` | `shared/widgets/photo_feed.dart` | Single-column feed, embeds PhotoCard, supports infinite scroll callback |
| `TopicBar` | `shared/widgets/topic_bar.dart` | Horizontal scrolling topic chip list, includes "All" option |

### New Pages

#### Photo Detail Page (`photo_detail/presentation/pages/photo_detail_page.dart`)

- Route: `/photo/:id`
- Hero shared element transition via `PageRouteBuilder`
- Content:
  - Full-screen image display (`urls.regular` → `urls.full`)
  - Photographer info row + tappable navigation
  - Engagement data (likes, views, downloads)
  - EXIF info display
  - Shooting location
  - Color palette / tags (tap tag to navigate to Explore page pre-filled)
  - More from this photographer (horizontal scroll)
  - Similar image recommendations (based on tags via `GET /search/photos`)
- Bottom action bar: like (local state), download (actionable)
- Download flow: tap download → size selection sheet → `GET /photos/:id/download` → `dio.download()` to local album
- Tap image to toggle fullscreen mode

#### Photographer Profile Page (`profile/presentation/pages/profile_page.dart`)

- Route: `/profile/:username`
- Content:
  - Avatar + name + bio
  - Photo grid (reuses PhotoCard)
- Data source: `GET /users/:username` + `GET /users/:username/photos`

### Discover Page Modifications

- Use extracted `PhotoCard`, `PhotoFeed`, `TopicBar` instead of inline code
- Add BlurHash placeholders
- Tap photo → `context.go('/photo/${photo.id}')`
- Tap avatar → `context.go('/profile/${photo.user.username}')`
- Random dice → `randomPhotoProvider` → `context.go('/photo/${photo.id}')`
- Remove bookmark button (deferred to Phase 3 or later)

### Key Dependencies

```yaml
dependencies:
  blurhash: ^3.0.0            # BlurHash decoding → PhotoCard loading placeholder
  cached_network_image: ^3.3.0 # Image caching (already exists)
  image_gallery_saver: ^4.1.0  # Save images to album
  photo_view: ^0.15.0          # Image zoom/pan/fullscreen → detail page
  flutter_image_compress: ^2.1.0 # Pre-download compression (optional)
```

### Phase 1 Does Not Introduce

- No `share_plus` (introduce with social features later)
- No `flutter_facebook_auth` / `google_sign_in` (introduce with OAuth phase)

---

## Phase 2: Collections (Unsplash API Read-Only)

### Goal

Users browse Unsplash's official curated collection list, tap to enter a collection and view its photos (read-only).

### New Module

```
collections/
├── data/
│   ├── datasources/collection_remote_datasource.dart
│   ├── models/collection_model.dart
│   └── repositories/collection_repository_impl.dart
├── domain/
│   ├── entities/collection.dart
│   └── repositories/collection_repository.dart
└── presentation/
    ├── pages/
    │   ├── collections_page.dart
    │   └── collection_detail_page.dart
    └── providers/collections_provider.dart
```

### Data Sources

| API | Purpose |
|-----|---------|
| `GET /collections?page=N` | Collection list (cover, name, photo count) |
| `GET /collections/:id/photos?page=N` | Photos within a collection |

### Collections Page UI

- 2-column grid layout, cards with cover image + title + photo count
- Empty state: API returns empty → "No collections available"
- Tap to enter collection detail page
- Reuse `PhotoCard` for collection photos

### Routes

- `collections_page` replaces placeholder in `app_router.dart`
- New: `/collection/:id`

### Current Limitations

- "Bookmark" button on Discover and Detail pages is not implemented in this phase
- No local write operations

---

## Phase 3: Search

### Goal

Users can search for images by keyword and filter criteria on the Explore page.

### Explore Page Module

```
explore/
├── data/datasources/search_remote_datasource.dart
├── presentation/
│   ├── pages/explore_page.dart
│   └── widgets/
│       ├── search_input.dart
│       ├── color_filter_bar.dart
│       ├── orientation_filter.dart
│       └── search_history.dart
└── providers/search_provider.dart
```

### Search API

```
GET /search/photos?query={keyword}&color={color}&orientation={orientation}&order_by={relevant|latest}&page={page}
```

### Search Page Features

- Search input: 300ms debounce auto-trigger
- Color filter: 12 color chips (All/B&W/Red/Orange/Yellow/Green/Teal/Blue/Purple/Magenta/White/Black)
- Orientation filter: All / Landscape / Portrait
- Sort toggle: Relevance / Latest
- Result list: single-column feed, reuses `PhotoCard`
- Empty results: guidance suggestions + popular search tags
- First entry (no search yet): shows search history (local storage, last 10) + popular preset terms
- Results header: "Search results (N) Sort: Relevance ▼"

---

## Architecture Principles

### Existing Architecture Preserved

- State management: Riverpod `FutureProvider.family`
- Routing: GoRouter ShellRoute
- Networking: Dio
- Local storage: Hive
- Data layer: DataSource → Repository → Provider → UI

### Component Reuse

- `PhotoCard` is the core reusable component, extracted in Phase 1, used directly in Phase 2/3
- All list scenarios (Discover, Search, Collection Detail) use `PhotoFeed` consistently

### Error Handling

- API errors: Unified `Failure` type → Provider throws → UI layer `ErrorState` component displays
- Network errors: `ErrorState` + retry button
- Empty data: `EmptyState` component
- Loading: `LoadingIndicator` / skeleton screen

---

### MVP Tab Navigation

Remove Tab 4 "Profile" from bottom nav, keep 3 tabs:

| # | Tab | Route | Phase |
|---|-----|-------|-------|
| 1 | Discover | `/discover` | Phase 1 |
| 2 | Explore | `/explore` | Phase 3 |
| 3 | Collections | `/collections` | Phase 2 |

Tab 4 "Profile" is restored in the OAuth phase.

> Phase 1: Explore and Collections tabs keep existing placeholders, replaced with real pages in Phase 3 and Phase 2 respectively.

---

## Excluded from MVP

- OAuth user login/registration
- Profile tab (Tab 4: stats, dark mode toggle, clear cache, about)
- Collection CRUD (create, edit, delete collections)
- Save photos to custom collections
- Like state synced to server
- Cross-device data sync
- Image upload
- Social features (follow, comment)

---

## Testing Strategy

- `PhotoCard` widget test (loading, normal display, error state)
- `PhotoDetailPage` widget test (data display, download trigger)
- Unit test for each provider (mock API response)
- Route navigation test

---

## File Change Summary

### Phase 1

| Action | File |
|--------|------|
| New | `lib/shared/widgets/photo_card.dart` |
| New | `lib/shared/widgets/photo_feed.dart` |
| New | `lib/shared/widgets/topic_bar.dart` |
| New | `lib/features/photo_detail/presentation/pages/photo_detail_page.dart` |
| New | `lib/features/photo_detail/presentation/widgets/download_sheet.dart` |
| New | `lib/features/profile/data/datasources/profile_remote_datasource.dart` |
| New | `lib/features/profile/presentation/pages/profile_page.dart` |
| New | `lib/features/profile/presentation/providers/profile_provider.dart` |
| Modify | `lib/features/discover/presentation/pages/discover_page.dart` |
| Modify | `lib/router/app_router.dart` |
| Modify | `lib/shared/widgets/bottom_nav_bar.dart` |
| Modify | `pubspec.yaml` |

### Phase 2

| Action | File |
|--------|------|
| New | `lib/features/collections/data/datasources/collection_remote_datasource.dart` |
| New | `lib/features/collections/data/models/collection_model.dart` |
| New | `lib/features/collections/data/repositories/collection_repository_impl.dart` |
| New | `lib/features/collections/domain/entities/collection.dart` |
| New | `lib/features/collections/domain/repositories/collection_repository.dart` |
| New | `lib/features/collections/presentation/pages/collections_page.dart` |
| New | `lib/features/collections/presentation/pages/collection_detail_page.dart` |
| New | `lib/features/collections/presentation/providers/collections_provider.dart` |
| Modify | `lib/router/app_router.dart` |

### Phase 3

| Action | File |
|--------|------|
| New | `lib/features/explore/data/datasources/search_remote_datasource.dart` |
| New | `lib/features/explore/presentation/pages/explore_page.dart` |
| New | `lib/features/explore/presentation/widgets/search_input.dart` |
| New | `lib/features/explore/presentation/widgets/color_filter_bar.dart` |
| New | `lib/features/explore/presentation/widgets/orientation_filter.dart` |
| New | `lib/features/explore/presentation/widgets/search_history.dart` |
| New | `lib/features/explore/presentation/providers/search_provider.dart` |
| Modify | `lib/router/app_router.dart` |
| Modify | `lib/shared/widgets/bottom_nav_bar.dart` |
