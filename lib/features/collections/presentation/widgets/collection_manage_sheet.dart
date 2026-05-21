import 'package:flutter/material.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';

void showCollectionManageSheet(
  BuildContext context, {
  required Collection collection,
  required VoidCallback onEdit,
  required VoidCallback onRemovePhotos,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => CollectionManageSheet(
      collection: collection,
      onEdit: onEdit,
      onRemovePhotos: onRemovePhotos,
      onDelete: onDelete,
    ),
  );
}

class CollectionManageSheet extends StatelessWidget {
  const CollectionManageSheet({
    super.key,
    required this.collection,
    required this.onEdit,
    required this.onRemovePhotos,
    required this.onDelete,
  });

  final Collection collection;
  final VoidCallback onEdit;
  final VoidCallback onRemovePhotos;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
                      const Text(
                        'Manage collection',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.05,
                          color: Color(0xFF09090B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Update the collection, clean up saved photos, or delete it safely.',
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
                  width: 36,
                  height: 36,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF4F4F5),
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
            child: Column(
              children: [
                _MenuRow(
                  icon: Icons.edit_outlined,
                  iconBackground: const Color(0xFF18181B),
                  title: 'Edit details',
                  subtitle: 'Title, description, and visibility',
                  onTap: () {
                    Navigator.of(context).pop();
                    onEdit();
                  },
                ),
                const SizedBox(height: 12),
                _MenuRow(
                  icon: Icons.delete_outline_rounded,
                  iconBackground: const Color(0xFF3F3F46),
                  title: 'Remove photos',
                  subtitle: 'Enter multi-select mode for this collection',
                  onTap: () {
                    Navigator.of(context).pop();
                    onRemovePhotos();
                  },
                ),
                const SizedBox(height: 12),
                _MenuRow(
                  icon: Icons.delete_forever_outlined,
                  iconBackground: const Color(0xFFDC2626),
                  title: 'Delete collection',
                  subtitle: 'Permanent action with confirmation',
                  titleColor: const Color(0xFFDC2626),
                  subtitleColor: const Color(0xFFFCA5A5),
                  chevronColor: const Color(0xFFFCA5A5),
                  onTap: () {
                    Navigator.of(context).pop();
                    onDelete();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
    this.subtitleColor,
    this.chevronColor,
  });

  final IconData icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? subtitleColor;
  final Color? chevronColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: const Color(0xFFF0F0F2)),
          ),
          backgroundColor: const Color(0xFFF0F0F2).withValues(alpha: 0.02),
          foregroundColor: Colors.black,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? const Color(0xFF09090B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor ?? Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: chevronColor ?? Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
