import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';

class CollectionRemovePhotosPage extends ConsumerStatefulWidget {
  const CollectionRemovePhotosPage({
    super.key,
    required this.collectionId,
    required this.collectionTitle,
  });

  final String collectionId;
  final String collectionTitle;

  @override
  ConsumerState<CollectionRemovePhotosPage> createState() =>
      _CollectionRemovePhotosPageState();
}

class _CollectionRemovePhotosPageState
    extends ConsumerState<CollectionRemovePhotosPage> {
  final Set<String> _selectedIds = {};
  bool _isRemoving = false;

  void _toggleSelection(String photoId) {
    setState(() {
      if (_selectedIds.contains(photoId)) {
        _selectedIds.remove(photoId);
      } else {
        _selectedIds.add(photoId);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _removeSelected() async {
    setState(() => _isRemoving = true);
    try {
      for (final photoId in _selectedIds) {
        await ref.read(removePhotoFromCollectionProvider((
          collectionId: widget.collectionId,
          photoId: photoId,
        )).future);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove photos: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRemoving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(collectionPhotosProvider(widget.collectionId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Batch Mode',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.grey[400],
              ),
            ),
            Text(
              'Remove photos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _clearSelection,
              child: Text(
                'Done',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
      body: photosAsync.when(
        data: (photos) => Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFF4F4F5)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A18181B),
                              blurRadius: 30,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select multiple photos to remove them from this collection. '
                              'Photos stay available on Unsplash.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Text(
                            'Selection',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Colors.grey[400],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF18181B),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_selectedIds.length} selected',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final photo = photos[index];
                          final isSelected =
                              _selectedIds.contains(photo.id);
                          return GestureDetector(
                            key: ValueKey('photo_tile_${photo.id}'),
                            onTap: () => _toggleSelection(photo.id),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.network(
                                    photo.urlSmall,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      color: Colors.grey[200],
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.22),
                                        borderRadius:
                                            BorderRadius.circular(18),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? const Color(0xFF18181B)
                                          : Colors.black
                                              .withValues(alpha: 0.64),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.14),
                                      ),
                                    ),
                                    child: Center(
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                          : const Text(
                                              '○',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: photos.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_selectedIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      '${_selectedIds.length} photos will be removed from '
                      '${widget.collectionTitle}. '
                      'This does not delete the original photos.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _isRemoving ? null : _removeSelected,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF18181B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isRemoving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Remove ${_selectedIds.length} photos',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('Failed to load photos: $error'),
        ),
      ),
    );
  }
}
