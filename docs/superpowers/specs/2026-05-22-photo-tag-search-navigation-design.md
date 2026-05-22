# Photo Tag → Search Navigation

## Summary

Make tags on the photo detail page tappable. Clicking a tag navigates to the search page with the tag title as the search query.

## Changes

### `_TagChip` widget (photo_detail_page.dart)

- Add `VoidCallback? onTap` parameter
- Wrap existing `Container` with `GestureDetector`, passing `onTap`
- No visual changes

### Call site in `_PhotoDetailContent.build()`

Change `_TagChip(label: tag.title)` to:
```dart
_TagChip(
  label: tag.title,
  onTap: () => context.push(
    '/search?q=${Uri.encodeComponent(tag.title)}',
  ),
)
```

### Testing

- Widget test: verify `_TagChip.onTap` fires when tag is tapped
- Covers the callback contract; route integration tested at widget level with GoRouter setup
