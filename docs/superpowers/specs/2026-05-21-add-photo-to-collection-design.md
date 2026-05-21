# Add Photo to Collection — Design Spec

## Overview

Allow authenticated users to save photos to Unsplash collections from the Discover photo feed and Photo Detail page. The feature reuses the existing bookmark icon as the entry point, with an auth gate for unauthenticated users and an inline bottom-sheet flow for collection selection or creation.

## Flow

1. User taps bookmark icon on a photo card (Discover page) or hero bar (Photo Detail page)
2. **If unauthenticated:** show existing `AuthGateSheet` (with save-specific copy), then on sign-in continuation proceeds to step 3
3. **If authenticated:** show `SaveToCollectionSheet` bottom sheet pre-populated with user's collections
4. User either:
   - Selects an existing collection → calls `POST /collections/{id}/add` → on success, dismiss sheet → show toast
   - Taps "Create new collection" → sheet transitions to a create-collection form (inline state switch, no sheet stacking)
5. After creating a collection → return to the selection view with the new collection prepended at top
6. User selects the new (or any) collection → same API call + toast

## API Layer Changes

### `ApiConstants` — one new helper
```dart
static String collectionAdd(String collectionId) =>
    '$collections/$collectionId/add';
```

### `CollectionRemoteDataSource` — one new method
```dart
Future<void> addPhotoToCollection(String collectionId, String photoId)
```
Implementation: `POST /collections/{collectionId}/add` with body `{'photo_id': photoId}`.

### `CollectionRepository` (abstract) — one new method
```dart
Future<Either<Failure, void>> addPhotoToCollection(
  String collectionId,
  String photoId,
);
```

### `CollectionRepositoryImpl` — implementation
Calls `remoteDataSource.addPhotoToCollection(collectionId, photoId)`. Error handling follows existing pattern (ServerException → Failure.server, NetworkException → Failure.network, etc.)

## New Widget: `SaveToCollectionSheet`

A `ConsumerStatefulWidget` shown as a modal bottom sheet.

### State management
- `_viewMode`: enum `select` | `create`
- `_collections`: `List<Collection>` — fetched on init via `collectionsProvider(1)`
- `_isSaving`: bool — loading state during API call
- `_selectedPhotoId`: String — passed in constructor

### View: Select Collection

- Pill indicator at top
- Title: "Select collection" + subtitle
- Close (×) button
- "Create new collection" row with + icon, description, chevron → switches to create mode
- "My Collections" section header with count
- List of collections, each showing:
  - Cover photo (54×54 rounded rect)
  - Title
  - Photo count + relative time or tagline
  - Privacy badge ("Private")
  - Chevron
- Loading state: shimmer/skeleton while collections fetch
- Empty state: "No collections yet" with prompt to create
- Error state (API failure): inline retry link

### View: Create Collection

- Same sheet shell (pill + container)
- Title "New collection" + subtitle
- "Back to collections" link (arrow + text) at top of form body
- Text field: Collection Name (max 60 chars, counter)
- Text area: Description (optional)
- Visibility toggle: Private (default) / Public
- Submit button: "Create collection"
- Error state: inline error text if creation fails
- On success: switch back to select mode, prepend new collection to list

### Toast

After a photo is successfully added to a collection:
```
┌─────────────────────────────────────────────┐
│  ✓   Saved to [Collection Name]      View   │
└─────────────────────────────────────────────┘
```
- Positioned above the sheet (or as a SnackBar)
- "View" → `context.push('/collection/{id}')`
- Auto-dismiss after ~3 s

## Integration

### Discover Page (`discover_page.dart`)

Replace `onBookmarkTap`:
```
onBookmarkTap: (photo) => _handleSaveToCollection(photo)
```

New method:
```dart
Future<void> _handleSaveToCollection(Photo photo) async {
  final authState = ref.read(authControllerProvider);
  if (!authState.isAuthenticated) {
    await showAuthGateSheet(context, ref,
      title: 'Sign in to save photos',
      body: 'Build collections of what inspires you and keep them in sync.',
    );
  }
  if (!context.mounted) return;
  await showSaveToCollectionSheet(context, photoId: photo.id);
}
```

### Photo Detail Page (`photo_detail_page.dart`)

Add `onTap` to the existing `Icons.bookmark_border` `_HeroActionButton`:
```dart
_HeroActionButton(
  icon: Icons.bookmark_border,
  onTap: () => _handleSaveToCollection(context, ref, photo),
),
```

Where `_handleSaveToCollection` follows the same auth-gate pattern.

## What Is NOT Changed

- **PhotoCard** widget: signature stays the same; only callers change their `onBookmarkTap` behavior
- **Existing `showCreateCollectionSheet`**: remains as-is for the standalone Collections tab flow; the inline create form in `SaveToCollectionSheet` is an independent widget
- **Collection list API**: the existing `collectionsProvider(1)` is reused (first page is sufficient for most users)
- **Auth gate sheet**: reused with parameterized title/body copy

## Error Handling

| Scenario | Behaviour |
|----------|-----------|
| API rate limit | Show error text in sheet body |
| Network error | Show error text with retry option |
| Unauthorized (401) | Show "Please sign in again" error, offer re-auth |
| Collection fetch fails | Show error state in select view with retry |
| Photo already in collection | API returns 409-style; show "Already saved" toast |

## Testing Plan

### Unit Tests
- `CollectionRemoteDataSourceImpl.addPhotoToCollection` — verify POST with correct body
- `CollectionRepositoryImpl.addPhotoToCollection` — verify error mapping

### Widget Tests
- `SaveToCollectionSheet` — verify collections load, create mode switch, save action
- Auth gate integration — verify unauthenticated tap shows gate, authenticated tap shows sheet

### Existing Tests
- No existing tests should break; the bookmark callbacks in Discover and Photo Detail are the only changed call sites
