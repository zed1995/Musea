import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

Future<void> showSaveToCollectionSheet(
  BuildContext context, {
  required String photoId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _SaveToCollectionSheet(photoId: photoId),
  );
}

class _SaveToCollectionSheet extends ConsumerStatefulWidget {
  const _SaveToCollectionSheet({required this.photoId});

  final String photoId;

  @override
  ConsumerState<_SaveToCollectionSheet> createState() =>
      _SaveToCollectionSheetState();
}

class _SaveToCollectionSheetState
    extends ConsumerState<_SaveToCollectionSheet> {
  bool _isCreateMode = false;
  List<Collection> _collections = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _saveErrorMessage;

  // Create form
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPrivate = true;
  bool _isSubmitting = false;
  String? _createErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCollections());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authState = ref.read(authControllerProvider);
      final username = authState.session?.user.username;
      if (username == null || username.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = '${l10n.couldNotIdentifyUser} ${l10n.signInAgain}';
        });
        return;
      }

      final repository = ref.read(collectionRepositoryProvider);
      final result = await repository.getUserCollections(
        username,
        page: 1,
        perPage: 50,
      );
      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.when(
              network: (m) => l10n.networkError(m),
              server: (_, m) => l10n.serverError(m),
              cache: (m) => 'Error: $m',
              notFound: (m) => 'Error: $m',
              unauthorized: (_) => l10n.signInAgain,
              rateLimit: (_) => l10n.tooManyRequests,
              unknown: (m) => 'Error: $m',
            );
          });
        },
        (collections) {
          setState(() {
            _isLoading = false;
            _collections = collections;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _addPhotoToCollection(Collection collection) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isSubmitting = true;
      _saveErrorMessage = null;
    });

    try {
      final repository = ref.read(collectionRepositoryProvider);
      final result = await repository.addPhotoToCollection(
        collectionId: collection.id,
        photoId: widget.photoId,
      );

      result.fold(
        (failure) {
          final message = failure.when(
            network: (m) => l10n.networkError(m),
            server: (code, m) => code == 409
                ? l10n.photoAlreadyInCollection
                : l10n.serverError(m),
            cache: (m) => 'Error: $m',
            notFound: (m) => 'Error: $m',
            unauthorized: (_) => l10n.signInAgain,
            rateLimit: (_) => l10n.tooManyRequests,
            unknown: (m) => 'Error: $m',
          );
          setState(() {
            _isSubmitting = false;
            _saveErrorMessage = message;
          });
        },
        (_) {
          final messenger = ScaffoldMessenger.of(context);
          final router = GoRouter.of(context);
          Navigator.of(context).pop();

          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.savedTo(collection.title)),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: l10n.view,
                onPressed: () =>
                    router.push('/collection/${collection.id}'),
              ),
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _saveErrorMessage = e.toString();
      });
    }
  }

  Future<void> _handleCreateCollection() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isSubmitting = true;
      _createErrorMessage = null;
    });

    try {
      final repository = ref.read(collectionRepositoryProvider);
      final result = await repository.createCollection(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        private: _isPrivate,
      );

      result.fold(
        (failure) {
          setState(() {
            _isSubmitting = false;
            _createErrorMessage = failure.when(
              network: (m) => l10n.networkError(m),
              server: (_, m) => l10n.serverError(m),
              cache: (m) => 'Error: $m',
              notFound: (m) => 'Error: $m',
              unauthorized: (_) => l10n.signInAgain,
              rateLimit: (_) => l10n.tooManyRequests,
              unknown: (m) => 'Error: $m',
            );
          });
        },
        (collection) {
          setState(() {
            _isCreateMode = false;
            _isSubmitting = false;
            _collections.insert(0, collection);
            _titleController.clear();
            _descriptionController.clear();
            _isPrivate = true;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _createErrorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          MediaQuery.viewPaddingOf(context).bottom + 8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4D4D8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isCreateMode) _buildCreateView() else _buildSelectView(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectView() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.selectCollection,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.15,
                      color: Color(0xFF09090B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.savePhotoToCollection,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Color(0xFF71717A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _isCreateMode = true),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFECECF0)),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.createNewCollection,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.noPerfectFitYet,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.myCollections,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
                color: Colors.grey[400],
              ),
            ),
            Text(
              '${_collections.length} collections',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_errorMessage != null)
          _ErrorRetry(message: _errorMessage!, onRetry: _loadCollections)
        else if (_collections.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                l10n.noCollectionsYet,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _collections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final collection = _collections[index];
                return _CollectionItem(
                  collection: collection,
                  onTap: _isSubmitting
                      ? null
                      : () => _addPhotoToCollection(collection),
                );
              },
            ),
          ),
        if (!_isLoading && _saveErrorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _saveErrorMessage!,
            style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
          ),
        ],
      ],
    );
  }

  Widget _buildCreateView() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isCreateMode = false),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.backToCollections,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.newCollection,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.newCollectionDesc,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Color(0xFF71717A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.collectionName,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: Color(0xFFA1A1AA),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _titleController,
          maxLength: 60,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: l10n.enterName,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF18181B)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            counterStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.descriptionOptional,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: Color(0xFFA1A1AA),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.addDescription,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF18181B)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.visibility,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: Color(0xFFA1A1AA),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _VisibilityOption(
                label: l10n.privateCollection,
                description: l10n.onlyYouCanSee,
                isSelected: _isPrivate,
                onTap: () => setState(() => _isPrivate = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _VisibilityOption(
                label: l10n.publicCollection,
                description: l10n.visibleOnProfile,
                isSelected: !_isPrivate,
                onTap: () => setState(() => _isPrivate = false),
              ),
            ),
          ],
        ),
        if (_createErrorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _createErrorMessage!,
            style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C)),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _titleController.text.trim().isEmpty || _isSubmitting
                ? null
                : _handleCreateCollection,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    l10n.createCollection,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _CollectionItem extends StatelessWidget {
  const _CollectionItem({
    required this.collection,
    this.onTap,
  });

  final Collection collection;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          color: Colors.white.withValues(alpha: 0.94),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF4F4F5),
              ),
              child: collection.coverPhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        collection.coverPhoto!.urlSmall,
                        fit: BoxFit.cover,
                        width: 54,
                        height: 54,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    )
                  : const SizedBox(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF18181B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.photoCount(collection.totalPhotos),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (collection.isPrivate)
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    l10n.private,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF52525B),
                    ),
                  ),
                ),
              ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  const _VisibilityOption({
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF18181B)
              : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF18181B)
                : const Color(0xFFF1F1F3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.white : const Color(0xFFA1A1AA),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF18181B),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: isSelected
                          ? Colors.white70
                          : const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
