import 'package:flutter/material.dart';

/// StatusBadge widget that shows connection status in the app bar.
/// Shows peer count when connected and "Offline" when disconnected.
class StatusBadge extends StatelessWidget {
  final bool isConnected;
  final int peerCount;

  const StatusBadge({super.key, required this.isConnected, this.peerCount = 0});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isConnected
        ? Colors.green.shade100
        : Colors.red.shade100;
    final contentColor = isConnected
        ? Colors.green.shade700
        : Colors.red.shade700;
    final icon = isConnected ? Icons.sync : Icons.sync_disabled;
    final text = isConnected ? '$peerCount device(s)' : 'Offline';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: contentColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: contentColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
