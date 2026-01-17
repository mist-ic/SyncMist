import 'package:flutter/material.dart';

/// EncryptionBadge widget that shows E2E encryption status.
/// Displays a lock icon with "E2EE" text and provides informational dialog on tap.
class EncryptionBadge extends StatelessWidget {
  const EncryptionBadge({super.key});

  void _showEncryptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.green),
            SizedBox(width: 8),
            Text('End-to-End Encryption'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• All clipboard data is encrypted before leaving your device',
            ),
            SizedBox(height: 8),
            Text('• Only paired devices can decrypt your content'),
            SizedBox(height: 8),
            Text('• We never see your clipboard'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'End-to-end encrypted\nYour clipboard is private',
      child: InkWell(
        onTap: () => _showEncryptionDialog(context),
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 14, color: Colors.green),
              SizedBox(width: 4),
              Text(
                'E2EE',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
