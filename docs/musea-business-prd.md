# Musea Business PRD

> **Version**: v1.0
> **Date**: 2026-05-17
> **Status**: Draft

---

## Problem Statement

Unsplash hosts one of the largest free high-quality image libraries, but its official client and web experience are relatively basic when it comes to image **discovery**:

- Browsing is primarily list-based, lacking an immersive visual exploration flow
- Image discovery paths are narrow (search + editor's picks), missing color-based and content-based browsing
- Mobile experience is incomplete, lacking a native cross-platform application
- Metadata display is understated — camera specs, location, and color information aren't well presented

Musea aims to build a **discovery-first** image browsing app, allowing casual users to explore vast collections of high-quality photography in a more intuitive and elegant way.

---

## Project Nature

> **This is a personal learning project** — no commercial metrics or user data targets. The goal is to practice full-stack Flutter development skills by building a complete application on top of a real API.

However, this doesn't mean product quality can be compromised. As a portfolio project, Musea should still strive for excellent user experience and code quality.

---

## Target Users

| User Type | Characteristics | Needs |
|-----------|----------------|-------|
| **Casual content consumer** | Enjoys browsing beautiful images, finding wallpapers, daily visual inspiration | Effortless browsing of high-quality images, discovering interesting content |
| **Photography enthusiast** | Follows photographic work, cares about camera specs and technique | View EXIF info, follow photographers, learn photography |
| **Designer / creative** | Needs visual references and aesthetic inspiration | Filter by color/theme, build reference collections |
| **Individual developer** | Learning Flutter and REST API integration | Focus on project architecture, API integration, best practices |

MVP primarily serves **casual content consumers** and **photography enthusiasts**.

---

## Solution Overview

**Musea** is a cross-platform image discovery app built with Flutter, leveraging the Unsplash API to deliver:

- **Immersive browsing** — masonry or grid layout for browsing latest/curated photos with more visual impact
- **Smart search** — multi-dimension search and filtering by keyword, color, orientation
- **Rich detail pages** — full photo metadata including EXIF, location, color info, and tags
- **Collection management** — users create themed collections to organize their favorite images
- **Photographer exploration** — view photographer profiles and their portfolios

Through carefully designed UI/UX, transforming straightforward API data into a smooth, beautiful visual browsing experience.

---

## Unsplash API Data Interface Analysis

### Available Endpoints Overview

| Category | Endpoint | Purpose | MVP Priority |
|----------|---------|---------|-------------|
| **Photos** | `GET /photos` | Get editor's pick photo list | ★★★ |
| **Photos** | `GET /photos/:id` | Get full photo details (EXIF, location, tags) | ★★★ |
| **Photos** | `GET /photos/random` | Get random photos (can be scoped by collection/topic/orientation) | ★★★ |
| **Photos** | `GET /photos/:id/statistics` | Get photo view/download statistics | ★★☆ |
| **Photos** | `GET /photos/:id/download` | Track download behavior (API compliance) | ★★★ |
| **Search** | `GET /search/photos` | Keyword search with color/orientation/sort filters | ★★★ |
| **Search** | `GET /search/collections` | Search collections | ★★☆ |
| **Topics** | `GET /topics` | Get Unsplash official curated topics | ★★★ |
| **Topics** | `GET /topics/:id/photos` | Get photos under a topic | ★★★ |
| **Users** | `GET /users/:username` | Get photographer public profile | ★★☆ |
| **Users** | `GET /users/:username/photos` | Get photographer's photo list | ★★☆ |
| **Collections** | `GET /collections` | Get collection list | ★☆☆ |
| **Collections** | `GET /collections/:id/photos` | Get photos in a collection | ★☆☆ |
| **Collections** | `POST /collections/:id/add` | Add photo to collection | ★☆☆ |
| **Collections** | `DELETE /collections/:id/remove` | Remove photo from collection | ★☆☆ |

### Key Data Model Fields

**Photo object**:
- `id`, `created_at`, `width`, `height`, `color` (primary HEX), `blur_hash` (placeholder)
- `description`, `alt_description`, `tags` (tag array)
- `urls`: `raw`/`full`/`regular`/`small`/`thumb` (five sizes)
- `exif`: `make`/`model`/`exposure_time`/`aperture`/`focal_length`/`iso`
- `location`: `city`/`country`/`position.lat`/`position.lng`
- `user`: Photographer profile (includes `name`/`username`/`profile_image`/`portfolio_url`/`bio`)
- `links`: `download`/`download_location` (download tracking)
- `likes` count

**Image URL processing** (Imgix):
- Five predefined sizes (raw/full/regular/small/thumb)
- Supports real-time parameters: `w`(width), `h`(height), `q`(quality), `fm`(format), `fit`, `dpr`(pixel ratio)
- **Must retain `ixid` parameter** to comply with API usage guidelines

### Authentication Strategy

| Phase | Auth Method | Available Features | Rate Limit |
|-------|------------|-------------------|------------|
| MVP | `Client-ID` public auth | Browse/search/detail/topics (read-only) | 50 req/hr (demo) → production upgrade available |
| Future | `OAuth 2.0` user auth | Collection management/likes/user data (read/write) | 5000 req/hr (production) |

### API Compliance Requirements

1. **Download tracking**: Must call `/photos/:id/download` endpoint every time a user downloads an image
2. **Hotlinking**: Directly use Unsplash CDN image URLs (`images.unsplash.com`), which don't count toward API limits
3. **Attribution**: Must display photographer credit when showing images
4. **ixid retention**: The `ixid` parameter in image URLs must not be removed

---

## User Stories

### Phase 1 — Browse & Discover

1. As a casual user, I want to see curated/latest high-quality images when I open the app, so I can quickly browse and discover great photos
2. As a casual user, I want to view images in a masonry/grid layout for a smoother visual experience than the official client
3. As a casual user, I want to browse images by topic (e.g., "Nature", "Architecture", "People") to discover specific categories
4. As a casual user, I want to pull-to-refresh to get new recommended content
5. As a casual user, I want to see random photo recommendations for serendipitous discovery
6. As a casual user, I want BlurHash placeholders for images in the browsing list to reduce loading anxiety

### Phase 2 — Search

7. As a casual user, I want to search photos by keyword to find specific content
8. As a casual user, I want to filter search results by color to find images with a cohesive palette
9. As a casual user, I want to filter search results by orientation (landscape/portrait/square) to fit different use cases
10. As a casual user, I want to sort search results by relevance or latest
11. As a casual user, I want good loading and empty state handling for search results

### Phase 3 — Photo Detail

12. As a casual user, I want to tap a photo to enter a detail page and view it large
13. As a photography enthusiast, I want to view EXIF info (camera model, aperture, shutter speed, ISO, focal length)
14. As a photography enthusiast, I want to view the photo's location (city/country/coordinates)
15. As a casual user, I want to see the primary color and palette info
16. As a casual user, I want to view photo tags and tap them to search related images
17. As a casual user, I want to view photographer info (name, bio, photo count) and navigate to their profile
18. As a casual user, I want to download images in different sizes
19. As a casual user, I want to see related/similar photo recommendations on the detail page
20. As a casual user, I want to see photo statistics (downloads, views)

### Phase 4 — Collections

21. As a casual user, I want to create my own collections (e.g., "Travel Inspiration", "Wallpapers")
22. As a casual user, I want to add favorite photos to collections
23. As a casual user, I want to browse photos in my collections
24. As a casual user, I want to remove photos from collections
25. As a casual user, I want to edit collection names and descriptions
26. As a casual user, I want to browse Unsplash's public curated collections

### Phase 5 — Photographer Exploration

27. As a casual user, I want to view a photographer's profile page (bio, photo count, social links)
28. As a photography enthusiast, I want to browse a photographer's full portfolio
29. As a photography enthusiast, I want to view photographer statistics

### Phase 6 — Error & Edge Case Handling

30. As a user, when the network is unavailable, I want a friendly offline state prompt
31. As a user, when the API rate limit is reached, I want a clear notification
32. As a user, when search returns no results, I want a friendly empty state with guidance
33. As a user, when an image fails to load, I want graceful degradation instead of a white screen
34. As a user, I want pull-to-refresh to provide clear feedback even on failure

---

## Feature Scope Definition

### MVP Included Features

| Module | Feature | Priority |
|--------|--------|---------|
| Browse | Editor's pick photo list (infinite scroll) | P0 |
| Browse | Topic browsing (by official topic categories) | P0 |
| Browse | Random photo recommendation | P1 |
| Search | Keyword search | P0 |
| Search | Color filter | P0 |
| Search | Orientation filter | P0 |
| Search | Sort toggle (relevance/latest) | P1 |
| Detail | Large image view (fullscreen/zoom) | P0 |
| Detail | EXIF info display | P0 |
| Detail | Location display (map/text) | P1 |
| Detail | Color/tag info | P0 |
| Detail | Photographer info | P0 |
| Detail | Related image recommendations | P1 |
| Detail | Image download (multi-size) | P0 |
| Detail | Statistics display | P2 |
| Collections | Create collection | P1 |
| Collections | Add/remove images | P0 |
| Collections | Browse collection content | P0 |
| Photographer | Photographer profile | P1 |
| Photographer | Photographer photo list | P1 |
| System | Offline/empty state/error handling | P0 |
| System | API rate limit handling | P0 |

### MVP Excludes (Future Consideration)

- OAuth user authentication (collection management via local storage instead)
- Like/comment social features
- Image upload functionality
- User follow system
- Push notifications
- Multi-language support

---

## Success Metrics

> As a personal learning project, success is not measured by commercial metrics.

### Learning Goals

- ☐ Master Flutter cross-platform app development lifecycle
- ☐ Practice REST API integration and data layer encapsulation
- ☐ Implement elegant image loading, caching, and placeholder strategies
- ☐ Practice good Flutter project architecture (Clean Architecture / Riverpod, etc.)
- ☐ Deliver a presentable portfolio application

### Quality Metrics

- ☐ Smooth app startup, no white screen
- ☐ Smooth list scrolling (60fps)
- ☐ Graceful image placeholders and transition animations
- ☐ Friendly user feedback for all API errors
- ☐ No app crashes

---

## Technical Dependencies & Constraints

### Known Dependencies

| Dependency | Description | Notes |
|-----------|-------------|-------|
| Unsplash API | All image data source | Requires developer account to get Client-ID |
| Flutter SDK | Cross-platform development framework | Version TBD |
| Unsplash API rate limit | Demo: 50 req/h, Production: 5000 req/h | MVP needs Production level application |
| Imgix CDN | Image loading and rendering | URL parameters must retain ixid |

### Constraints

- Comply with Unsplash API Guidelines (download tracking, attribution, ixid retention)
- Mobile-first, no desktop adaptation planned
- All image data depends on Unsplash, cannot work offline

---

## Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| API rate limit insufficient | High | Limited user experience | Apply for Production level (5000/h); implement local caching to reduce requests |
| Single data source dependency | Medium | App unusable when service is down | Implement graceful error handling and degraded display |
| Image loading performance | Medium | List lag, high data usage | Use BlurHash placeholders, on-demand size loading, caching strategy |
| Flutter learning curve | Medium | Slower development | Plan time well, build skeleton first then refine |
| API changes | Low | Some features break | Monitor Unsplash Changelog, reserve adaptation layer |

---

## Roadmap

```
Phase 1: Project skeleton
  - Flutter project init, architecture setup
  - API service layer encapsulation
  - Discover home page (editor's picks + topics)

Phase 2: Search & navigation
  - Search functionality (keyword + filters)
  - Navigation framework setup

Phase 3: Photo detail page
  - Full detail page (metadata, tags, photographer, related images)
  - Image download functionality

Phase 4: Collections
  - Collection management (create/add/browse/remove)
  - Local storage integration

Phase 5: Photographer exploration
  - Photographer profile page
  - Photo list

Phase 6: Polish & release
  - Error handling refinement
  - Loading animations
  - Performance optimization
  - App release preparation
```

---

## Out of Scope

The following features are explicitly not planned for the current roadmap:

- **User registration/login** — Collection data uses local storage (SharedPreferences / SQLite)
- **Social features** — No likes, comments, or follows
- **Image upload** — Musea is a discovery tool, not a photography community
- **Web/Desktop** — Focus on mobile experience
- **Multi-language** — MVP supports single language
- **Accessibility** — Non-core requirement
- **Offline image caching** — Cache metadata only, not original images
- **Push notifications** — No scenarios requiring push

---

## Open Questions

1. **Design style**: Visual direction not yet determined — minimal white space, immersive dark, or magazine card style? Design exploration needed before development
2. **Flutter state management**: BLoC vs Riverpod vs Provider? Must decide before development
3. **Local storage**: SharedPreferences vs Hive vs SQLite (drift) for collection local storage?
4. **Image caching strategy**: Use `cached_network_image` or build custom cache layer?
5. **Map display**: Show location with map or just text? Introduce `google_maps_flutter` or Mapbox?

---

## References

- [Unsplash API Documentation](https://unsplash.com/documentation)
- [Unsplash API Guidelines - Download Tracking](https://help.unsplash.com/en/articles/2511258-guideline-triggering-a-download)
- [Unsplash API Guidelines - Hotlinking](https://help.unsplash.com/en/articles/2511271-guideline-hotlinking-images)
- [BlurHash Specification](https://blurha.sh/)
- [Imgix Image Processing Docs](https://docs.imgix.com/)
