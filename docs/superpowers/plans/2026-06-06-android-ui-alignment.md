# Android UI Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align the existing Flutter app surfaces with the Android-oriented prototype refinements from commit `928e397` by introducing shared app-bar primitives and applying them across settings, search, mine/profile, immersive detail pages, and collection sheets without changing business behavior.

**Architecture:** Keep all routing, provider, and repository logic intact, and concentrate the work inside presentation widgets plus focused widget/router tests. Extract two narrow shared primitives for standard Android top bars and immersive hero app bars, then recompose the affected pages and sheets around those primitives so the visual language is consistent in one pass.

**Tech Stack:** Flutter, Riverpod, GoRouter, widget tests, existing app theme/colors

---

## File Map

### Create

- `lib/shared/widgets/android_top_bar.dart`
- `lib/shared/widgets/immersive_hero_app_bar.dart`
- `test/shared/widgets/android_top_bar_test.dart`

### Modify

- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/features/settings/presentation/pages/settings_language_page.dart`
- `lib/features/settings/presentation/pages/settings_downloads_page.dart`
- `lib/features/search/presentation/pages/search_page.dart`
- `lib/features/profile/presentation/pages/mine_page.dart`
- `lib/features/profile/presentation/pages/profile_page.dart`
- `lib/features/photo_detail/presentation/pages/photo_detail_page.dart`
- `lib/features/collections/presentation/pages/collection_detail_page.dart`
- `lib/features/collections/presentation/widgets/save_to_collection_sheet.dart`
- `lib/features/collections/presentation/widgets/create_collection_sheet.dart`
- `lib/features/collections/presentation/widgets/collection_edit_sheet.dart`
- `lib/features/collections/presentation/widgets/collection_manage_sheet.dart`
- `lib/features/collections/presentation/widgets/collection_delete_sheet.dart`
- `test/router/app_router_test.dart`
- `test/features/settings/presentation/pages/settings_page_test.dart`
- `test/features/settings/presentation/pages/settings_language_page_test.dart`
- `test/features/settings/presentation/pages/settings_downloads_page_test.dart`
- `test/features/search/presentation/pages/search_page_test.dart`
- `test/features/profile/presentation/pages/mine_tab_page_test.dart`
- `test/features/profile/presentation/pages/profile_page_test.dart`
- `test/features/photo_detail/presentation/pages/photo_detail_page_test.dart`
- `test/features/collections/presentation/pages/collection_detail_page_test.dart`
- `test/features/collections/presentation/widgets/save_to_collection_sheet_test.dart`
- `test/features/collections/presentation/widgets/create_collection_sheet_test.dart`
- `test/features/collections/presentation/widgets/collection_edit_sheet_test.dart`
- `test/features/collections/presentation/widgets/collection_manage_sheet_test.dart`
- `test/features/collections/presentation/widgets/collection_delete_sheet_test.dart`

### Responsibilities

- `android_top_bar.dart`: shared direct-title Android-style top bar with optional back button and action slots
- `immersive_hero_app_bar.dart`: shared scrim + transparent 48dp action layer for hero-image pages and sheets
- settings/search/mine/profile pages: adopt direct-title top bars and lighter Android page chrome
- photo/collection detail pages: adopt immersive hero app bar and tighter action sets
- collection sheets: align hero and sheet header controls to a flatter Android Material pattern
- updated tests: verify changed titles, navigation affordances, and moved/reduced hero-action emphasis

---

### Task 1: Add shared Android top bar primitive

**Files:**
- Create: `lib/shared/widgets/android_top_bar.dart`
- Create: `test/shared/widgets/android_top_bar_test.dart`

- [ ] **Step 1: Write the failing shared-widget test**

Create `test/shared/widgets/android_top_bar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/shared/widgets/android_top_bar.dart';

void main() {
  testWidgets('AndroidTopBar renders title and back affordance', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: AndroidTopBar(
            titleText: 'Settings',
            showBackButton: true,
          ),
        ),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('AndroidTopBar keeps title stable with trailing action slot', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AndroidTopBar(
            titleText: 'Search',
            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Search'), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/shared/widgets/android_top_bar_test.dart`

Expected: FAIL because `android_top_bar.dart` does not exist.

- [ ] **Step 3: Implement the shared top bar**

Create `lib/shared/widgets/android_top_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:musea/core/theme/colors.dart';

class AndroidTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AndroidTopBar({
    super.key,
    required this.titleText,
    this.showBackButton = false,
    this.onBack,
    this.leading,
    this.trailing,
    this.bottomBorder = true,
  });

  final String titleText;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? leading;
  final Widget? trailing;
  final bool bottomBorder;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final left = leading ??
        (showBackButton
            ? IconButton(
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : const SizedBox(width: 40, height: 40));

    final right = trailing ?? const SizedBox(width: 40, height: 40);

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.gray50,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: bottomBorder
          ? const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1),
            )
          : null,
      titleSpacing: 0,
      title: Row(
        children: [
          SizedBox(width: 48, child: Align(alignment: Alignment.centerLeft, child: left)),
          Expanded(
            child: Text(
              titleText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
          ),
          SizedBox(width: 48, child: Align(alignment: Alignment.centerRight, child: right)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/shared/widgets/android_top_bar_test.dart`

Expected: PASS with 2 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/android_top_bar.dart test/shared/widgets/android_top_bar_test.dart
git commit -m "feat: add Android top bar primitive"
```

---

### Task 2: Add shared immersive hero app bar primitive

**Files:**
- Create: `lib/shared/widgets/immersive_hero_app_bar.dart`
- Modify: `test/shared/widgets/android_top_bar_test.dart`

- [ ] **Step 1: Extend the failing shared-widget test with immersive coverage**

Append to `test/shared/widgets/android_top_bar_test.dart`:

```dart
testWidgets('ImmersiveHeroAppBar renders back and action buttons', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Container(color: Colors.black),
            ImmersiveHeroAppBar(
              onBack: () {},
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_border_rounded),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.ios_share_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
  expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/shared/widgets/android_top_bar_test.dart`

Expected: FAIL because `ImmersiveHeroAppBar` is undefined.

- [ ] **Step 3: Implement the immersive hero app bar**

Create `lib/shared/widgets/immersive_hero_app_bar.dart`:

```dart
import 'package:flutter/material.dart';

class ImmersiveHeroAppBar extends StatelessWidget {
  const ImmersiveHeroAppBar({
    super.key,
    this.onBack,
    this.actions = const [],
    this.topPadding,
  });

  final VoidCallback? onBack;
  final List<Widget> actions;
  final double? topPadding;

  @override
  Widget build(BuildContext context) {
    final padding = topPadding ?? MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.only(top: padding + 8, left: 4, right: 4, bottom: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.38),
            Colors.black.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const Spacer(),
          for (final action in actions)
            SizedBox(width: 48, height: 48, child: Center(child: action)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/shared/widgets/android_top_bar_test.dart`

Expected: PASS with 3 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/immersive_hero_app_bar.dart test/shared/widgets/android_top_bar_test.dart
git commit -m "feat: add immersive hero app bar primitive"
```

---

### Task 3: Align standard top-bar pages

**Files:**
- Modify: `lib/features/settings/presentation/pages/settings_page.dart`
- Modify: `lib/features/settings/presentation/pages/settings_language_page.dart`
- Modify: `lib/features/settings/presentation/pages/settings_downloads_page.dart`
- Modify: `lib/features/search/presentation/pages/search_page.dart`
- Modify: `lib/features/profile/presentation/pages/mine_page.dart`
- Modify: `lib/features/profile/presentation/pages/profile_page.dart`
- Modify: `test/router/app_router_test.dart`
- Modify: `test/features/settings/presentation/pages/settings_page_test.dart`
- Modify: `test/features/settings/presentation/pages/settings_language_page_test.dart`
- Modify: `test/features/settings/presentation/pages/settings_downloads_page_test.dart`
- Modify: `test/features/search/presentation/pages/search_page_test.dart`
- Modify: `test/features/profile/presentation/pages/mine_tab_page_test.dart`
- Modify: `test/features/profile/presentation/pages/profile_page_test.dart`

- [ ] **Step 1: Write failing assertions for the new navigation language**

Update the existing tests to expect direct-title Android bars:

```dart
expect(find.byIcon(Icons.arrow_back_rounded), findsWidgets);
expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
expect(find.text('Settings'), findsOneWidget);
expect(find.text('Language'), findsOneWidget);
expect(find.text('Downloads'), findsOneWidget);
```

In `test/features/search/presentation/pages/search_page_test.dart`, add:

```dart
expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
```

In `test/features/profile/presentation/pages/mine_tab_page_test.dart`, add:

```dart
expect(find.text('Mine'), findsOneWidget);
expect(find.byIcon(Icons.tune_rounded), findsNothing);
expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
```

- [ ] **Step 2: Run the focused tests to verify they fail**

Run:

```bash
flutter test \
  test/router/app_router_test.dart \
  test/features/settings/presentation/pages/settings_page_test.dart \
  test/features/settings/presentation/pages/settings_language_page_test.dart \
  test/features/settings/presentation/pages/settings_downloads_page_test.dart \
  test/features/search/presentation/pages/search_page_test.dart \
  test/features/profile/presentation/pages/mine_tab_page_test.dart \
  test/features/profile/presentation/pages/profile_page_test.dart
```

Expected: FAIL because the pages still render the old app bars and icon expectations.

- [ ] **Step 3: Implement the shared top bar across standard pages**

Apply this pattern in the page files:

```dart
return Scaffold(
  backgroundColor: AppColors.gray50,
  appBar: AndroidTopBar(
    titleText: l10n.settingsTitle,
    showBackButton: true,
  ),
  body: ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
    children: [...],
  ),
);
```

For `MinePage`, update the signed-out and signed-in headers to use direct titles plus a simpler settings action:

```dart
AndroidTopBar(
  titleText: l10n.minePageTitle,
  trailing: IconButton(
    onPressed: () => context.push('/settings'),
    icon: const Icon(Icons.settings_outlined),
  ),
  bottomBorder: false,
)
```

For `SearchPage`, replace the custom back affordance in `_SearchHeader` with:

```dart
IconButton(
  onPressed: onBack,
  icon: const Icon(Icons.arrow_back_rounded),
)
```

- [ ] **Step 4: Run the focused tests to verify they pass**

Run the same command from Step 2.

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/settings/presentation/pages/settings_page.dart \
  lib/features/settings/presentation/pages/settings_language_page.dart \
  lib/features/settings/presentation/pages/settings_downloads_page.dart \
  lib/features/search/presentation/pages/search_page.dart \
  lib/features/profile/presentation/pages/mine_page.dart \
  lib/features/profile/presentation/pages/profile_page.dart \
  test/router/app_router_test.dart \
  test/features/settings/presentation/pages/settings_page_test.dart \
  test/features/settings/presentation/pages/settings_language_page_test.dart \
  test/features/settings/presentation/pages/settings_downloads_page_test.dart \
  test/features/search/presentation/pages/search_page_test.dart \
  test/features/profile/presentation/pages/mine_tab_page_test.dart \
  test/features/profile/presentation/pages/profile_page_test.dart
git commit -m "feat: align standard page app bars with Android prototype"
```

---

### Task 4: Align immersive detail pages

**Files:**
- Modify: `lib/features/photo_detail/presentation/pages/photo_detail_page.dart`
- Modify: `lib/features/collections/presentation/pages/collection_detail_page.dart`
- Modify: `test/features/photo_detail/presentation/pages/photo_detail_page_test.dart`
- Modify: `test/features/collections/presentation/pages/collection_detail_page_test.dart`

- [ ] **Step 1: Write failing assertions for the hero action sets**

Update `test/features/photo_detail/presentation/pages/photo_detail_page_test.dart` with:

```dart
expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
```

Update `test/features/collections/presentation/pages/collection_detail_page_test.dart` with:

```dart
expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
```

- [ ] **Step 2: Run the focused tests to verify they fail**

Run:

```bash
flutter test \
  test/features/photo_detail/presentation/pages/photo_detail_page_test.dart \
  test/features/collections/presentation/pages/collection_detail_page_test.dart
```

Expected: FAIL because the current hero controls and icon groupings do not match.

- [ ] **Step 3: Recompose the detail-page heroes around `ImmersiveHeroAppBar`**

In `photo_detail_page.dart`, apply this structure inside the hero stack:

```dart
Stack(
  children: [
    _HeroImage(photo: widget.photo),
    ImmersiveHeroAppBar(
      onBack: () => Navigator.of(context).maybePop(),
      actions: [
        IconButton(
          onPressed: widget.onBookmarkTap,
          icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white),
        ),
        IconButton(
          onPressed: widget.onShareTap,
          icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
        ),
      ],
    ),
  ],
)
```

In `collection_detail_page.dart`, keep owner management available but move it below the hero title or into the sheet trigger area rather than the top-right hero cluster:

```dart
ImmersiveHeroAppBar(
  onBack: () => Navigator.of(context).maybePop(),
  actions: [
    IconButton(
      onPressed: onShareTap,
      icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
    ),
  ],
)
```

- [ ] **Step 4: Run the focused tests to verify they pass**

Run the same command from Step 2.

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/photo_detail/presentation/pages/photo_detail_page.dart \
  lib/features/collections/presentation/pages/collection_detail_page.dart \
  test/features/photo_detail/presentation/pages/photo_detail_page_test.dart \
  test/features/collections/presentation/pages/collection_detail_page_test.dart
git commit -m "feat: align immersive detail headers with Android prototype"
```

---

### Task 5: Align collection sheets

**Files:**
- Modify: `lib/features/collections/presentation/widgets/save_to_collection_sheet.dart`
- Modify: `lib/features/collections/presentation/widgets/create_collection_sheet.dart`
- Modify: `lib/features/collections/presentation/widgets/collection_edit_sheet.dart`
- Modify: `lib/features/collections/presentation/widgets/collection_manage_sheet.dart`
- Modify: `lib/features/collections/presentation/widgets/collection_delete_sheet.dart`
- Modify: `test/features/collections/presentation/widgets/save_to_collection_sheet_test.dart`
- Modify: `test/features/collections/presentation/widgets/create_collection_sheet_test.dart`
- Modify: `test/features/collections/presentation/widgets/collection_edit_sheet_test.dart`
- Modify: `test/features/collections/presentation/widgets/collection_manage_sheet_test.dart`
- Modify: `test/features/collections/presentation/widgets/collection_delete_sheet_test.dart`

- [ ] **Step 1: Write failing header assertions for the sheets**

In the existing sheet tests, add assertions like:

```dart
expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
expect(find.byIcon(Icons.close_rounded), findsOneWidget);
```

For delete/manage sheets where there should be no hero action cluster expansion, add:

```dart
expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
```

- [ ] **Step 2: Run the focused sheet tests to verify they fail**

Run:

```bash
flutter test \
  test/features/collections/presentation/widgets/save_to_collection_sheet_test.dart \
  test/features/collections/presentation/widgets/create_collection_sheet_test.dart \
  test/features/collections/presentation/widgets/collection_edit_sheet_test.dart \
  test/features/collections/presentation/widgets/collection_manage_sheet_test.dart \
  test/features/collections/presentation/widgets/collection_delete_sheet_test.dart
```

Expected: FAIL because the current sheets still use the older floating-control styling and icon structure.

- [ ] **Step 3: Rebuild the sheet headers around the shared primitives**

Use this pattern in hero-image sheets:

```dart
Stack(
  children: [
    _SheetHeroImage(...),
    ImmersiveHeroAppBar(
      onBack: () => Navigator.of(context).maybePop(),
      actions: [...],
    ),
  ],
)
```

Use this pattern for the flatter sheet header:

```dart
Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(description),
        ],
      ),
    ),
    IconButton(
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.close_rounded),
    ),
  ],
)
```

- [ ] **Step 4: Run the focused sheet tests to verify they pass**

Run the same command from Step 2.

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/collections/presentation/widgets/save_to_collection_sheet.dart \
  lib/features/collections/presentation/widgets/create_collection_sheet.dart \
  lib/features/collections/presentation/widgets/collection_edit_sheet.dart \
  lib/features/collections/presentation/widgets/collection_manage_sheet.dart \
  lib/features/collections/presentation/widgets/collection_delete_sheet.dart \
  test/features/collections/presentation/widgets/save_to_collection_sheet_test.dart \
  test/features/collections/presentation/widgets/create_collection_sheet_test.dart \
  test/features/collections/presentation/widgets/collection_edit_sheet_test.dart \
  test/features/collections/presentation/widgets/collection_manage_sheet_test.dart \
  test/features/collections/presentation/widgets/collection_delete_sheet_test.dart
git commit -m "feat: align collection sheets with Android prototype"
```

---

### Task 6: Format and run regression verification

**Files:**
- Modify: all files touched in Tasks 1-5

- [ ] **Step 1: Format the modified Dart files**

Run:

```bash
dart format \
  lib/shared/widgets/android_top_bar.dart \
  lib/shared/widgets/immersive_hero_app_bar.dart \
  lib/features/settings/presentation/pages/settings_page.dart \
  lib/features/settings/presentation/pages/settings_language_page.dart \
  lib/features/settings/presentation/pages/settings_downloads_page.dart \
  lib/features/search/presentation/pages/search_page.dart \
  lib/features/profile/presentation/pages/mine_page.dart \
  lib/features/profile/presentation/pages/profile_page.dart \
  lib/features/photo_detail/presentation/pages/photo_detail_page.dart \
  lib/features/collections/presentation/pages/collection_detail_page.dart \
  lib/features/collections/presentation/widgets/save_to_collection_sheet.dart \
  lib/features/collections/presentation/widgets/create_collection_sheet.dart \
  lib/features/collections/presentation/widgets/collection_edit_sheet.dart \
  lib/features/collections/presentation/widgets/collection_manage_sheet.dart \
  lib/features/collections/presentation/widgets/collection_delete_sheet.dart \
  test/shared/widgets/android_top_bar_test.dart \
  test/router/app_router_test.dart \
  test/features/settings/presentation/pages/settings_page_test.dart \
  test/features/settings/presentation/pages/settings_language_page_test.dart \
  test/features/settings/presentation/pages/settings_downloads_page_test.dart \
  test/features/search/presentation/pages/search_page_test.dart \
  test/features/profile/presentation/pages/mine_tab_page_test.dart \
  test/features/profile/presentation/pages/profile_page_test.dart \
  test/features/photo_detail/presentation/pages/photo_detail_page_test.dart \
  test/features/collections/presentation/pages/collection_detail_page_test.dart \
  test/features/collections/presentation/widgets/save_to_collection_sheet_test.dart \
  test/features/collections/presentation/widgets/create_collection_sheet_test.dart \
  test/features/collections/presentation/widgets/collection_edit_sheet_test.dart \
  test/features/collections/presentation/widgets/collection_manage_sheet_test.dart \
  test/features/collections/presentation/widgets/collection_delete_sheet_test.dart
```

Expected: formatting completes with no errors.

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`

Expected: PASS.

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze`

Expected: PASS with no new issues.

- [ ] **Step 4: Commit**

```bash
git add \
  lib/shared/widgets/android_top_bar.dart \
  lib/shared/widgets/immersive_hero_app_bar.dart \
  lib/features/settings/presentation/pages/settings_page.dart \
  lib/features/settings/presentation/pages/settings_language_page.dart \
  lib/features/settings/presentation/pages/settings_downloads_page.dart \
  lib/features/search/presentation/pages/search_page.dart \
  lib/features/profile/presentation/pages/mine_page.dart \
  lib/features/profile/presentation/pages/profile_page.dart \
  lib/features/photo_detail/presentation/pages/photo_detail_page.dart \
  lib/features/collections/presentation/pages/collection_detail_page.dart \
  lib/features/collections/presentation/widgets/save_to_collection_sheet.dart \
  lib/features/collections/presentation/widgets/create_collection_sheet.dart \
  lib/features/collections/presentation/widgets/collection_edit_sheet.dart \
  lib/features/collections/presentation/widgets/collection_manage_sheet.dart \
  lib/features/collections/presentation/widgets/collection_delete_sheet.dart \
  test/shared/widgets/android_top_bar_test.dart \
  test/router/app_router_test.dart \
  test/features/settings/presentation/pages/settings_page_test.dart \
  test/features/settings/presentation/pages/settings_language_page_test.dart \
  test/features/settings/presentation/pages/settings_downloads_page_test.dart \
  test/features/search/presentation/pages/search_page_test.dart \
  test/features/profile/presentation/pages/mine_tab_page_test.dart \
  test/features/profile/presentation/pages/profile_page_test.dart \
  test/features/photo_detail/presentation/pages/photo_detail_page_test.dart \
  test/features/collections/presentation/pages/collection_detail_page_test.dart \
  test/features/collections/presentation/widgets/save_to_collection_sheet_test.dart \
  test/features/collections/presentation/widgets/create_collection_sheet_test.dart \
  test/features/collections/presentation/widgets/collection_edit_sheet_test.dart \
  test/features/collections/presentation/widgets/collection_manage_sheet_test.dart \
  test/features/collections/presentation/widgets/collection_delete_sheet_test.dart
git commit -m "test: verify Android UI alignment pass"
```
