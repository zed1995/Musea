import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

void showCollectionDeleteSheet(
  BuildContext context, {
  required Collection collection,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => CollectionDeleteSheet(collection: collection),
  );
}

class CollectionDeleteSheet extends ConsumerStatefulWidget {
  const CollectionDeleteSheet({super.key, required this.collection});

  final Collection collection;

  @override
  ConsumerState<CollectionDeleteSheet> createState() =>
      _CollectionDeleteSheetState();
}

class _CollectionDeleteSheetState extends ConsumerState<CollectionDeleteSheet> {
  final TextEditingController _confirmController = TextEditingController();
  bool _isDeleting = false;

  String get _collectionTitle => widget.collection.title.toUpperCase();
  bool get _isConfirmed =>
      _confirmController.text.trim().toUpperCase() == _collectionTitle;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 54,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD4D4D8),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.deleteCollection,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.05,
                          color: Colors.red[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.deleteCollectionDesc,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: const Color(0xFF71717A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.willBeDeleted(widget.collection.title),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.photosRemainUnsplash,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.red[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE7E7EB)),
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A18181B),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.typeToConfirm,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: Color(0xFFA1A1AA),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.03,
                      color: Color(0xFF18181B),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: (_isConfirmed && !_isDeleting) ? _delete : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                         l10n.deleteCollectionAction,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  side: const BorderSide(color: Color(0xFFE4E4E7)),
                  foregroundColor: const Color(0xFF27272A),
                ),
                child: Text(
                  l10n.cancelAction,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    setState(() => _isDeleting = true);
    try {
      await ref.read(deleteCollectionProvider(widget.collection.id).future);
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }
}
