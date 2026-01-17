import 'package:flutter/material.dart';

/// SyncIndicator widget that shows when clipboard is syncing with animation.
class SyncIndicator extends StatefulWidget {
  final bool isSyncing;
  final String? lastSyncedContent;
  final DateTime? lastSyncTime;

  const SyncIndicator({
    super.key,
    required this.isSyncing,
    this.lastSyncedContent,
    this.lastSyncTime,
  });

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isSyncing) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(SyncIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSyncing != oldWidget.isSyncing) {
      if (widget.isSyncing) {
        _animationController.repeat();
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Formats the time since last sync.
  String _formatTimeSinceSync() {
    if (widget.lastSyncTime == null) {
      return 'Ready';
    }

    final diff = DateTime.now().difference(widget.lastSyncTime!);
    if (diff.inSeconds < 10) {
      return 'Just now';
    } else if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }

  /// Truncates content to 30 chars.
  String _truncateContent(String content) {
    if (content.length <= 30) return content;
    return '${content.substring(0, 30)}...';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.isSyncing
        ? Colors.blue.shade50
        : Colors.green.shade50;
    final iconColor = widget.isSyncing ? Colors.blue : Colors.green;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (widget.isSyncing)
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animationController.value * 2 * 3.14159,
                      child: Icon(Icons.sync, color: iconColor, size: 20),
                    );
                  },
                )
              else
                Icon(Icons.sync, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.isSyncing ? 'Syncing...' : _formatTimeSinceSync(),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (widget.lastSyncedContent != null) ...[
            const SizedBox(height: 8),
            Text(
              _truncateContent(widget.lastSyncedContent!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
