import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/services/download_notifier.dart';
import 'package:musea/core/services/providers.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';

class DownloadOption {
  const DownloadOption({
    required this.label,
    required this.callToActionLabel,
    required this.description,
    required this.url,
  });

  final String label;
  final String callToActionLabel;
  final String description;
  final String url;
}

List<DownloadOption> buildDownloadOptions(Photo photo) {
  return [
    DownloadOption(
      label: 'Small',
      callToActionLabel: 'Download Small',
      description: 'Fast to save and easy to share.',
      url: photo.urlSmall,
    ),
    DownloadOption(
      label: 'Regular',
      callToActionLabel: 'Download Regular',
      description: 'A balanced choice for most screens and posts.',
      url: photo.urlRegular,
    ),
    DownloadOption(
      label: 'Full',
      callToActionLabel: 'Download Full',
      description: 'Sharper and more detailed for larger displays.',
      url: photo.urlFull,
    ),
    DownloadOption(
      label: 'Original',
      callToActionLabel: 'Download Original',
      description: 'The largest available version with the most flexibility.',
      url: photo.urlRaw,
    ),
  ];
}

class DownloadSheet extends ConsumerStatefulWidget {
  const DownloadSheet({super.key, required this.photo});

  final Photo photo;

  static Future<void> show(BuildContext context, Photo photo) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DownloadSheet(photo: photo),
    );
  }

  @override
  ConsumerState<DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends ConsumerState<DownloadSheet> {
  late final List<DownloadOption> _options = buildDownloadOptions(widget.photo);
  int _selectedIndex = 1;
  bool _startedDownload = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(downloadNotifierProvider, (previous, next) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;

      if (previous?.state.isCompleted != true && next.state.isCompleted) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Image saved to gallery')),
          );
      }

      if (previous?.state.isFailed != true && next.state.isFailed) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Download failed')),
          );
      }
    });

    final notifier = ref.watch(downloadNotifierProvider);
    final showProgress = _startedDownload || !notifier.state.isIdle;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final bottomPadding =
        (viewInsets.bottom > viewPadding.bottom
                ? viewInsets.bottom
                : viewPadding.bottom) +
            18;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: showProgress
              ? _ProgressView(
                  notifier: notifier,
                  onClose: () => Navigator.of(context).pop(),
                  onRetry: () {
                    notifier.reset();
                    setState(() => _startedDownload = false);
                  },
                )
              : _SelectionView(
                  options: _options,
                  selectedIndex: _selectedIndex,
                  onSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  onDismiss: () => Navigator.of(context).pop(),
                  onDownload: () {
                    setState(() => _startedDownload = true);
                    notifier.download(
                      _options[_selectedIndex].url,
                      widget.photo,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _SelectionView extends StatelessWidget {
  const _SelectionView({
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    required this.onDismiss,
    required this.onDownload,
  });

  final List<DownloadOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onDismiss;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final selectedOption = options[selectedIndex];

    return Column(
      key: const ValueKey('selection'),
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
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                'Choose the size that works best for where you want to use this photo.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF52525B),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onDismiss,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F4F5),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFF71717A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final entry in options.asMap().entries)
          _OptionTile(
            option: entry.value,
            selected: entry.key == selectedIndex,
            onTap: () => onSelected(entry.key),
          ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gray900,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: onDownload,
            child: Text(
              selectedOption.callToActionLabel,
              style: const TextStyle(
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

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final DownloadOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFF4F4F5)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(minWidth: 62),
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.gray900 : const Color(0xFFF6F6F7),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                option.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF27272A),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    option.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: selected
                          ? const Color(0xFF18181B)
                          : const Color(0xFF52525B),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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

class _ProgressView extends StatelessWidget {
  const _ProgressView({
    required this.notifier,
    required this.onClose,
    required this.onRetry,
  });

  final DownloadNotifier notifier;
  final VoidCallback onClose;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final state = notifier.state;
    final actionLabel = switch (state.status) {
      DownloadStatus.completed => 'Done',
      DownloadStatus.failed => 'Back to Sizes',
      _ => 'Download in Background',
    };

    return Column(
      key: const ValueKey('progress'),
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
        const SizedBox(height: 18),
        const Text(
          'Download Progress',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _progressSubtitle(state),
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF52525B),
          ),
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: state.isFailed ? 0 : (state.progress > 0 ? state.progress : null),
            minHeight: 8,
            backgroundColor: const Color(0xFFF4F4F5),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gray900),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              state.statusText,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF27272A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              _progressMeta(state),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF71717A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gray900,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              if (state.isFailed) {
                onRetry();
                return;
              }
              onClose();
            },
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _progressSubtitle(DownloadProgress state) {
    if (state.isCompleted) {
      return 'Your photo has been saved and is ready in the gallery.';
    }
    if (state.isFailed) {
      return 'Something went wrong while saving this image.';
    }
    if (state.isSaving) {
      return 'Almost there. We are moving the file into your gallery now.';
    }
    return 'You can keep browsing while the download continues in the background.';
  }

  String _progressMeta(DownloadProgress state) {
    if (state.isCompleted) return '100%';
    if (state.isFailed) return '0%';
    if (state.totalBytes > 0) {
      return '${_formatBytes(state.receivedBytes)} / ${_formatBytes(state.totalBytes)}';
    }
    return '${(state.progress * 100).round()}%';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex += 1;
    }
    final formatted = value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    return '$formatted ${units[unitIndex]}';
  }
}
