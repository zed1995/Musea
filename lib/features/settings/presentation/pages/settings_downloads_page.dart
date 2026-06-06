import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/services/download_notifier.dart';
import 'package:musea/core/services/providers.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/l10n/generated/app_localizations.dart';
import 'package:musea/shared/widgets/android_top_bar.dart';

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

    Widget buildDownloadingSection(String title, List<DownloadTask> items) {
      if (items.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: Color(0xFFA8A29E),
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SwipeToRevealDelete(
                deleteKey: ValueKey('delete-task-${task.id}'),
                deleteSurfaceKey: ValueKey('delete-surface-${task.id}'),
                paddingKey: ValueKey('swipe-padding-${task.id}'),
                borderRadius: BorderRadius.circular(24),
                enabled: task.status != DownloadTaskStatus.downloading,
                onDelete: task.status == DownloadTaskStatus.downloading
                    ? null
                    : () {
                        ref.read(downloadNotifierProvider).removeTask(task.id);
                        showMessage(l10n.downloadTaskRemoved);
                      },
                childBuilder: (revealed) => _DownloadTaskTile(
                  key: ValueKey('download-card-${task.id}'),
                  task: task,
                  grouped: false,
                  revealed: revealed,
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

    Widget buildGroupedSection(String title, List<DownloadTask> items) {
      if (items.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: Color(0xFFA8A29E),
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SwipeToRevealDelete(
                deleteKey: ValueKey('delete-task-${task.id}'),
                deleteSurfaceKey: ValueKey('delete-surface-${task.id}'),
                paddingKey: ValueKey('swipe-padding-${task.id}'),
                borderRadius: BorderRadius.circular(24),
                onDelete: () {
                  ref.read(downloadNotifierProvider).removeTask(task.id);
                  showMessage(l10n.downloadTaskRemoved);
                },
                childBuilder: (revealed) => _DownloadTaskTile(
                  key: ValueKey('download-card-${task.id}'),
                  task: task,
                  grouped: false,
                  revealed: revealed,
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
      backgroundColor: const Color(0xFFF7F5F1),
      appBar: AndroidTopBar(
        titleText: l10n.downloadsPageTitle,
        showBackButton: true,
        trailing: completed.isNotEmpty || failed.isNotEmpty
            ? PopupMenuButton<_DownloadsMenuAction>(
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
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: tasks.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    children: [
                      _DownloadsEmptyState(label: l10n.noDownloadsYet),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    children: [
                      buildDownloadingSection(
                          l10n.downloadingSection, downloading),
                      if (downloading.isNotEmpty) const SizedBox(height: 20),
                      buildGroupedSection(l10n.completedSection, completed),
                      if (completed.isNotEmpty) const SizedBox(height: 20),
                      buildGroupedSection(l10n.failedSection, failed),
                    ],
                  ),
          ),
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
    required this.deleteSurfaceKey,
    required this.paddingKey,
    required this.childBuilder,
    required this.borderRadius,
    this.enabled = true,
    this.onDelete,
  });

  final Key deleteKey;
  final Key deleteSurfaceKey;
  final Key paddingKey;
  final Widget Function(bool revealed) childBuilder;
  final BorderRadius borderRadius;
  final bool enabled;
  final VoidCallback? onDelete;

  @override
  State<_SwipeToRevealDelete> createState() => _SwipeToRevealDeleteState();
}

class _SwipeToRevealDeleteState extends State<_SwipeToRevealDelete> {
  static const double _revealWidth = 64;
  double _dragExtent = 0;
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.onDelete == null) {
      return widget.childBuilder(false);
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                SizedBox(
                  width: _revealWidth,
                  child: DecoratedBox(
                    key: widget.deleteSurfaceKey,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topRight: widget.borderRadius.topRight,
                        bottomRight: widget.borderRadius.bottomRight,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: const [
                          Color(0xFFEF4444),
                          Color(0xFFDC2626),
                        ],
                      ),
                    ),
                    child: TextButton(
                      key: widget.deleteKey,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: const RoundedRectangleBorder(),
                      ),
                      onPressed: widget.onDelete,
                      child: Text(
                        AppLocalizations.of(context)!.deleteAction,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
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
            child: AnimatedPadding(
              key: widget.paddingKey,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.zero,
              child: Transform.translate(
                offset: Offset(_open ? -_revealWidth : 0, 0),
                child: widget.childBuilder(_open),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadTaskTile extends StatelessWidget {
  const _DownloadTaskTile({
    super.key,
    required this.task,
    required this.grouped,
    required this.revealed,
    this.onRetry,
  });

  final DownloadTask task;
  final bool grouped;
  final bool revealed;
  final VoidCallback? onRetry;
  String get _progressLabel => '${(task.progress * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final isDownloading = task.status == DownloadTaskStatus.downloading;
    return Container(
      key: ValueKey('download-surface-${task.id}'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: grouped
            ? BorderRadius.zero
            : BorderRadius.only(
                topLeft: const Radius.circular(24),
                bottomLeft: const Radius.circular(24),
                topRight: Radius.circular(revealed ? 0 : 24),
                bottomRight: Radius.circular(revealed ? 0 : 24),
              ),
        border: grouped ? null : Border.all(color: const Color(0xFFEEEBE6)),
        boxShadow: grouped
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 34,
                  offset: const Offset(0, 14),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  task.photo.urlThumb,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 64,
                      height: 64,
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
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
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
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.14,
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
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (onRetry != null)
                        _StatusBadge(status: task.status)
                      else if (isDownloading)
                        _ProgressBadge(label: _progressLabel)
                      else
                        _StatusBadge(status: task.status),
                    ],
                  ),
                  if (isDownloading) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: task.progress.clamp(0, 1),
                        minHeight: 7,
                        backgroundColor: const Color(0xFFECE7E2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF18181B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatBytes(task.receivedBytes)} / ${_formatBytes(task.totalBytes)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF78716C),
                      ),
                    ),
                  ] else if (onRetry != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.downloadFailed,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFBE123C),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: onRetry,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF18181B),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            minimumSize: const Size(0, 34),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child:
                              Text(AppLocalizations.of(context)!.retryAction),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Text(
                      AppLocalizations.of(context)!.downloadProgressCompleted,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF78716C),
                      ),
                    ),
                  ],
                ],
              ),
            ),
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

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Colors.white,
        ),
      ),
    );
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
          const Color(0xFF18181B),
          Colors.white,
        ),
      DownloadTaskStatus.completed => (
          l10n.doneStatus,
          const Color(0xFFEEF2E8),
          const Color(0xFF3F4B2A),
        ),
      DownloadTaskStatus.failed => (
          l10n.failedStatus,
          const Color(0xFFFFF1F2),
          const Color(0xFFBE123C),
        ),
    };

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: foreground,
        ),
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
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD6D3D1),
            style: BorderStyle.solid,
          ),
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
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Saved photos will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF78716C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
