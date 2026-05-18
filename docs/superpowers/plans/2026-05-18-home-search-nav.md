# Home Search And Nav Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update the home and bottom navigation surfaces to match the approved prototype direction and implement a dedicated full-screen search page.

**Architecture:** Keep `/discover` as the shell home route, remove it from bottom-nav selection logic, and add a root-level `/search` page that aggregates existing provider data into three locally filtered result segments. Keep implementation localized to router, shared navigation, discover presentation, and a new search feature surface.

**Tech Stack:** Flutter, Riverpod, GoRouter, Flutter widget tests

---

### Task 1: Cover navigation and search behavior with tests

**Files:**
- Create: `test/router/app_router_test.dart`
- Create: `test/features/search/presentation/pages/search_page_test.dart`

- [ ] **Step 1: Write the failing tests**
- [ ] **Step 2: Run the targeted tests and confirm the failures are due to missing `/search` and old bottom-nav behavior**
- [ ] **Step 3: Implement the minimal routing and search UI changes**
- [ ] **Step 4: Re-run the targeted tests and confirm they pass**

### Task 2: Update shell navigation and home entry UI

**Files:**
- Modify: `lib/router/app_router.dart`
- Modify: `lib/shared/widgets/bottom_nav_bar.dart`
- Modify: `lib/features/discover/presentation/pages/discover_page.dart`

- [ ] **Step 1: Remove discover from bottom-nav items and adjust route matching**
- [ ] **Step 2: Convert the home search bar into a tappable route entry to `/search`**
- [ ] **Step 3: Keep the random button behavior intact**
- [ ] **Step 4: Verify the shell still opens on `/discover`**

### Task 3: Add the dedicated search page

**Files:**
- Create: `lib/features/search/presentation/pages/search_page.dart`

- [ ] **Step 1: Build the sticky search shell, segment control, and chip row**
- [ ] **Step 2: Load photo and collection data from existing providers**
- [ ] **Step 3: Derive unique users from photo results**
- [ ] **Step 4: Implement local filtering and per-segment result rendering**
- [ ] **Step 5: Add empty, loading, and inline error states**

### Task 4: Verify the delivered behavior

**Files:**
- Modify as needed from prior tasks only

- [ ] **Step 1: Run the targeted widget tests**
- [ ] **Step 2: Run the wider relevant Flutter test set**
- [ ] **Step 3: Fix any regressions without broad refactors**
