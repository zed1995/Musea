# Musea MVP Phase 3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Users can search photos by keyword with color, orientation, and sort filters.

**Architecture:** New `explore` feature module. Search data source wraps `GET /search/photos`. Provider manages query + filter state with 300ms debounce. Filters, search input, and history are separate widgets composed into the ExplorePage. Search history persisted via SharedPreferences.

**Tech Stack:** Flutter 3.x, Riverpod, GoRouter, Dio, SharedPreferences, PhotoFeed (Phase 1)

---

### Task 1: Search remote data source

**Files:**
- Create: `lib/features/explore/data/datasources/search_remote_datasource.dart`

- [ ] **Step 1: Create SearchRemoteDataSource**

`lib/features/explore/data/datasources/search_remote_datasource.dart`:

```dart
import 'package:musea/core/network/dio_client.dart';
import 'package:musea/core/constants/api_constants.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';

class SearchParams {
  final String query;
  final String? color;
  final String? orientation;
  final String orderBy;
  final int page;

  const SearchParams({
    required this.query,
    this.color,
    this.orientation,
    this.orderBy = 'relevant',
    this.page = 1,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'query': query,
      'page': page,
      'per_page': ApiConstants.searchPerPage,
      'order_by': orderBy,
    };
    if (color != null) params['color'] = color;
    if (orientation != null) params['orientation'] = orientation;
    return params;
  }
}

abstract class SearchRemoteDataSource {
  Future<List<PhotoModel>> searchPhotos(SearchParams params);
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final DioClient _dioClient;

  SearchRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<PhotoModel>> searchPhotos(SearchParams params) async {
    final response = await _dioClient.get(
      ApiConstants.searchPhotos,
      queryParameters: params.toQueryParameters(),
    );
    return (response['results'] as List)
        .map((json) => PhotoModel.fromJson(json))
        .toList();
  }
}
```

- [ ] **Step 2: Verify analysis**

Run: `dart analyze lib/features/explore/data/datasources/search_remote_datasource.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/explore/data/datasources/
git commit -m "feat: add search remote data source with SearchParams"
```

---

### Task 2: Search Riverpod provider

**Files:**
- Create: `lib/features/explore/presentation/providers/search_provider.dart`

- [ ] **Step 1: Create search providers**

`lib/features/explore/presentation/providers/search_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/core/network/providers.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/explore/data/datasources/search_remote_datasource.dart';

final searchRemoteDataSourceProvider = Provider<SearchRemoteDataSource>((ref) {
  return SearchRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

// Holds current search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Holds current search filters
final searchColorProvider = StateProvider<String?>((ref) => null);
final searchOrientationProvider = StateProvider<String?>((ref) => null);
final searchOrderByProvider = StateProvider<String>((ref) => 'relevant');

// Debounced search params — triggers after 300ms of no query changes
final debouncedSearchParamsProvider = FutureProvider.autoDispose<SearchParams?>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return null;

  // Wait 300ms for debounce
  await Future.delayed(const Duration(milliseconds: 300));

  // Check if query changed during the delay
  final currentQuery = ref.read(searchQueryProvider);
  if (currentQuery.trim().isEmpty || currentQuery != query) return null;

  final color = ref.read(searchColorProvider);
  final orientation = ref.read(searchOrientationProvider);
  final orderBy = ref.read(searchOrderByProvider);

  return SearchParams(
    query: currentQuery.trim(),
    color: color,
    orientation: orientation,
    orderBy: orderBy,
  );
});

// Search results based on current params
final searchResultsProvider = FutureProvider.autoDispose<List<Photo>>((ref) async {
  final params = await ref.watch(debouncedSearchParamsProvider.future);
  if (params == null) return [];

  final dataSource = ref.read(searchRemoteDataSourceProvider);
  final photos = await dataSource.searchPhotos(params);
  return photos.map((p) => p.toEntity()).toList();
});
```

- [ ] **Step 2: Verify analysis**

Run: `dart analyze lib/features/explore/presentation/providers/search_provider.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/explore/presentation/providers/
git commit -m "feat: add search provider with debounce and filters"
```

---

### Task 3: Search input widget

**Files:**
- Create: `lib/features/explore/presentation/widgets/search_input.dart`

- [ ] **Step 1: Create SearchInput widget**

`lib/features/explore/presentation/widgets/search_input.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/explore/presentation/providers/search_provider.dart';

class SearchInput extends ConsumerWidget {
  const SearchInput({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);

    return TextField(
      onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search photos or photographers...',
        prefixIcon: const Icon(Icons.search, color: AppColors.gray500),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.gray500),
                onPressed: () => ref.read(searchQueryProvider.notifier).state = '',
              )
            : null,
        filled: true,
        fillColor: AppColors.gray100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analysis**

Run: `dart analyze lib/features/explore/presentation/widgets/search_input.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/explore/presentation/widgets/search_input.dart
git commit -m "feat: add search input widget"
```

---

### Task 4: Color filter bar

**Files:**
- Create: `lib/features/explore/presentation/widgets/color_filter_bar.dart`

- [ ] **Step 1: Create ColorFilterBar**

`lib/features/explore/presentation/widgets/color_filter_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/explore/presentation/providers/search_provider.dart';

class _ColorOption {
  final String label;
  final String? value;
  final Color color;

  const _ColorOption({required this.label, this.value, required this.color});
}

const _colorOptions = [
  _ColorOption(label: 'All', value: null, color: Colors.grey),
  _ColorOption(label: 'B&W', value: 'black_and_white', color: Colors.black),
  _ColorOption(label: 'Red', value: 'red', color: Colors.red),
  _ColorOption(label: 'Orange', value: 'orange', color: Colors.orange),
  _ColorOption(label: 'Yellow', value: 'yellow', color: Colors.yellow),
  _ColorOption(label: 'Green', value: 'green', color: Colors.green),
  _ColorOption(label: 'Teal', value: 'teal', color: Colors.teal),
  _ColorOption(label: 'Blue', value: 'blue', color: Colors.blue),
  _ColorOption(label: 'Purple', value: 'purple', color: Colors.purple),
  _ColorOption(label: 'Pink', value: 'magenta', color: Colors.pink),
  _ColorOption(label: 'White', value: 'white', color: Colors.white),
  _ColorOption(label: 'Black', value: 'black', color: Colors.black),
];

class ColorFilterBar extends ConsumerWidget {
  const ColorFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedColor = ref.watch(searchColorProvider);

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _colorOptions.length,
        itemBuilder: (context, index) {
          final option = _colorOptions[index];
          final isSelected = selectedColor == option.value;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ref.read(searchColorProvider.notifier).state = option.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? option.color : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? option.color : AppColors.gray300,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  option.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected
                        ? (option.color == Colors.white || option.color == Colors.yellow
                            ? Colors.black
                            : Colors.white)
                        : AppColors.gray600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analysis**

Run: `dart analyze lib/features/explore/presentation/widgets/color_filter_bar.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/explore/presentation/widgets/color_filter_bar.dart
git commit -m "feat: add color filter bar with 12 color options"
```

---

### Task 5: Orientation filter bar

**Files:**
- Create: `lib/features/explore/presentation/widgets/orientation_filter.dart`

- [ ] **Step 1: Create OrientationFilter**

`lib/features/explore/presentation/widgets/orientation_filter.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/explore/presentation/providers/search_provider.dart';

class OrientationFilter extends ConsumerWidget {
  const OrientationFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(searchOrientationProvider);

    return Row(
      children: [
        _buildChip(ref, 'All', null, selected),
        const SizedBox(width: 8),
        _buildChip(ref, 'Landscape', 'landscape', selected),
        const SizedBox(width: 8),
        _buildChip(ref, 'Portrait', 'portrait', selected),
      ],
    );
  }

  Widget _buildChip(WidgetRef ref, String label, String? value, String? selected) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => ref.read(searchOrientationProvider.notifier).state = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value == null
                  ? Icons.aspect_ratio
                  : value == 'landscape'
                      ? Icons.landscape
                      : Icons.portrait,
              size: 16,
              color: isSelected ? AppColors.onPrimary : AppColors.gray600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? AppColors.onPrimary : AppColors.gray600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analysis**

Run: `dart analyze lib/features/explore/presentation/widgets/orientation_filter.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/explore/presentation/widgets/orientation_filter.dart
git commit -m "feat: add orientation filter with landscape/portrait options"
```

---

### Task 6: Search history + hot tags widget

**Files:**
- Create: `lib/features/explore/presentation/widgets/search_history.dart`

- [ ] **Step 1: Create search history widget with SharedPreferences**

`lib/features/explore/presentation/widgets/search_history.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/explore/presentation/providers/search_provider.dart';

const _maxHistoryItems = 10;
const _historyKey = 'search_history';

final searchHistoryProvider = FutureProvider<List<String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(_historyKey) ?? [];
});

Future<void> addSearchHistory(String query) async {
  if (query.trim().isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  final history = prefs.getStringList(_historyKey) ?? [];
  history.remove(query);
  history.insert(0, query);
  if (history.length > _maxHistoryItems) {
    history.removeRange(_maxHistoryItems, history.length);
  }
  await prefs.setStringList(_historyKey, history);
}

class SearchHistory extends ConsumerWidget {
  const SearchHistory({super.key});

  static const hotTags = ['Nature', 'Wallpaper', 'Minimal', 'Architecture', 'Travel', 'Night'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(searchHistoryProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          historyAsync.when(
            data: (history) {
              if (history.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: history.map((term) {
                      return ActionChip(
                        label: Text(term, style: AppTextStyles.bodySmall),
                        onPressed: () => ref.read(searchQueryProvider.notifier).state = term,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Text('Popular', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: hotTags.map((tag) {
              return ActionChip(
                label: Text(tag, style: AppTextStyles.bodySmall),
                onPressed: () => ref.read(searchQueryProvider.notifier).state = tag,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                avatar: const Icon(Icons.trending_up, size: 14),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Add shared_preferences dependency**

Run: `cd /Users/zed/Codes/Musea && flutter pub add shared_preferences`

- [ ] **Step 3: Verify analysis**

Run: `dart analyze lib/features/explore/presentation/widgets/search_history.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/features/explore/presentation/widgets/search_history.dart pubspec.yaml pubspec.lock
git commit -m "feat: add search history widget with SharedPreferences storage"
```

---

### Task 7: ExplorePage (replaces placeholder)

**Files:**
- Create: `lib/features/explore/presentation/pages/explore_page.dart`

- [ ] **Step 1: Create ExplorePage**

`lib/features/explore/presentation/pages/explore_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/explore/presentation/providers/search_provider.dart';
import 'package:musea/features/explore/presentation/widgets/search_input.dart';
import 'package:musea/features/explore/presentation/widgets/color_filter_bar.dart';
import 'package:musea/features/explore/presentation/widgets/orientation_filter.dart';
import 'package:musea/features/explore/presentation/widgets/search_history.dart';
import 'package:musea/shared/widgets/photo_feed.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/empty_state.dart';

class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final isSearching = query.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SearchInput(),
                    const SizedBox(height: 12),
                    if (isSearching) ...[
                      ColorFilterBar(),
                      const SizedBox(height: 8),
                      _buildSortRow(ref),
                    ],
                  ],
                ),
              ),
            ),
            if (!isSearching)
              SliverToBoxAdapter(child: SearchHistory())
            else
              searchResults.when(
                data: (photos) {
                  if (photos.isEmpty) {
                    return SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.search_off,
                        title: 'No results found',
                        subtitle: 'Try different keywords or fewer filters',
                      ),
                    );
                  }
                  return PhotoFeed(
                    photos: photos,
                    isLoadingMore: false,
                    onPhotoTap: (photo) => context.push('/photo/${photo.id}'),
                    onUserTap: (photo) => context.push('/profile/${photo.user.username}'),
                    showDownloadButton: false,
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: LoadingIndicator()),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: ErrorState(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(searchResultsProvider),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortRow(WidgetRef ref) {
    final orderBy = ref.watch(searchOrderByProvider);
    return Row(
      children: [
        const OrientationFilter(),
        const Spacer(),
        GestureDetector(
          onTap: () {
            final newOrder = orderBy == 'relevant' ? 'latest' : 'relevant';
            ref.read(searchOrderByProvider.notifier).state = newOrder;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  orderBy == 'relevant' ? 'Relevant' : 'Latest',
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.swap_vert, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify analysis**

Run: `dart analyze lib/features/explore/presentation/pages/explore_page.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/explore/presentation/pages/explore_page.dart
git commit -m "feat: create ExplorePage with search, filters, and results"
```

---

### Task 8: Update routing (replace Explore placeholder)

**Files:**
- Modify: `lib/router/app_router.dart`

- [ ] **Step 1: Read and update app_router.dart**

Read `lib/router/app_router.dart`. The `/explore` route is currently using `ExplorePlaceholderPage` inside the ShellRoute.

Change the import section to add:
```dart
import 'package:musea/features/explore/presentation/pages/explore_page.dart';
```

Replace the `/explore` route:
```dart
GoRoute(
  path: '/explore',
  name: 'explore',
  pageBuilder: (context, state) => const NoTransitionPage(
    child: ExplorePage(),
  ),
),
```

Remove the `ExplorePlaceholderPage` class definition.

- [ ] **Step 2: Verify analysis**

Run: `dart analyze lib/router/app_router.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/router/app_router.dart
git commit -m "feat: replace Explore placeholder with real search page"
```

---

### Task 9: Write tests

**Files:**
- Create: `test/features/explore/presentation/widgets/search_input_test.dart`

- [ ] **Step 1: Write SearchInput widget test

`test/features/explore/presentation/widgets/search_input_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/explore/presentation/widgets/search_input.dart';
import 'package:musea/features/explore/presentation/providers/search_provider.dart';

void main() {
  testWidgets('SearchInput shows hint text and accepts input', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: SearchInput()),
        ),
      ),
    );

    expect(find.text('Search photos or photographers...'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nature');
    expect(find.text('nature'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test**

Run: `flutter test test/features/explore/presentation/widgets/search_input_test.dart`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add test/features/explore/presentation/widgets/search_input_test.dart
git commit -m "test: add SearchInput widget test"
```

---

### Self-Review

**1. Spec coverage:**
- [x] Search remote data source → Task 1
- [x] Debounced search provider → Task 2
- [x] Search input widget (300ms debounce, clear button) → Task 3
- [x] Color filter bar (12 colors) → Task 4
- [x] Orientation filter → Task 5
- [x] Search history (SharedPreferences, 10 items) → Task 6
- [x] Hot tags → Task 6
- [x] Explore page (results, empty state) → Task 7
- [x] Route update → Task 8
- [x] Tests → Task 9

**2. Placeholder scan:** No TBD, TODO, "implement later" in any code block.

**3. Type consistency:**
- `SearchParams` fields match API query parameters
- `searchResultsProvider` returns `List<Photo>` — matches PhotoFeed's expected type
- `searchQueryProvider` is `StateProvider<String>` — matches SearchInput's usage
- Color values match actual Unsplash API `color` parameter values
