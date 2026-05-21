import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/auth/domain/entities/auth_user.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
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
      photosAsync: ref.watch(userPhotosProvider(user.username)),
      collectionsAsync: ref.watch(userCollectionsProvider(user.username)),
      likesAsync: ref.watch(userLikesProvider(user.username)),
      onRefresh: () => ref
          .read(authControllerProvider.notifier)
          .refreshIfNeeded(force: true),
      onSignOut: () => ref.read(authControllerProvider.notifier).signOut(),
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
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
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SignedOutTopBar(),
                      const SizedBox(height: 18),
                      _SignedOutSheet(
                        isAuthorizing: isAuthorizing,
                        errorMessage: errorMessage,
                        onSignIn: onSignIn,
                      ),
                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          Expanded(
                            child: _MetricCard(value: '0', label: 'Photos'),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _MetricCard(
                              value: '0',
                              label: 'Collections',
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _MetricCard(value: '0', label: 'Likes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 18, 12, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why sign in',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  SizedBox(height: 12),
                  _BenefitCard(
                    title: 'Liked photos',
                    body:
                        'Revisit favorites you save and keep your archive in sync with Unsplash.',
                  ),
                  SizedBox(height: 10),
                  _BenefitCard(
                    title: 'Saved collections',
                    body:
                        'Keep inspiration grouped in the same workspace you already browse from.',
                  ),
                  SizedBox(height: 10),
                  _BenefitCard(
                    title: 'Personal space',
                    body:
                        'Unlock a calmer home for your uploads, preferences, and future tools.',
                  ),
                  SizedBox(height: 20),
                  _SignedOutGuestCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedOutTopBar extends StatelessWidget {
  const _SignedOutTopBar();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workspace',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
                color: Color(0xFFA1A1AA),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Mine',
              style: TextStyle(
                fontSize: 30,
                height: 1,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.2,
                color: Color(0xFF18181B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SignedOutSheet extends StatelessWidget {
  const _SignedOutSheet({
    required this.isAuthorizing,
    required this.errorMessage,
    required this.onSignIn,
  });

  final bool isAuthorizing;
  final String? errorMessage;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFFFCFBF9),
          ],
        ),
        border: Border.all(color: const Color(0xFFF1ECE5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BrandOrb(),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          color: Color(0xFF71717A),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your visual archive, synced with Unsplash',
                        style: TextStyle(
                          fontSize: 28,
                          height: 1.04,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.1,
                          color: Color(0xFF18181B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Keep every like, save, and future personal surface connected to the photos you care about.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF52525B),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                errorMessage!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isAuthorizing ? null : onSignIn,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
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
                    : const Text(
                        'Continue with Unsplash',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'We use your Unsplash account to sync likes, saves, and your personal archive.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF71717A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedOutGuestCard extends StatelessWidget {
  const _SignedOutGuestCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0EE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You can keep exploring as a guest',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF18181B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Discover, search, browse collections, and open public profiles without signing in. Mine becomes your personal home when you are ready.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF71717A),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandOrb extends StatelessWidget {
  const _BrandOrb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [
            Colors.white,
            Color(0xFFF8F4EE),
            Color(0xFFEAD8C2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        size: 26,
        color: Color(0xFF18181B),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFE9E1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F0E7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
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
    );
  }
}

class _SignedInMineView extends StatefulWidget {
  const _SignedInMineView({
    required this.authUser,
    required this.publicUser,
    required this.isRefreshing,
    required this.errorMessage,
    required this.photosAsync,
    required this.collectionsAsync,
    required this.likesAsync,
    required this.onRefresh,
    required this.onSignOut,
  });

  final AuthUser authUser;
  final User publicUser;
  final bool isRefreshing;
  final String? errorMessage;
  final AsyncValue<List<Photo>> photosAsync;
  final AsyncValue<List<Collection>> collectionsAsync;
  final AsyncValue<List<Photo>> likesAsync;
  final Future<void> Function() onRefresh;
  final VoidCallback onSignOut;

  @override
  State<_SignedInMineView> createState() => _SignedInMineViewState();
}

class _SignedInMineViewState extends State<_SignedInMineView> {
  _MineSegment _selectedSegment = _MineSegment.photos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _MineHero(
                user: widget.authUser,
                isRefreshing: widget.isRefreshing,
                onSignOut: widget.onSignOut,
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
                child: _buildSelectedSection(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSection(BuildContext context) {
    switch (_selectedSegment) {
      case _MineSegment.photos:
        return _MinePhotoSection(
          title: 'Latest uploads',
          photosAsync: widget.photosAsync,
        );
      case _MineSegment.collections:
        return _MineCollectionsSection(
          collectionsAsync: widget.collectionsAsync,
        );
      case _MineSegment.likes:
        return _MinePhotoSection(
          title: 'Liked photos',
          photosAsync: widget.likesAsync,
          showLikes: true,
        );
    }
  }
}

class _MineHero extends StatelessWidget {
  const _MineHero({
    required this.user,
    required this.isRefreshing,
    required this.onSignOut,
  });

  final AuthUser user;
  final bool isRefreshing;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = [
      if ((user.location ?? '').trim().isNotEmpty) user.location!.trim(),
      'Personal workspace for photos, collections, and saved inspiration.',
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workspace',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFA1A1AA),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Mine',
                        style: TextStyle(
                          fontSize: 30,
                          height: 1,
                          letterSpacing: -1.2,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF18181B),
                        ),
                      ),
                    ],
                  ),
                  _TopBarIconButton(
                    icon: Icons.more_horiz_rounded,
                    onTap: () => _showMineActions(context, onSignOut),
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
                      label: 'Photos',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      value: '${user.totalCollections}',
                      label: 'Collections',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      value: _formatCount(user.totalLikes),
                      label: 'Likes',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickActionChip(
                      icon: Icons.edit_outlined,
                      label: 'Edit profile',
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    _QuickActionChip(
                      icon: Icons.bookmark_border_rounded,
                      label: 'Saved',
                      onTap: () {
                        DefaultTabController.of(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    _QuickActionChip(
                      icon: Icons.download_outlined,
                      label: 'Downloads',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isRefreshing
                    ? 'Syncing latest profile...'
                    : 'Showing your cached profile first.',
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

  Future<void> _showMineActions(
    BuildContext context,
    VoidCallback onSignOut,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4D4D8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Sign out'),
                  onTap: () {
                    Navigator.of(context).pop();
                    onSignOut();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MinePhotoSection extends StatelessWidget {
  const _MinePhotoSection({
    required this.title,
    required this.photosAsync,
    this.showLikes = false,
  });

  final String title;
  final AsyncValue<List<Photo>> photosAsync;
  final bool showLikes;

  @override
  Widget build(BuildContext context) {
    return photosAsync.when(
      data: (photos) {
        if (photos.isEmpty) {
          return _SectionEmptyCard(
            message: showLikes ? 'No liked photos yet.' : 'Nothing here yet.',
          );
        }

        return PhotoGrid(
          photos: photos,
          showLikes: showLikes,
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: LoadingIndicator()),
      ),
      error: (error, stack) => ErrorState(message: error.toString()),
    );
  }
}

class _MineCollectionsSection extends StatelessWidget {
  const _MineCollectionsSection({
    required this.collectionsAsync,
  });

  final AsyncValue<List<Collection>> collectionsAsync;

  @override
  Widget build(BuildContext context) {
    return collectionsAsync.when(
      data: (collections) {
        if (collections.isEmpty) {
          return const _SectionEmptyCard(message: 'No collections yet.');
        }

        return Column(
          children: collections.map((collection) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CollectionCard(collection: collection),
            );
          }).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: LoadingIndicator()),
      ),
      error: (error, stack) => ErrorState(message: error.toString()),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
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
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFEAEAF0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF18181B)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF18181B),
              ),
            ),
          ],
        ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Photos',
              selected: selectedSegment == _MineSegment.photos,
              onTap: () => onSelected(_MineSegment.photos),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'Collections',
              selected: selectedSegment == _MineSegment.collections,
              onTap: () => onSelected(_MineSegment.collections),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'Likes',
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
