import 'package:flutter/material.dart';

/// Data class representing a peer device.
class PeerData {
  final String deviceId;
  final String deviceName;
  final String address;
  final int port;
  final bool isConnected;

  const PeerData({
    required this.deviceId,
    required this.deviceName,
    required this.address,
    required this.port,
    required this.isConnected,
  });

  /// Mock data for testing
  static List<PeerData> mockPeers = [
    const PeerData(
      deviceId: 'pc-1',
      deviceName: 'Windows PC',
      address: '192.168.1.100',
      port: 9876,
      isConnected: true,
    ),
    const PeerData(
      deviceId: 'phone-1',
      deviceName: 'Android Phone',
      address: '192.168.1.101',
      port: 9876,
      isConnected: false,
    ),
  ];
}

/// PeerList widget that shows discovered devices with connect/disconnect buttons.
class PeerList extends StatefulWidget {
  final List<PeerData> peers;
  final Function(PeerData)? onConnect;
  final Function(PeerData)? onDisconnect;

  const PeerList({
    super.key,
    required this.peers,
    this.onConnect,
    this.onDisconnect,
  });

  @override
  State<PeerList> createState() => _PeerListState();
}

class _PeerListState extends State<PeerList> {
  /// Gets the appropriate icon based on device name.
  IconData _getDeviceIcon(String deviceName) {
    final name = deviceName.toLowerCase();
    if (name.contains('windows') ||
        name.contains('pc') ||
        name.contains('mac')) {
      return Icons.computer;
    } else if (name.contains('android') || name.contains('phone')) {
      return Icons.phone_android;
    } else if (name.contains('linux')) {
      return Icons.laptop;
    }
    return Icons.devices;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.peers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Searching for devices...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure devices are on the same network',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.peers.length,
      itemBuilder: (context, index) {
        final peer = widget.peers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Icon(
              _getDeviceIcon(peer.deviceName),
              color: peer.isConnected ? Colors.green : Colors.grey,
            ),
            title: Text(peer.deviceName),
            subtitle: Text(peer.address),
            trailing: IconButton(
              icon: Icon(
                peer.isConnected ? Icons.link_off : Icons.link,
                color: peer.isConnected ? Colors.green : Colors.grey,
              ),
              tooltip: peer.isConnected ? 'Disconnect' : 'Connect',
              onPressed: () {
                if (peer.isConnected) {
                  widget.onDisconnect?.call(peer);
                } else {
                  widget.onConnect?.call(peer);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
