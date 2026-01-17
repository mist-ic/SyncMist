import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Data class representing a device node in the network graph.
class DeviceNode {
  final String id;
  final String name;
  final bool isThisDevice;
  final bool isConnected;

  const DeviceNode({
    required this.id,
    required this.name,
    required this.isThisDevice,
    required this.isConnected,
  });

  /// Mock data for testing
  static List<DeviceNode> mockNodes = [
    const DeviceNode(
      id: 'self',
      name: 'This Device',
      isThisDevice: true,
      isConnected: true,
    ),
    const DeviceNode(
      id: 'pc',
      name: 'Windows PC',
      isThisDevice: false,
      isConnected: true,
    ),
    const DeviceNode(
      id: 'phone',
      name: 'Phone',
      isThisDevice: false,
      isConnected: false,
    ),
  ];
}

/// NetworkGraph widget that visualizes P2P connections as an animated graph.
class NetworkGraph extends StatefulWidget {
  final List<DeviceNode> devices;
  final VoidCallback? onSyncAnimation;

  const NetworkGraph({super.key, required this.devices, this.onSyncAnimation});

  @override
  State<NetworkGraph> createState() => NetworkGraphState();
}

class NetworkGraphState extends State<NetworkGraph>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Plays the sync animation.
  void playAnimation() {
    _animationController.reset();
    _animationController.forward();
    widget.onSyncAnimation?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              painter: _NetworkGraphPainter(
                devices: widget.devices,
                animationProgress: _animation.value,
              ),
              size: const Size(200, 200),
            );
          },
        ),
      ),
    );
  }
}

class _NetworkGraphPainter extends CustomPainter {
  final List<DeviceNode> devices;
  final double animationProgress;

  _NetworkGraphPainter({
    required this.devices,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    const nodeRadius = 24.0;

    // Calculate node positions in a circle
    final nodePositions = <String, Offset>{};
    for (int i = 0; i < devices.length; i++) {
      final angle = (2 * math.pi * i / devices.length) - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      nodePositions[devices[i].id] = Offset(x, y);
    }

    // Draw connection lines between connected devices
    final linePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final thisDevice = devices.firstWhere(
      (d) => d.isThisDevice,
      orElse: () =>
          devices.isNotEmpty ? devices.first : throw StateError('No devices'),
    );

    for (final device in devices) {
      if (device.isConnected && !device.isThisDevice) {
        final from = nodePositions[thisDevice.id]!;
        final to = nodePositions[device.id]!;
        canvas.drawLine(from, to, linePaint);

        // Draw animated sync dot
        if (animationProgress > 0 && animationProgress < 1) {
          final dotPaint = Paint()
            ..color = Colors.blue
            ..style = PaintingStyle.fill;
          final dotPosition = Offset(
            from.dx + (to.dx - from.dx) * animationProgress,
            from.dy + (to.dy - from.dy) * animationProgress,
          );
          canvas.drawCircle(dotPosition, 6, dotPaint);
        }
      }
    }

    // Draw nodes
    for (final device in devices) {
      final pos = nodePositions[device.id]!;

      // Node circle
      final nodePaint = Paint()
        ..color = device.isThisDevice
            ? Colors.blue
            : device.isConnected
                ? Colors.green
                : Colors.grey
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, nodeRadius, nodePaint);

      // Device icon (emoji as text)
      final textPainter = TextPainter(
        text: TextSpan(
          text: device.name.toLowerCase().contains('phone') ? '📱' : '💻',
          style: const TextStyle(fontSize: 18),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );

      // Device name below node
      final namePainter = TextPainter(
        text: TextSpan(
          text: device.name,
          style: const TextStyle(fontSize: 10, color: Colors.black87),
        ),
        textDirection: TextDirection.ltr,
      );
      namePainter.layout();
      namePainter.paint(
        canvas,
        Offset(pos.dx - namePainter.width / 2, pos.dy + nodeRadius + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkGraphPainter oldDelegate) {
    if (oldDelegate.animationProgress != animationProgress) return true;
    if (oldDelegate.devices.length != devices.length) return true;

    // Check if any device status changed
    for (int i = 0; i < devices.length; i++) {
      if (oldDelegate.devices[i].id != devices[i].id ||
          oldDelegate.devices[i].isConnected != devices[i].isConnected) {
        return true;
      }
    }
    return false;
  }
}
