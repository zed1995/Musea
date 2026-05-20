# Download Sheet UI + Progress Design

> **Date**: 2026-05-20
> **Status**: Approved for implementation

## Goal

Redesign the download bottom sheet to match the functional prototype, and add download progress indication (in-app + Android notification).

## Current State

The download sheet shows 5 size options as `ListTile` items. Tapping an option immediately triggers download via `dio` bytes + `Gal.putImageBytes()`. No progress indication.

## Changes

### Sheet UI (prototype match)

Radio-button style size selection with resolution labels (`Width×Height`), plus Cancel/Download action buttons. After tapping Download, sheet transitions to a progress view.

### Download progress

- **In-app**: `LinearProgressIndicator` + percentage text + byte count in the sheet
- **Android notification**: `flutter_local_notifications` with ongoing progress notification, updated as download progresses
- **iOS**: In-app only (iOS doesn't have persistent notification progress for non-foreground-services)

### Resolution display

Derived from `Photo.width`/`Photo.height` using Unsplash URL naming conventions:

| Variant | Longest edge limit | Display formula |
|---------|-------------------|-----------------|
| Raw | Original | `{w}×{h}` |
| Full | 5760px | `min(w,5760)×min(h,5760)` (proportional) |
| Regular | 1080px | `min(w,1080)×min(h,1080)` |
| Small | 400px | `min(w,400)×min(h,400)` |
| Thumb | 200px | `min(w,200)×min(h,200)` |

### Files modified/created

| File | Action | Purpose |
|------|--------|---------|
| `pubspec.yaml` | Edit | Add `flutter_local_notifications` |
| `lib/main.dart` | Edit | Init notification plugin on app start |
| `lib/core/services/download_notifier.dart` | Create | Download state + notification management |
| `lib/features/photo_detail/presentation/widgets/download_sheet.dart` | Rewrite | New UI with radio buttons, progress view, Cancel/Download actions |
| `lib/features/photo_detail/presentation/pages/photo_detail_page.dart` | Edit | Wire new download flow |

### Data flow

```
User taps "Download Free"
  → DownloadSheet.show() → user selects size + taps "Download"
  → Sheet switches to progress view
  → DownloadNotifier.download(url, photo):
      1. Track via Unsplash API (GET /photos/:id/download)
      2. Dio GET bytes with onReceiveProgress → update progress
      3. flutter_local_notifications show/download progress notification
      4. Gal.putImageBytes() save to gallery
      5. flutter_local_notifications show success notification
  → Sheet shows completion → auto-close → SnackBar
```
