# Topic Cache SWR (Stale-While-Revalidate) Design

## Problem

The topic filter bar on the Discover page shows a loading spinner on every app launch. Topics rarely change, so users should never perceive a loading state for this data.

## Solution: SWR Pattern

Always read the local cache first (instant display), then silently refresh in the background if the cache is stale.

### Data Flow

```
App start → Discover page accessed →
  ├─ Read Hive cache → show topics immediately (no loading)
  │   └─ No cache → show ["All"] fallback
  └─ Check TTL (lastUpdatedAt + 24h < now?)
       ├─ Yes (cache fresh) → nothing else happens
       └─ No (cache expired or missing) → background refresh:
            ├─ API succeeds → update Hive cache + lastUpdatedAt
            │   └─ State was empty → update UI with real topics
            │   └─ State had cached data → no UI update (write only)
            └─ API fails → silent (cached data stays visible)
```

### Key Rules

1. **TTL check timing**: Only on fresh app start when Discover page is first accessed. No re-check within the same session.
2. **Same session, has cache → background writes cache only, does not update UI**. Prevents topic deletion from causing filter loss.
3. **Only scenario that updates UI**: Transition from fallback empty list → real data from background fetch.
4. **Pull-to-refresh**: Refreshes photos only, never triggers topic refresh.

## Files Changed

| File | Change |
|------|--------|
| `lib/features/discover/data/datasources/topic_local_datasource.dart` | Add `lastUpdatedAt` storage, refactor read/write interface |
| `lib/features/discover/presentation/providers/topics_provider.dart` | Change from `FutureProvider` to `NotifierProvider` (SWR Notifier) |
| `lib/features/discover/presentation/pages/discover_page.dart` | Remove topic loading/error states |
| `lib/features/discover/data/repositories/photo_repository_impl.dart` | Simplify `getTopics()`, remove cache fallback logic |
| `test/features/discover/presentation/pages/discover_page_test.dart` | Adapt to new provider override syntax |
| `test/router/app_router_test.dart` | Adapt to new provider override syntax |

## Detailed Design

### 1. TopicLocalDataSource Extension

Storage structure changed to a JSON object containing both topics and timestamp:

```json
{
  "topics": [...],
  "lastUpdatedAt": "2026-05-20T10:00:00.000Z"
}
```

Interface changes:

```dart
abstract class TopicLocalDataSource {
  Future<void> saveTopics(List<TopicModel> topics); // stores topics + current time
  Future<List<TopicModel>> getTopics();              // returns topics only
  Future<DateTime?> getLastUpdatedAt();               // returns timestamp
  Future<void> clearCache();
}
```

### 2. TopicListNotifier (New SWR Provider)

```dart
final topicsProvider = NotifierProvider<TopicListNotifier, List<Topic>>(
  TopicListNotifier.new,
);

class TopicListNotifier extends Notifier<List<Topic>> {
  @override
  List<Topic> build() {
    _init(); // async init, doesn't block build
    return []; // sync default state
  }

  Future<void> _init() async {
    // 1. Read cache
    final cached = await _topicLocalDataSource.getTopics();
    if (cached.isNotEmpty) {
      state = cached.map((e) => e.toEntity()).toList();
    }

    // 2. Check TTL
    final lastUpdated = await _topicLocalDataSource.getLastUpdatedAt();
    if (lastUpdated != null &&
        DateTime.now().difference(lastUpdated).inHours < 24) {
      return; // cache still valid
    }

    // 3. Background refresh
    _refreshInBackground();
  }

  Future<void> _refreshInBackground() async {
    final result = await _photoRepository.getTopics();
    result.fold(
      (failure) => {/* silent */},
      (topics) async {
        await _topicLocalDataSource.saveTopics(
          topics.map((e) => TopicModel.fromEntity(e)).toList(),
        );
        if (state.isEmpty) {
          state = topics; // only update UI when transitioning from empty
        }
      },
    );
  }
}
```

### 3. DiscoverPage Simplification

Replace `topicsAsync.when()` with direct `List<Topic>` usage:

```dart
// Before
final topicsAsync = ref.watch(topicsProvider);
// ... topicsAsync.when(data: ..., loading: ..., error: ...)

// After
final topics = ref.watch(topicsProvider);
// ... topics.isEmpty ? show All only : show All + topics
```

- Remove `loading` branch (LoadingIndicator)
- Remove `error` branch (SizedBox.shrink)
- `RefreshIndicator.onRefresh` no longer invalidates topics provider

### 4. PhotoRepositoryImpl Simplification

`getTopics()` becomes a pure network request + cache write, removing fallback logic:

```dart
@override
Future<Either<Failure, List<Topic>>> getTopics(...) async {
  try {
    final topics = await remoteDataSource.getTopics(...);
    await topicLocalDataSource.saveTopics(topics);
    return Right(topics.map((t) => t.toEntity()).toList());
  } on ServerException catch (e) {
    return Left(Failure.server(...));
  } on NetworkException catch (e) {
    return Left(Failure.network(...));
  }
}
```

## Test Plan

1. **TopicLocalDataSource unit tests**
   - `saveTopics` then `getTopics` returns correct data
   - `getLastUpdatedAt` returns correct timestamp
   - `clearCache` empties all stored data

2. **TopicListNotifier unit tests**
   - Cache valid + not expired → state = cached data, no network request
   - Cache expired → state = cached data, background network request fired
   - No cache → state = [], background request updates state on success
   - Network request fails → state unchanged (empty or old cache)

3. **DiscoverPage widget tests**
   - Topics no longer show a loading indicator
   - No topics → only All tab is visible
   - Topics loaded → full tab list displayed
   - Pull-to-refresh leaves topics unchanged (verify not invalidated)

## Error Handling

| Scenario | Behavior |
|----------|----------|
| First launch, poor network, API timeout | Show only "All", no error, retry on next launch |
| Has cache, API fails | Continue showing stale cache, silent |
| Has cache, API returns fewer topics | Cache written but UI unchanged |
| Fallback empty state, background fetch succeeds | Topics silently appear in tab bar |
