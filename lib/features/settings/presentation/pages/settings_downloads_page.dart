import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/services/download_notifier.dart';
import 'package:musea/core/services/providers.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

class SettingsDownloadsPage extends ConsumerWidget {
  const SettingsDownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.watch(downloadNotifierProvider);
    final tasks = notifier.tasks;
    final downloading = tasks
        .where((task) => task.status == DownloadTaskStatus.downloading)
        .toList();
    final completed = tasks
        .where((task) => task.status == DownloadTaskStatus.completed)
        .toList();
    final failed = tasks
        .where((task) => task.status == DownloadTaskStatus.failed)
        .toList();

    void showMessage(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    Widget buildSection(String title, List<DownloadTask> items) {
      if (items.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.gray400,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SwipeToRevealDelete(
                deleteKey: ValueKey('delete-task-${task.id}'),
                enabled: task.status != DownloadTaskStatus.downloading,
                onDelete: task.status == DownloadTaskStatus.downloading
                    ? null
                    : () {
                        ref.read(downloadNotifierProvider).removeTask(task.id);
                        showMessage(l10n.downloadTaskRemoved);
                      },
                child: _DownloadTaskTile(
                  task: task,
                  onRetry: task.status == DownloadTaskStatus.failed
                      ? () => ref.read(downloadNotifierProvider).retryTask(task)
                      : null,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.gray50,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.downloadsPageTitle),
        actions: [
          if (completed.isNotEmpty || failed.isNotEmpty)
            PopupMenuButton<_DownloadsMenuAction>(
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (value) {
                switch (value) {
                  case _DownloadsMenuAction.clearCompleted:
                    ref.read(downloadNotifierProvider).clearCompleted();
                    showMessage(l10n.completedTasksCleared);
                  case _DownloadsMenuAction.clearFailed:
                    ref.read(downloadNotifierProvider).clearFailed();
                    showMessage(l10n.failedTasksCleared);
                }
              },
              itemBuilder: (context) => [
                if (completed.isNotEmpty)
                  PopupMenuItem<_DownloadsMenuAction>(
                    value: _DownloadsMenuAction.clearCompleted,
                    child: Text(l10n.clearCompletedAction),
                  ),
                if (failed.isNotEmpty)
                  PopupMenuItem<_DownloadsMenuAction>(
                    value: _DownloadsMenuAction.clearFailed,
                    child: Text(l10n.clearFailedAction),
                  ),
              ],
            ),
        ],
      ),
      body: tasks.isEmpty
          ? _DownloadsEmptyState(label: l10n.noDownloadsYet)
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _DownloadsHint(label: l10n.downloadRecordsOnlyHint),
                const SizedBox(height: 16),
                buildSection(l10n.downloadingSection, downloading),
                if (downloading.isNotEmpty) const SizedBox(height: 16),
                buildSection(l10n.completedSection, completed),
                if (completed.isNotEmpty) const SizedBox(height: 16),
                buildSection(l10n.failedSection, failed),
              ],
            ),
    );
  }
}

enum _DownloadsMenuAction {
  clearCompleted,
  clearFailed,
}

class _SwipeToRevealDelete extends StatefulWidget {
  const _SwipeToRevealDelete({
    required this.deleteKey,
    required this.child,
    this.enabled = true,
    this.onDelete,
  });

  final Key deleteKey;
  final Widget child;
  final bool enabled;
  final VoidCallback? onDelete;

  @override
  State<_SwipeToRevealDelete> createState() => _SwipeToRevealDeleteState();
}

class _SwipeToRevealDeleteState extends State<_SwipeToRevealDelete> {
  static const double _actionWidth = 92;
  double _dragExtent = 0;
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.onDelete == null) {
      return widget.child;
    }

    return SizedBox(
      height: 78,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: _actionWidth,
                  child: FilledButton(
                    key: widget.deleteKey,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(),
                    ),
                    onPressed: widget.onDelete,
                    child: Text(AppLocalizations.of(context)!.deleteAction),
                  ),
                ),
              ),
            ),
            AnimatedSlide(
              offset: Offset(_open ? -_actionWidth / 320 : 0, 0),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _open ? () => setState(() => _open = false) : null,
                onHorizontalDragUpdate: (details) {
                  _dragExtent += details.delta.dx;
                },
                onHorizontalDragEnd: (_) {
                  final shouldOpen = _dragExtent < -24;
                  final shouldClose = _dragExtent > 24;
                  setState(() {
                    if (shouldOpen) {
                      _open = true;
                    } else if (shouldClose) {
                      _open = false;
                    }
                  });
                  _dragExtent = 0;
                },
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadTaskTile extends StatelessWidget {
  const _DownloadTaskTile({
    required this.task,
    this.onRetry,
  });

  final DownloadTask task;
  final VoidCallback? onRetry;

  bool get _showProgressMeta => task.status == DownloadTaskStatus.downloading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                task.photo.urlThumb,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 52,
                    height: 52,
                    color: AppColors.gray100,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_outlined,
                      color: AppColors.gray400,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray500,
                    ),
                  ),
                  if (_showProgressMeta) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${(task.progress * 100).round()}%  ${_formatBytes(task.receivedBytes)} / ${_formatBytes(task.totalBytes)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.gray900,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.retryAction),
              )
            else
              _StatusBadge(status: task.status),
          ],
        ),
      ),
    );
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
    final formatted = value >= 100 || value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$formatted ${units[unitIndex]}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final DownloadTaskStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, background, foreground) = switch (status) {
      DownloadTaskStatus.downloading => (
          l10n.activeStatus,
          const Color(0xFFF3F4F6),
          AppColors.gray700,
        ),
      DownloadTaskStatus.completed => (
          l10n.doneStatus,
          const Color(0xFFE7F6EC),
          const Color(0xFF2F6B43),
        ),
      DownloadTaskStatus.failed => (
          l10n.failedStatus,
          const Color(0xFFFCEAEA),
          AppColors.error,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

class _DownloadsHint extends StatelessWidget {
  const _DownloadsHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: AppColors.gray600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadsEmptyState extends StatelessWidget {
  const _DownloadsEmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.download_done_rounded,
              size: 26,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
