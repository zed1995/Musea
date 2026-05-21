# Create Collection Feature

## Overview

Add a "Create Collection" feature to the Collections page. When the user taps the `+` button in the collections header, if they are not authenticated, an auth bottom sheet is shown. If they are authenticated, a create-collection bottom sheet is presented. On submit, the Unsplash API is called to create the collection, and the user is navigated to the new collection's detail page.

## Flow

```
Tap + button in Collections header
  → Check authState.isAuthenticated
    → false → showAuthGateSheet (existing)
    → true  → showCreateCollectionSheet
      → User fills form → taps "Create collection"
        → POST /collections with title, description, private
        → On success: pop sheet → push /collection/{id}
        → On error: show inline error in sheet
```

## UI — Create Collection Sheet

Bottom sheet (`create_collection_sheet.dart`) matching `prototype/collection-create-sheet.html`:

- **Header**: Pill drag indicator, "New collection" title, subtitle, close (x) button
- **Collection Name**: Text input, required, max 60 characters, with "N / 60" counter
- **Description**: Textarea, optional
- **Visibility**: Private (default, selected) / Public — radio-style selection
- **Create button**: Primary CTA, disabled when title is empty
- **States**: Loading spinner on button during submission, error message on failure

## Data Layer

### Remote Datasource (existing file — add method)

```dart
Future<CollectionModel> createCollection({
  required String title,
  String? description,
  bool? private,
});
```

Calls `_dioClient.post('/collections', data: body)` with title, description, private fields.

### Repository (existing file — add method)

```dart
Future<Either<Failure, Collection>> createCollection({
  required String title,
  String? description,
  bool? private,
});
```

Wraps datasource call with existing error handling pattern (ServerException, NetworkException, RateLimitException → Failure).

### Provider (new file)

`createCollectionProvider` — exposes a callable function `(CreateCollectionParams) → Future<Either<Failure, Collection>>`.

## Files Changed

| File | Change |
|------|--------|
| `lib/core/constants/api_constants.dart` | Add `write_collections` to `authScopes` |
| `lib/features/collections/data/datasources/collection_remote_datasource.dart` | Add `createCollection()` method |
| `lib/features/collections/domain/repositories/collection_repository.dart` | Add `createCollection()` method |
| `lib/features/collections/data/repositories/collection_repository_impl.dart` | Implement `createCollection()` |
| `lib/features/collections/presentation/providers/collections_provider.dart` | Add `createCollectionProvider` |
| `lib/features/collections/presentation/widgets/create_collection_sheet.dart` | **NEW** — bottom sheet form widget |
| `lib/features/collections/presentation/pages/collections_page.dart` | Wire `+` button onPressed |

## Auth Considerations

- OAuth scope `write_collections` must be added. Users who already authenticated will need to re-authenticate to grant the new scope.
- The create endpoint requires an authenticated user (Bearer token). The existing `ApiInterceptor` handles this automatically.

## Error Handling

- **403 Forbidden** / **401 Unauthorized**: Show message about re-authentication needed
- **Network error**: Inline error with retry
- **Title required**: Form validation — button disabled when empty

## Testing

- **Datasource test**: Verify correct POST request with body params
- **Repository test**: Verify error wrapping (success + all failure types)
- **Widget test**: Sheet renders correctly, form validation, submit triggers API
- **Collections page test**: + button behavior — unauthenticated shows auth sheet, authenticated shows create sheet
