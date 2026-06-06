import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/auth/domain/entities/auth_user.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/profile/presentation/providers/profile_controller.dart';
import 'package:musea/features/search/presentation/providers/search_controller.dart';
import 'package:musea/l10n/generated/app_localizations.dart';
import 'package:musea/shared/widgets/collection_card.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/shared/widgets/photo_grid.dart';

class MinePage extends ConsumerStatefulWidget {
  const MinePage({super.key});

  @override
  ConsumerState<MinePage> createState() => _MinePageState();
}

class _MinePageState extends ConsumerState<MinePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).refreshIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    if (!authState.isAuthenticated) {
      return _SignedOutMineView(
        isAuthorizing: authState.isAuthorizing,
        errorMessage: authState.errorMessage,
        onSignIn: () => ref.read(authControllerProvider.notifier).beginSignIn(),
      );
    }

    final session = authState.session!;
    final user = session.user;
    final publicUser = User(
      id: user.id,
      username: user.username,
      name: user.displayName,
      firstName: user.firstName,
      lastName: user.lastName,
      bio: user.bio,
      location: user.location,
      portfolioUrl: user.portfolioUrl,
      instagramUsername: user.instagramUsername,
      twitterUsername: user.twitterUsername,
      profileImageSmall: user.profileImageSmall ?? user.profileImageMedium,
      profileImageMedium: user.profileImageMedium,
      profileImageLarge: user.profileImageLarge ?? user.profileImageMedium,
      totalPhotos: user.totalPhotos,
      totalLikes: user.totalLikes,
      totalCollections: user.totalCollections,
      downloads: user.downloads,
    );

    return _SignedInMineView(
      authUser: user,
      publicUser: publicUser,
      isRefreshing: authState.isRefreshing,
      errorMessage: authState.errorMessage,
      onRefresh: () => ref
          .read(authControllerProvider.notifier)
          .refreshIfNeeded(force: true),
    );
  }
}

enum _MineSegment { photos, collections, likes }

class _SignedOutMineView extends StatelessWidget {
  const _SignedOutMineView({
    required this.isAuthorizing,
    required this.errorMessage,
    required this.onSignIn,
  });

  final bool isAuthorizing;
  final String? errorMessage;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomScrollPadding = MediaQuery.paddingOf(context).bottom + 40;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            color: const Color(0xFFFCFCFD),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: _MineGuestTopBar(title: l10n.minePageTitle),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomScrollPadding),
              child: Column(
                children: [
                  _buildHeroContent(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 28),
                    child: Column(
                      children: [
                        _FeatureCard(
                          icon: Icons.favorite_border_rounded,
                          title: l10n.likedPhotos,
                          description: l10n.likedPhotosDesc,
                        ),
                        const SizedBox(height: 12),
                        _FeatureCard(
                          icon: Icons.bookmark_border_rounded,
                          title: l10n.savedCollections,
                          description: l10n.savedCollectionsDesc,
                        ),
                        const SizedBox(height: 12),
                        _FeatureCard(
                          icon: Icons.article_outlined,
                          title: l10n.personalSpace,
                          description: l10n.personalSpaceDesc,
                        ),
                        const SizedBox(height: 16),
                        _GuestModeSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFCFCFD),
            Color(0xFFF7F7F8),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F1F2)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
          child: Column(
            children: [
              _SignInCard(
                isAuthorizing: isAuthorizing,
                errorMessage: errorMessage,
                onSignIn: onSignIn,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(value: '0', label: l10n.photos),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(value: '0', label: l10n.collections),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(value: '0', label: l10n.likes),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionChip(
                      icon: Icons.home_outlined,
                      label: l10n.browseAsGuest,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionChip(
                      icon: Icons.visibility_outlined,
                      label: l10n.browseProfiles,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MineGuestTopBar extends StatelessWidget {
  const _MineGuestTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 30,
            height: 1,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
            color: Color(0xFF18181B),
          ),
        ),
        _GuestTopBarButton(),
      ],
    );
  }
}

class _GuestTopBarButton extends StatelessWidget {
  const _GuestTopBarButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECF0)),
      ),
        child: IconButton(
        onPressed: () => context.push('/settings'),
        icon:
            const Icon(
              Icons.settings_outlined,
              size: 18,
              color: Color(0xFF27272A),
            ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _SignInCard extends StatelessWidget {
  const _SignInCard({
    required this.isAuthorizing,
    required this.errorMessage,
    required this.onSignIn,
  });

  final bool isAuthorizing;
  final String? errorMessage;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.9),
        border: Border.all(color: const Color(0xFFF4F4F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.92),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          children: [
            const _BrandMark(),
            const SizedBox(height: 16),
            Text(
              l10n.signIn,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
                color: Color(0xFF71717A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.yourArchiveSynced,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                height: 1.02,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                color: Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                l10n.keepLikesSaves,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF71717A),
                ),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: isAuthorizing ? null : onSignIn,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 14,
                  shadowColor: Colors.black.withValues(alpha: 0.18),
                ),
                child: isAuthorizing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chevron_right_rounded, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n.continueWithUnsplash,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.weUseUnsplashAccount,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.25,
                color: Color(0xFF71717A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'M',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -2.08,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F1F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF3F3F46)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestModeSection extends StatelessWidget {
  const _GuestModeSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.guestMode,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: Color(0xFFA1A1AA),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.guestModeDesc,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.54,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.guestModeBody,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _GuestChip(label: l10n.guestChipDiscover)),
              const SizedBox(width: 8),
              Expanded(child: _GuestChip(label: l10n.guestChipSearch)),
              const SizedBox(width: 8),
              Expanded(child: _GuestChip(label: l10n.guestChipCollections)),
              const SizedBox(width: 8),
              Expanded(child: _GuestChip(label: l10n.guestChipProfiles)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuestChip extends StatelessWidget {
  const _GuestChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFEAEAF0)),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3F3F46),
          ),
        ),
      ),
    );
  }
}

class _SignedInMineView extends ConsumerStatefulWidget {
  const _SignedInMineView({
    required this.authUser,
    required this.publicUser,
    required this.isRefreshing,
    required this.errorMessage,
    required this.onRefresh,
  });

  final AuthUser authUser;
  final User publicUser;
  final bool isRefreshing;
  final String? errorMessage;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_SignedInMineView> createState() => _SignedInMineViewState();
}

class _SignedInMineViewState extends ConsumerState<_SignedInMineView> {
  _MineSegment _selectedSegment = _MineSegment.photos;
  final ScrollController _scrollController = ScrollController();

  String get _username => widget.authUser.username;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userPhotosControllerProvider(_username).notifier).loadInitial();
      ref
          .read(userCollectionsControllerProvider(_username).notifier)
          .loadInitial();
      ref.read(userLikesControllerProvider(_username).notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      switch (_selectedSegment) {
        case _MineSegment.photos:
          ref.read(userPhotosControllerProvider(_username).notifier).loadMore();
        case _MineSegment.collections:
          ref
              .read(userCollectionsControllerProvider(_username).notifier)
              .loadMore();
        case _MineSegment.likes:
          ref.read(userLikesControllerProvider(_username).notifier).loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: _MineHero(
                user: widget.authUser,
                isRefreshing: widget.isRefreshing,
              ),
            ),
            if (widget.errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Text(
                    widget.errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _MineSegmentHeaderDelegate(
                child: Container(
                  color: Colors.white.withValues(alpha: 0.96),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: _MineSegmentBar(
                    selectedSegment: _selectedSegment,
                    onSelected: (segment) {
                      setState(() => _selectedSegment = segment);
                    },
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
                child: _buildSelectedSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSection() {
    switch (_selectedSegment) {
      case _MineSegment.photos:
        final state = ref.watch(userPhotosControllerProvider(_username));
        return _MinePhotoSection(state: state);
      case _MineSegment.collections:
        final state = ref.watch(userCollectionsControllerProvider(_username));
        return _MineCollectionsSection(state: state);
      case _MineSegment.likes:
        final state = ref.watch(userLikesControllerProvider(_username));
        return _MinePhotoSection(state: state, showLikes: true);
    }
  }
}

class _MineHero extends StatelessWidget {
  const _MineHero({
    required this.user,
    required this.isRefreshing,
  });

  final AuthUser user;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtitleParts = [
      if ((user.location ?? '').trim().isNotEmpty) user.location!.trim(),
      l10n.personalWorkspaceSubtitle,
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFCFCFD),
            Color(0xFFF7F7F8),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F1F2)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.minePageTitle,
                    style: const TextStyle(
                      fontSize: 30,
                      height: 1,
                      letterSpacing: -1.2,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TopBarIconButton(
                        icon: Icons.edit_outlined,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      _TopBarIconButton(
                        icon: Icons.settings_outlined,
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AvatarImage(
                    imageUrl: user.profileImageMedium,
                    size: 76,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontSize: 22,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.9,
                            color: Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '@${user.username}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF52525B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitleParts.join(' · '),
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      value: '${user.totalPhotos}',
                      label: l10n.photos,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      value: '${user.totalCollections}',
                      label: l10n.collections,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      value: _formatCount(user.totalLikes),
                      label: l10n.likes,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                isRefreshing
                    ? l10n.syncingLatestProfile
                    : l10n.showingCachedProfile,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFA1A1AA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MinePhotoSection extends StatelessWidget {
  const _MinePhotoSection({
    required this.state,
    this.showLikes = false,
  });

  final PaginatedState<Photo> state;
  final bool showLikes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: LoadingIndicator()),
      );
    }
    if (state.items.isEmpty && state.error != null) {
      return ErrorState(message: state.error.toString());
    }
    if (state.items.isEmpty && state.error == null) {
      return _SectionEmptyCard(
        message: showLikes ? l10n.noLikedPhotosYet : l10n.nothingHereYet,
      );
    }

    return Column(
      children: [
        PhotoGrid(photos: state.items, showLikes: showLikes),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LoadingIndicator(),
          ),
      ],
    );
  }
}

class _MineCollectionsSection extends StatelessWidget {
  const _MineCollectionsSection({
    required this.state,
  });

  final PaginatedState<Collection> state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: LoadingIndicator()),
      );
    }
    if (state.items.isEmpty && state.error != null) {
      return ErrorState(message: state.error.toString());
    }
    if (state.items.isEmpty && state.error == null) {
      return _SectionEmptyCard(message: l10n.noCollectionsYet);
    }

    return Column(
      children: [
        ...state.items.map((collection) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CollectionCard(collection: collection),
            )),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LoadingIndicator(),
          ),
      ],
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFECECF0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF27272A)),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF4F4F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: Color(0xFFA1A1AA),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final text = Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF18181B),
            ),
          );

          return Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFEAEAF0)),
            ),
            child: constraints.maxWidth.isFinite
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 16, color: const Color(0xFF18181B)),
                      const SizedBox(width: 6),
                      Expanded(child: text),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 16, color: const Color(0xFF18181B)),
                      const SizedBox(width: 6),
                      text,
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _MineSegmentBar extends StatelessWidget {
  const _MineSegmentBar({
    required this.selectedSegment,
    required this.onSelected,
  });

  final _MineSegment selectedSegment;
  final ValueChanged<_MineSegment> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: l10n.photos,
              selected: selectedSegment == _MineSegment.photos,
              onTap: () => onSelected(_MineSegment.photos),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: l10n.collections,
              selected: selectedSegment == _MineSegment.collections,
              onTap: () => onSelected(_MineSegment.collections),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: l10n.likes,
              selected: selectedSegment == _MineSegment.likes,
              onTap: () => onSelected(_MineSegment.likes),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF18181B) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF71717A),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MineSegmentHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _MineSegmentHeaderDelegate({required this.child});

  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 58;

  @override
  double get minExtent => 58;

  @override
  bool shouldRebuild(covariant _MineSegmentHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.imageUrl,
    required this.size,
  });

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => Container(
          width: size,
          height: size,
          color: AppColors.gray100,
          child: const Icon(Icons.person_outline_rounded),
        ),
      ),
    );
  }
}

class _SectionEmptyCard extends StatelessWidget {
  const _SectionEmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF71717A),
          fontSize: 14,
        ),
      ),
    );
  }
}

String _formatCount(int count) {
  if (count >= 1000000) {
    return '${(count / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
  }
  if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(count >= 10000 ? 0 : 1).replaceAll('.0', '')}k';
  }
  return '$count';
}
