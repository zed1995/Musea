# Collection Management — Design Spec

## Summary

Implement three collection management operations (edit, remove photos, delete) accessible via a Manage bottom sheet from the Collection Detail page. Only the collection owner can access these functions.

## Entry Point

**Collection Detail Page** (`collection_detail_page.dart`)

The topbar currently has three buttons: back, bookmark (empty callback), share (empty callback). Per the prototype:

- **Remove** the bookmark button
- **Add** a Manage button (grid icon) — only visible when the current user is the collection owner
- **Keep** the share button (empty callback, not in scope)

Owner check:

```dart
final authState = ref.watch(authControllerProvider);
final isOwner = authState.isAuthenticated &&
    authState.session?.user.id == collection.user?.id;
```

When the Manage button is tapped, show `CollectionManageSheet` as a modal bottom sheet.

## CollectionManageSheet

A modal bottom sheet with three menu rows:

1. **Edit details** — pencil icon. Subtitle: "Title, description, and visibility". Tapping opens `CollectionEditSheet`.
2. **Remove photos** — trash icon (olive/neutral color). Subtitle: "Enter multi-select mode for this collection". Tapping opens `CollectionRemovePhotosPage`.
3. **Delete collection** — trash icon (red). Subtitle: "Permanent action with confirmation". Tapping opens `CollectionDeleteSheet`.

Each row has a chevron-right icon on the trailing edge. The sheet has a drag handle, title "Manage collection", subtitle "Update the collection, clean up saved photos, or delete it safely.", and a close (x) button in the header.

Implementation: `lib/features/collections/presentation/widgets/collection_manage_sheet.dart`

## CollectionEditSheet

A modal bottom sheet with form fields:

- **Collection Name** — text field, 60 char max, shows character count
- **Description** — text field, optional, multiline
- **Visibility** — two-option toggle: Public / Private

Pre-populated with current collection values. "Save changes" button calls `PUT /collections/:id` then dismisses and refreshes the detail page.

Implementation: `lib/features/collections/presentation/widgets/collection_edit_sheet.dart`

## CollectionRemovePhotosPage

A page (not a sheet — too much content for a sheet) showing all photos in the collection in a 2-column grid. Each photo has a select chip (circle → checkmark on selection). Top section shows "Batch Mode" header with "Remove photos" title, a "Done" button that exits selection mode.

A floating bottom bar shows selection count and a "Remove N photos" action button. On confirm, calls `DELETE /collections/:id/remove?photo_id=xyz` for each selected photo (or batch if API supports it — the Unsplash API does not document batch remove, so call individually).

Implementation: `lib/features/collections/presentation/pages/collection_remove_photos_page.dart`

## CollectionDeleteSheet

A modal bottom sheet with:

- Red "Delete collection?" title
- Warning: "This permanently removes the collection and its saved links."
- Red danger note box: "Kyoto Research will be deleted" with explanation
- Confirmation input: user must type the collection name to enable the delete button
- "Delete collection" red CTA button (disabled until name matches)
- "Cancel" secondary button

On confirm, calls `DELETE /collections/:id`, pops back to collections list, refreshes the list.

Implementation: `lib/features/collections/presentation/widgets/collection_delete_sheet.dart`

## Data Layer Changes

### ApiConstants

Add path helpers:

```dart
static String collectionRemove(String collectionId, String photoId) =>
    '$collections/$collectionId/remove?photo_id=$photoId';
```

### CollectionRemoteDataSource

Add three methods:

```dart
Future<CollectionModel> updateCollection(String id, {
  String? title,
  String? description,
  bool? private,
});

Future<void> deleteCollection(String id);

Future<void> removePhotoFromCollection({
  required String collectionId,
  required String photoId,
});
```

### CollectionRepository

Add three methods matching the datasource, returning `Either<Failure, …>`.

### CollectionRepositoryImpl

Standard try/catch pattern mapping exceptions to Failures, same as existing methods.

## Provider Changes

Add mutation-style providers in `collections_provider.dart`:

```dart
// Simple mutation — caller awaits and invalidates on completion
final collectionRepositoryProvider // — already exists

// For edit: return the updated collection
FutureProvider.family<Collection, ({String id, String? title, String? description, bool? private})>

// For delete: void
FutureProvider.family<void, String>

// For remove photo: void
FutureProvider.family<void, ({String collectionId, String photoId})>
```

Pattern: each provider calls the repository, then invalidates `collectionDetailProvider` and `collectionPhotosProvider` on the relevant collection ID.

## Auth Integration

- `isOwner` check uses `authControllerProvider` (already exists)
- Manage button / sheet only shown for owner
- If auth session expires mid-session, the sheet is already open — closing it (dismiss) is fine; API call will return 401 which maps to `UnauthorizedFailure`

## File Changes Summary

### New files:
- `lib/features/collections/presentation/widgets/collection_manage_sheet.dart`
- `lib/features/collections/presentation/widgets/collection_edit_sheet.dart`
- `lib/features/collections/presentation/pages/collection_remove_photos_page.dart`
- `lib/features/collections/presentation/widgets/collection_delete_sheet.dart`

### Modified files:
- `lib/core/constants/api_constants.dart` — add `collectionRemove` path
- `lib/features/collections/data/datasources/collection_remote_datasource.dart` — add 3 methods
- `lib/features/collections/domain/repositories/collection_repository.dart` — add 3 methods
- `lib/features/collections/data/repositories/collection_repository_impl.dart` — implement 3 methods
- `lib/features/collections/presentation/providers/collections_provider.dart` — add mutation providers
- `lib/features/collections/presentation/pages/collection_detail_page.dart` — replace bookmark with manage button, owner check
- `lib/router/app_router.dart` — add route for `CollectionRemovePhotosPage` (if full screen route needed)

## Testing

### Data Layer
- Update collection: mock `PUT /collections/:id` returns updated collection
- Delete collection: mock `DELETE /collections/:id` returns 204
- Remove photo: mock `DELETE /collections/:id/remove?photo_id=xyz` returns 204

### Provider Layer
- Call mutation → verify repository method called → verify detail provider invalidated

### Widget Tests
- Owner sees Manage button; non-owner does not
- Manage sheet renders three menu items
- Edit sheet pre-populates fields, save button calls update
- Delete sheet requires name confirmation before enabling delete
- Remove photos page: selecting photos updates count, confirm calls remove for each

## Not in Scope

- Share button functionality
- Follow button on collection detail hero
- Collections list page updates (the deleted collection will disappear on next refresh naturally)
- Error retry handling within sheets (API errors show snackbar)
