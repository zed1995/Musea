import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/auth/domain/entities/auth_user.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';

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
    final photosAsync = ref.watch(userPhotosProvider(user.username));
    final collectionsAsync = ref.watch(userCollectionsProvider(user.username));
    final likesAsync = ref.watch(userLikesProvider(user.username));

    return _SignedInMineView(
      user: user,
      isRefreshing: authState.isRefreshing,
      errorMessage: authState.errorMessage,
      photosAsync: photosAsync,
      collectionsAsync: collectionsAsync,
      likesAsync: likesAsync,
      onRefresh: () => ref
          .read(authControllerProvider.notifier)
          .refreshIfNeeded(force: true),
      onSignOut: () => ref.read(authControllerProvider.notifier).signOut(),
    );
  }
}

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F5F0),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              const _MineHeader(title: 'Mine'),
              const SizedBox(height: 28),
              const Text(
                'Your visual archive, synced with Unsplash',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF18181B),
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sign in once to keep your likes, collections, and future personal surfaces connected across devices.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF52525B),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Continue with Unsplash',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We use your Unsplash account to sync your activity and load your personal profile in Musea.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF71717A),
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isAuthorizing ? null : onSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF18181B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                            : const Text('Continue with Unsplash'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _BenefitsCard(),
              const SizedBox(height: 18),
              const _GuestCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignedInMineView extends StatelessWidget {
  const _SignedInMineView({
    required this.user,
    required this.isRefreshing,
    required this.errorMessage,
    required this.photosAsync,
    required this.collectionsAsync,
    required this.likesAsync,
    required this.onRefresh,
    required this.onSignOut,
  });

  final AuthUser user;
  final bool isRefreshing;
  final String? errorMessage;
  final AsyncValue<List<Photo>> photosAsync;
  final AsyncValue<List<Collection>> collectionsAsync;
  final AsyncValue<List<Photo>> likesAsync;
  final VoidCallback onRefresh;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              _MineHeader(
                title: 'Mine',
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'sign_out') {
                      onSignOut();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'sign_out',
                      child: Text('Sign out'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _MineProfileHero(user: user, isRefreshing: isRefreshing),
              if (errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _MineStatsRow(user: user),
              const SizedBox(height: 18),
              _MineSection(
                title: 'Latest uploads',
                child: _PhotoGrid(asyncPhotos: photosAsync),
              ),
              const SizedBox(height: 18),
              _MineSection(
                title: 'Liked photos',
                child: _PhotoGrid(asyncPhotos: likesAsync),
              ),
              const SizedBox(height: 18),
              _MineSection(
                title: 'Collections',
                child: _CollectionsList(asyncCollections: collectionsAsync),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MineHeader extends StatelessWidget {
  const _MineHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF18181B),
          ),
        ),
        trailing ??
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF4F4F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 20,
                color: Color(0xFF3F3F46),
              ),
            ),
      ],
    );
  }
}

class _MineProfileHero extends StatelessWidget {
  const _MineProfileHero({
    required this.user,
    required this.isRefreshing,
  });

  final AuthUser user;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF18181B),
            Color(0xFF3F3F46),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                backgroundImage: user.profileImageMedium.isNotEmpty
                    ? CachedNetworkImageProvider(user.profileImageMedium)
                    : null,
                child: user.profileImageMedium.isEmpty
                    ? Text(
                        user.displayName.isEmpty
                            ? '?'
                            : user.displayName.characters.first,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((user.bio ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              user.bio!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
          if ((user.location ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              user.location!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.76),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            isRefreshing
                ? 'Syncing latest profile...'
                : 'Showing your cached profile first.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MineStatsRow extends StatelessWidget {
  const _MineStatsRow({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatCard(label: 'Photos', value: '${user.totalPhotos}')),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Likes', value: '${user.totalLikes}')),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Collections',
            value: '${user.totalCollections}',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF18181B),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF71717A),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MineSection extends StatelessWidget {
  const _MineSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF18181B),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.asyncPhotos});

  final AsyncValue<List<Photo>> asyncPhotos;

  @override
  Widget build(BuildContext context) {
    return asyncPhotos.when(
      data: (photos) {
        if (photos.isEmpty) {
          return const Text(
            'Nothing here yet.',
            style: TextStyle(color: Color(0xFF71717A)),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: photos.length.clamp(0, 4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final photo = photos[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CachedNetworkImage(
                imageUrl: photo.urlSmall,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: AppColors.gray100,
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => ErrorState(message: error.toString()),
    );
  }
}

class _CollectionsList extends StatelessWidget {
  const _CollectionsList({required this.asyncCollections});

  final AsyncValue<List<Collection>> asyncCollections;

  @override
  Widget build(BuildContext context) {
    return asyncCollections.when(
      data: (collections) {
        if (collections.isEmpty) {
          return const Text(
            'No collections yet.',
            style: TextStyle(color: Color(0xFF71717A)),
          );
        }

        return Column(
          children: collections.take(3).map((collection) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${collection.totalPhotos} photos',
                      style: const TextStyle(
                        color: Color(0xFF71717A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => ErrorState(message: error.toString()),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What you unlock',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF18181B),
            ),
          ),
          SizedBox(height: 16),
          _BenefitRow(
            title: 'Liked photos',
            body: 'Revisit favorites you saved on Unsplash.',
          ),
          SizedBox(height: 12),
          _BenefitRow(
            title: 'Saved collections',
            body: 'Keep inspiration grouped and easy to return to.',
          ),
          SizedBox(height: 12),
          _BenefitRow(
            title: 'Personal space',
            body: 'See your profile surface update from local cache first.',
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.auto_awesome,
            size: 16,
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
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF71717A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E4E7)),
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
            'Discover, search, collections, and public profiles stay available even before you sign in.',
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
