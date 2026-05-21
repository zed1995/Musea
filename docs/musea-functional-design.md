# Musea Functional Module Design

> **Version**: v1.0
> **Date**: 2026-05-17
> **Based on**: Unsplash API data capabilities

---

## 1. Overall Navigation Structure

**Bottom Tab Navigation** with 4 main tabs:

| # | Tab Name | Icon | Core Purpose |
|---|---------|------|-------------|
| 1 | **Discover** | 🏠 | Editor's picks + topic browsing + random discovery |
| 2 | **Explore** | 🔍 | Multi-dimension search + filter |
| 3 | **Collections** | 📁 | Local collection management |
| 4 | **Profile** | 👤 | Settings + stats + about |

---

## 2. Tab 1: Discover

### 2.1 Page Layout

```
┌──────────────────────────────────────┐
│  🔍 Search photos, photographers...    │  ← Search bar + random button
├──────────────────────────────────────┤
│  [All] [Nature] [Architecture] [People] [Film] ⋯  │  ← Topic bar (horizontal scroll)
├──────────────────────────────────────┤
│                                      │
│  ┌──────────────────────────────┐   │
│  │                              │   │
│  │         P H O T O           │   │  ← Full-width photo
│  │                              │   │     Adaptive height
│  ├────────────────────────────────┤  │
│  │                                │  │  ← Overlay bar (translucent gradient)
│  │  ◎ username  [♡ 1.2k] [💾 892] [⬇ 456]│  │      Left: avatar + username
│  └────────────────────────────────┘  │      Right: three action buttons + counts
│                                      │
│  ┌──────────────────────────────┐   │
│  │                              │   │  ← Next photo
│  │         P H O T O           │   │
│  ├────────────────────────────────┤  │
│  │  ◎ username  [♡ 892] [💾 2.1k] [⬇ 128]│  │
│  └────────────────────────────────┘  │
│                                      │
│         [Load more...]               │  ← Infinite scroll + skeleton
└──────────────────────────────────────┘
```

### 2.2 Top Area

**Search bar** (non-editable, tap navigates to Explore tab):
- Left: magnifying glass icon + "Search photos, photographers..."
- Right: random dice icon → triggers `/photos/random`, navigates to random photo detail

### 2.3 Topic Bar

Horizontal scrolling chip list, sourced from `GET /topics`.

| Element | Data Field | Display |
|---------|-----------|---------|
| All | None (fixed item) | Default selected, rounded chip with background color |
| Each topic | `topic.title` + `topic.cover_photo.urls.thumb` | Rounded pill, filled when selected, outline when unselected |
| Selection | Switches to `GET /topics/:slug/photos` | Replaces photo feed data source |

**Topic chip style**:
```
 ┌──────────────┐  ┌──────────┐  ┌────────┐  ┌──────────┐
 │  ✦ All       │  │  🌲 Nature│  │ 🏛 Arch │  │ 👤 People│  ⋯
 └──────────────┘  └──────────┘  └────────┘  └──────────┘
```

### 2.4 Photo Card Design

The core UI component reused across discover feed, search, topics, and collections. **Single-column full-width layout** focused on the image itself, with streamlined information and direct actions.

```
┌────────────────────────────────────┐
│                                    │
│            P H O T O              │
│                                    │  ← Full-width adaptive image
│                                    │     src: photo.urls.regular
│                                    │     placeholder: blur_hash
├────────────────────────────────────┤
│                                    │  ← Bottom overlay bar
│  ◎ username  [♡ 1.2k] [💾 892] [⬇ 456]│     Gradient background (transparent → semi-transparent black)
│                                    │     Left: avatar(round) + username
└────────────────────────────────────┘     Right: three action buttons + counts
```

**Card layout**: Overlay at the bottom of the image, left side shows user info, right side shows action buttons.

```
┌──────────────────────────────────────────┐
│                                          │
│               P H O T O                 │  ← Full-width adaptive image
│                                          │
├──────────────────────────────────────────┤
│  ░░ Gradient overlay (transparent → black@40%)  │
│  ◎ username      [♡ 1.2k] [💾 892] [⬇ 456]  │
└──────────────────────────────────────────┘
```

**Bottom overlay bar**:

| Area | Element | Data Source | Notes |
|------|---------|-------------|-------|
| Left | Avatar (round) | `photo.user.profile_image.medium` (64x64) | Tappable → photographer profile |
| Left | Username | `photo.user.name` | White bold, tappable |
| Right | ♡ Like | `photo.likes` (show `k` format > 1000) | Toggle like state, local state for MVP |
| Right | 💾 Bookmark | Local bookmark count | Shows collection picker sheet |
| Right | ⬇ Download | `photo.downloads` or local count | Shows size selection dialog |

**Interactions**:
- Tap image → photo detail page (Hero shared element transition)
- Tap avatar/username → photographer profile page
- Tap action buttons → trigger corresponding actions

**Image size adaptation**:
```
Image width = screen width (full-width)
Image height = screen width × (photo.height / photo.width)

For tall images (ratio > 3:1), cap max height at 60% of screen height
Show hint "View full image"
```

### 2.5 Data Loading Strategy

| Action | Data Source | Trigger |
|--------|-------------|---------|
| Initial load | `GET /photos?page=1&per_page=20` | Enter Discover page |
| Load more | `GET /photos?page=N&per_page=20` | 2 screens before scroll bottom |
| Topic switch | `GET /topics/:slug/photos?page=1` | Tap topic chip |
| Refresh | Re-request current data source page=1 | Pull to refresh |
| Random | `GET /photos/random?count=1` | Tap dice button |

**Loading states**:
- First load: skeleton screen (BlurHash placeholder grid)
- Load more: bottom circular progress indicator
- Refresh: top refresh indicator
- Error: SnackBar + retry button

---

## 3. Tab 2: Explore

### 3.1 Page Layout

```
┌──────────────────────────────────────┐
│  ┌────────────────────────────┐ [×] │  ← Search input (real-time)
│  │ 🔍 Search photos...        │     │     With clear button
│  └────────────────────────────┘     │
├──────────────────────────────────────┤
│  Color: [■All] [■B&W] [■Red] [■Blue]⋯ │  ← Color filter bar (horizontal scroll)
│  Orientation: [▼ All]  [▬ Landscape]  [▬ Portrait]   │  ← Orientation filter (3-select-1)
│  Sort: [● Relevance]  [○ Latest]            │  ← Sort toggle
├──────────────────────────────────────┤
│  Search results (124)                │  ← Result count
├──────────────────────────────────────┤
│                                      │
│  ┌──────────────────────────────┐   │
│  │         P H O T O           │   │  ← Single-column feed (reuses Discover card)
│  ├────────────────────────────────┤  │
│  │  ◎ username  [♡ 892] [💾 2.1k] [⬇ 456] │  │
│  └────────────────────────────────┘  │
│                                      │
│         [Load more...]               │  ← Infinite scroll
└──────────────────────────────────────┘
```

**Empty search results**:
```
┌──────────────────────────────────────┐
│                                      │
│              🔍                      │
│      No matching photos found        │
│                                      │
│  Try these suggestions:              │
│  • Use broader keywords              │
│  • Reduce filter criteria            │
│  • Check spelling                    │
│                                      │
│  [Popular: Nature] [Wallpaper] [Minimal]  │
│                                      │
└──────────────────────────────────────┘
```

### 3.2 Search Input

| Feature | Implementation |
|---------|---------------|
| Input trigger | 300ms debounce, auto-initiate search |
| Clear | Show × button when input has content |
| Empty input | Search history (local storage) + popular suggestions |
| Submit | Keyboard search button triggers search |

**Data source**: `GET /search/photos?query={keyword}`

### 3.3 Filter Bar

**Color filter** (horizontal scrolling chips):

```
[■ All] [⬤ B&W] [■ Red] [■ Orange] [■ Yellow] [■ Green] [■ Teal] [■ Blue] [■ Purple] [■ Magenta] [■ White] [■ Black]
```

| Color | API Parameter | Swatch |
|-------|--------------|--------|
| All | (omit param) | Rainbow gradient |
| B&W | `black_and_white` | B&W gradient |
| Red | `red` | 🔴 |
| Orange | `orange` | 🟠 |
| Yellow | `yellow` | 🟡 |
| Green | `green` | 🟢 |
| Teal | `teal` | Teal |
| Blue | `blue` | 🔵 |
| Purple | `purple` | 🟣 |
| Magenta | `magenta` | Magenta |
| White | `white` | ⚪ |
| Black | `black` | ⚫ |

Tapping a color chip toggles selection and auto-triggers a search (with animation).

**Orientation filter** (3 pill buttons):

```
[▬ All]  [▯ Landscape]  [▮ Portrait]
```

| Option | API Parameter | Notes |
|--------|--------------|-------|
| All | (omit param) | Show all orientations |
| Landscape | `orientation=landscape` | Width > Height |
| Portrait | `orientation=portrait` | Height > Width |

Selected: filled background + white text; Unselected: outline + gray text.

**Sort toggle**:

```
[● Relevance]  [○ Latest]
```

### 3.4 Search Results

| Element | Data Source | Notes |
|---------|-------------|-------|
| Total count | `search_photos.total` | Display "Search results (N)" |
| Result list | `search_photos.results[]` | Single-column feed, reuses discover card (`photo.urls.regular` full-width) |
| Pagination | `page` + `per_page` params | Infinite scroll |
| Empty results | — | Show guidance suggestions + popular search tags |
| First entry (no search yet) | — | Show search history and popular tags |
| View toggle | Optional | User can toggle between "single column" and "grid" modes |

**Search results header**:
```
Search results (124)         Sort: Relevance ▼
```

### 3.5 Search History & Recommendations

| Area | Content | Data Source |
|------|---------|-------------|
| Search history | Last 10 search terms | Local storage |
| Popular searches | Preset hot keywords (e.g., Nature, Wallpaper, Minimal) | Local preset + future expandable |
| Popular tags | Top 10 topic names from `GET /topics` | Unsplash API |

---

## 4. Tab 3: Collections

### 4.1 Page Layout

```
┌────────────────────────────────────┐
│  My Collections                [+] │  ← Title + create button
├────────────────────────────────────┤
│                                    │
│  ┌──────────┐  ┌──────────┐      │
│  │          │  │          │      │
│  │  Cover   │  │  Cover   │      │  ← Collection cards (2-column grid)
│  │  Photo   │  │  Photo   │      │
│  ├──────────┤  ├──────────┤      │
│  │ Travel   │  │ Wallpaper│      │
│  │ 24 photos│  │ 8 photos │      │
│  └──────────┘  └──────────┘      │
│                                    │
│  ┌──────────┐                      │
│  │          │                      │
│  │  Cover   │                      │
│  │  Photo   │                      │
│  ├──────────┤                      │
│  │ Design   │                      │
│  │ 15 photos│                      │
│  └──────────┘                      │
│                                    │
│         [No more data]             │
└────────────────────────────────────┘
```

### 4.2 Collection Card

```
┌────────────────────┐
│                     │
│    Cover Photo     │  ← Collection cover (collection.cover_photo.urls.small)
│     (2:1 ratio)     │     If no cover, use first image
│                     │
├────────────────────┤
│                     │
│  📁 Travel Ideas    │  ← Collection title, bold
│  24 photos         │  ← Photo count
│                     │
└────────────────────┘
```

| Card Element | Notes |
|-------------|-------|
| Cover image | Collection's first image or manually set cover |
| Title | User-created name, editable |
| Photo count | "N photos" |
| Interaction | Tap → collection detail; Long press → edit/delete menu |

**Empty state** (first use):
```
┌─────────────────────────┐
│                         │
│       📂                │
│  No collections yet     │
│  Tap + in top right     │
│  to create your first   │
│  collection             │
│                         │
└─────────────────────────┘
```

### 4.3 Create/Edit Collection Dialog

```
┌─────────────────────────┐
│  Create Collection       │
│                         │
│  Name                    │
│  ┌─────────────────┐   │
│  │ e.g., Travel Ideas│   │
│  └─────────────────┘   │
│                         │
│  Description (optional)  │
│  ┌─────────────────┐   │
│  │ My favorite travel   │   │
│  │ photos           │   │
│  └─────────────────┘   │
│                         │
│  [Cancel]      [Create] │
└─────────────────────────┘
```

### 4.4 Collection Detail Page

```
┌──────────────────────────────────────┐
│  ← Collections                   ⋮  │  ← Top nav + more menu
├──────────────────────────────────────┤
│  ┌──────────────────────────────┐   │
│  │         Banner Cover         │   │  ← Collection cover (16:9)
│  └──────────────────────────────┘   │
│                                      │
│  📁 Travel Ideas                     │  ← Title
│  My favorite travel photography      │  ← Description
│  24 photos · Created May 2026       │  ← Metadata
│                                      │
│  [Edit]  [Clear]                     │  ← Action buttons
│                                      │
│  ┌──────────────────────────────┐   │
│  │         P H O T O           │   │  ← Single-column feed (reuses Photo Card)
│  ├────────────────────────────────┤  │
│  │  ◎ username  [♡ 892] [💾 Saved] [⬇ 2.1k]│  │
│  └────────────────────────────────┘  │
│                                      │
│         [Load more...]               │  ← Infinite scroll
└──────────────────────────────────────┘
```

**Collection empty state**:
```
┌──────────────────────────────────────┐
│                                      │
│              📂                      │
│       This collection is empty       │
│                                      │
│  Browse the discover page and tap    │
│  the bookmark button on photos       │
│  to add them to this collection      │
│                                      │
│  [Go to Discover]                    │
└──────────────────────────────────────┘
```

### 4.5 Add Photo to Collection Flow

Triggered from photo detail page or quick menu:

```
                 Long press / tap bookmark button
                         │
                         ▼
               ┌───────────────────┐
               │  Save to Collection │
               │                   │
               │  ○ Travel Ideas (24)│  ← Collection list, single-select
               │  ○ Wallpapers (8)   │
               │  ○ Design Ref (15)  │
               │                   │
               │  [+ New Collection] │
               │                   │
               │  [Cancel]  [Save]  │
               └───────────────────┘
```

### 4.6 Data Storage

> Since there is no OAuth user system during MVP, collection data uses **local storage**.

| Data Type | Storage | Notes |
|-----------|---------|-------|
| Collection list | `Hive` or `drift` | Contains id, name, description, creation time |
| Collection-photo mapping | Local DB | Photo ID + collection ID + added time |
| Photo cache data | `Hive` | Cache `Photo` essential fields (id, urls, user.name, etc.) |
| Search history | `SharedPreferences` | Last 10 search terms |

> **Note**: Local storage means collection data is not synced across devices. Can be migrated to server-side after OAuth integration.

---

## 5. Photo Detail Page

### 5.1 Page Layout

```
┌────────────────────────────────────┐
│  ← Back  [Download]  [Bookmark]    [⋮]  │  ← Top navigation bar
├────────────────────────────────────┤
│                                    │
│        ┌──────────────────┐       │
│        │                  │       │
│        │   Fullscreen     │       │  ← Main image area (fit: contain)
│        │   Image Display  │       │     Source: photo.urls.regular
│        │   Pinch to Zoom  │       │     Tap to toggle fullscreen mode
│        └──────────────────┘       │
│                                    │
├────────────────────────────────────┤
│                                    │
│  ◎ username  @username            │  ← Photographer info row
│  "Photographer bio"                │     Tappable → profile
│                                    │
├────────────────────────────────────┤
│  ♡ 1,284   ·  👁 52.3k  ·  ⬇ 12k  │  ← Engagement stats
│                                    │
├────────────────────────────────────┤
│  Photo Info                        │  ← Metadata group
│  ┌──────────────────────────────┐ │
│  │ 📷 Camera  Sony A7 III       │ │
│  │ 🔭 Lens    FE 24-70mm F2.8  │ │
│  │ ⏱ Shutter 1/250s            │ │
│  │ 🔆 Aperture f/2.8           │ │
│  │ 🔢 ISO     400               │ │
│  │ 📏 Focal    35mm             │ │
│  │ 📐 Size     6000×4000       │ │
│  └──────────────────────────────┘ │
│                                    │
│  Location                          │
│  ┌──────────────────────────────┐ │
│  │ 📍 Kyoto, Japan              │ │
│  │ [🗺 Map thumbnail (optional)] │ │  ← Expandable map
│  └──────────────────────────────┘ │
│                                    │
│  Color Palette                     │
│  ┌──────────────────────────────┐ │
│  │ Primary: ■ #5B7B9A          │ │
│  │ Palette: ■■■■■■■■            │ │  ← Extracted from image or tags
│  └──────────────────────────────┘ │
│                                    │
│  Tags                              │
│  ┌──────────────────────────────┐ │
│  │ [Kyoto] [Temple] [Autumn]    │ │  ← Horizontal scroll tags
│  │ [Japan] [Architecture]       │ │     Tap → explore page with pre-filled search
│  └──────────────────────────────┘ │
│                                    │
├────────────────────────────────────┤
│  More from this photographer       │  ← Photographer recommendations
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐     │
│  │ img│ │img │ │img │ │img │ ⋯    │  ← Horizontal scroll
│  └────┘ └────┘ └────┘ └────┘     │
│                                    │
├────────────────────────────────────┤
│  Similar Photos                    │  ← Related recommendations
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐     │
│  │ img│ │img │ │img │ │img │ ⋯    │  ← Horizontal scroll
│  └────┘ └────┘ └────┘ └────┘     │
│                                    │
└────────────────────────────────────┘
```

### 5.2 Module Data Mapping

| Module | Data Field | API Source |
|--------|-----------|------------|
| Main image | `photo.urls.regular` (default) → `full` (fullscreen) | `GET /photos/:id` |
| Photographer | `photo.user.name` + `photo.user.username` + `photo.user.profile_image.medium` + `photo.user.bio` | `GET /photos/:id` (embedded user) |
| Engagement | `photo.likes` + additional stats call | `GET /photos/:id` (likes) + `GET /photos/:id/statistics` |
| EXIF | `photo.exif.make`, `.model`, `.exposure_time`, `.aperture`, `.focal_length`, `.iso` | `GET /photos/:id` |
| Location | `photo.location.city`, `.country`, `.position.latitude`, `.position.longitude` | `GET /photos/:id` |
| Color | `photo.color` (HEX) | `GET /photos/:id` |
| Tags | `photo.tags[].title` | `GET /photos/:id` (full response includes tags) |
| More works | `GET /users/:username/photos` | Extra call |
| Similar | Based on current photo's `tags` or `color`, call `GET /search/photos` | Extra call |

### 5.3 Download Flow

```
Tap download button
    │
    ▼
┌─────────────────────┐
│  Select Size         │
│                     │
│  ● Raw (Original) 42MB │  ← From urls.raw
│  ○ Full (Fullscreen) 8MB│  ← From urls.full
│  ○ Regular     2MB  │  ← From urls.regular
│  ○ Small       500KB│  ← From urls.small
│  ○ Thumb       200KB│  ← From urls.thumb
│                     │
│  [Cancel]  [Download]│
└─────────────────────┘
```

**Download process**:
1. User selects size → tap Download
2. Call `GET /photos/:id/download` (API compliance requirement)
3. Download image from returned `url` to local album
4. Show success SnackBar

### 5.4 Fullscreen Browse Mode

```
Tap image → hide nav bar + info panel
         → image fills screen
         → double-tap zoom / pinch to zoom
         → vertical swipe to exit fullscreen

Tap again → restore nav bar and info panel
```

---

## 6. Tab 4: Profile

### 6.1 Page Layout

```
┌────────────────────────────────────┐
│  Profile                            │
├────────────────────────────────────┤
│                                    │
│  ┌──────────────────────────┐     │
│  │   📊  52 photos bookmarked │     │  ← Stats card
│  │       3 collections created│     │
│  └──────────────────────────┘     │
│                                    │
│  ┌──────────────────────────┐     │
│  │   ⚙️ Settings             │  →  │  ← Menu list
│  ├──────────────────────────┤     │
│  │   🌙 Dark Mode           │ 🔘  │  ← Toggle
│  ├──────────────────────────┤     │
│  │   💾 Clear Image Cache   │  →  │
│  ├──────────────────────────┤     │
│  │   ❔ About Musea          │  →  │
│  └──────────────────────────┘     │
│                                    │
│  ┌──────────────────────────┐     │
│  │   ⚡ Data Source          │     │
│  │    Unsplash API v1       │     │  ← Brand info
│  │    50 requests/hour left│     │
│  └──────────────────────────┘     │
│                                    │
└────────────────────────────────────┘
```

### 6.2 Settings

| Setting | Type | Notes |
|---------|------|-------|
| Dark mode | Toggle | Switch theme (light/dark/system) |
| Clear image cache | Button | Clear disk cache, show current cache size |
| About Musea | Navigate | Version, tech stack, credits |

---

## 7. Shared Components

### 7.1 PhotoFeed

Reusable single-column feed component used in Discover, Explore, Topics, Collection Detail, etc. Each item is a full-width photo card.

| Prop | Type | Notes |
|------|------|-------|
| `photos` | `List<Photo>` | Photo data list |
| `onPhotoTap` | `(Photo, int) → void` | Tap photo → detail page (pass index for swipe navigation) |
| `onUserTap` | `(User) → void` | Tap avatar → photographer page |
| `onLikeTap` | `(Photo) → void` | Like button callback |
| `onSaveTap` | `(Photo) → void` | Save button callback (show collection picker) |
| `onDownloadTap` | `(Photo) → void` | Download button callback (show size picker) |
| `onLoadMore` | `() → void` | Scroll to bottom → load more |
| `isLiked` | `(Photo) → bool` | Check if photo is liked (local state) |
| `isSaved` | `(Photo) → bool` | Check if photo is saved (local state) |

### 7.2 TopicBar

| Prop | Type | Notes |
|------|------|-------|
| `topics` | `List<Topic>` | Unsplash topic list |
| `selectedId` | `String` | Currently selected topic ID |
| `onTopicTap` | `(Topic) → void` | Topic switch callback |
| `showAll` | `bool` | Whether to include "All" option |

### 7.3 SearchFilters

| Prop | Type | Notes |
|------|------|-------|
| `selectedColor` | `String?` | Current color parameter |
| `selectedOrientation` | `String?` | Current orientation parameter |
| `selectedOrder` | `String` | Sort order |
| `onFilterChanged` | `(Filters) → void` | Filter change callback |

### 7.4 EmptyState

| Prop | Type | Notes |
|------|------|-------|
| `icon` | `IconData` | Empty state icon |
| `title` | `String` | Title |
| `subtitle` | `String?` | Subtitle |
| `action` | `Widget?` | Action button (e.g., "Go to Discover") |

### 7.5 ErrorState

| Prop | Type | Notes |
|------|------|-------|
| `message` | `String` | Error message |
| `onRetry` | `VoidCallback?` | Retry button callback |

---

## 8. Navigation & Routes

### 8.1 Page Stack

```
App
├── Home (Bottom Navigation)
│   ├── Discover (DiscoverPage)
│   ├── Explore (ExplorePage)
│   ├── Collections (CollectionsPage)
│   └── Profile (ProfilePage)
├── Photo Detail Page (PhotoDetailPage)
├── Photographer Page (PhotographerPage)
├── Collection Detail Page (CollectionDetailPage)
├── Topic Detail Page (TopicDetailPage)
└── Full Screen Image Page (FullScreenImagePage)
```

### 8.2 Page Relationships

```
Discover ──tap photo──→ Photo Detail ──tap photographer──→ Photographer Page
                          │                                  │
                          ├──tap tag──→ Explore (pre-filled search)
                          ├──bookmark──→ Collection picker dialog
                          └──similar photo──→ Another photo detail

Explore ──search results──→ Photo Detail

Topic chip ──tap──→ Topic Detail ──tap photo──→ Photo Detail

Collections ──tap collection──→ Collection Detail ──tap photo──→ Photo Detail
  │                                    │
  └──create/edit──→ Dialog           └──remove──→ Confirmation dialog
```

---

## 9. Data Flow Overview

```
┌──────────────────────────────────────────────┐
│                  UI Layer                      │
│  Pages / Widgets / Components                  │
└────────────────────┬─────────────────────────┘
                     │ State Management
                     ▼
┌──────────────────────────────────────────────┐
│            Business Logic Layer                │
│  UseCases / Providers / Blocs                  │
│  - Data aggregation (e.g., detail = photo+stats+photographer works)  │
│  - Caching strategy                           │
│  - Collection CRUD                            │
└────────────────────┬─────────────────────────┘
                     ▼
┌──────────────────────────────────────────────┐
│              Data Layer                        │
│  ┌─────────────────┐  ┌──────────────────┐   │
│  │ Unsplash API    │  │ Local Storage    │   │
│  │ (REST Client)   │  │ (Hive/SQLite)    │   │
│  └─────────────────┘  └──────────────────┘   │
└──────────────────────────────────────────────┘
```

### Data Fusion Example: Detail Page

```
PhotoDetailPage required data:
  1. Photo details  → GET /photos/:id              (API)
  2. Statistics     → GET /photos/:id/statistics   (API, optional)
  3. Photographer   → GET /users/:username/photos  (API)
  4. Similar        → GET /search/photos (based on tags)  (API)
  5. Save status    → Local query: is photo saved?  (Local)
```

---

## 10. Interactions & Animations

| Scenario | Animation | Notes |
|----------|-----------|-------|
| Image loading | BlurHash → fade-in image | Blur placeholder smooth transition to clear image |
| List entry | Cards fade-in and slide-up one by one | Staggered animation, 50ms interval per item |
| Tab switch | Smooth horizontal slide | PageView + bottom nav sync |
| Pull to refresh | Standard refresh indicator | Refresh icon + text |
| Search filter | AnimatedSwitcher | Content fade-in/out on filter change |
| Detail page entry | Hero shared element transition + swipe back | Feed image expands to detail; edge swipe to go back |
| Collection popup | Bottom sheet | Slide up from bottom |
| Empty state | Micro-animation illustration | Soft breathing animation |

---

## 11. API Call Summary by Page

| Page | API Call | Frequency |
|------|---------|-----------|
| Discover - All | `GET /photos?page=N` | Each entry / load more |
| Discover - Topic | `GET /topics` + `GET /topics/:slug/photos` | Entry + topic switch |
| Explore - Search | `GET /search/photos?query=&color=&orientation=&order_by=` | User input / filter change |
| Photo detail | `GET /photos/:id` (+ optional stats) | Entry |
| Detail - More works | `GET /users/:username/photos` | Entry |
| Detail - Similar | `GET /search/photos?query=tag1,tag2` | Entry |
| Collections page | Local read | Entry |
| Collection detail | Local read + `GET /photos/:id` (on demand) | Entry |
| Photographer page | `GET /users/:username` + `/users/:username/photos` | Entry |
| Topic detail | `GET /topics/:slug` + `GET /topics/:slug/photos` | Entry |

**Rate control strategy**: Use in-memory cache for repeated calls (topic list, photographer profiles) to reduce API requests. Image CDN hotlinks don't count toward rate limits.
