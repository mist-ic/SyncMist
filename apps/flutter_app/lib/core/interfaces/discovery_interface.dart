import 'dart:async';

import 'package:flutter/foundation.dart';

/// Information about a discovered peer device.
class PeerInfo {
  /// Unique identifier for this device.
  final String deviceId;

  /// Human-readable name for this device.
  final String deviceName;

  /// List of network addresses for this device.
  final List<String> addresses;

  /// Port number the device is listening on.
  final int port;

  /// When this device was discovered.
  final DateTime discoveredAt;

  PeerInfo({
    required this.deviceId,
    required this.deviceName,
    required this.addresses,
    required this.port,
    DateTime? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  @override
  String toString() => 'PeerInfo($deviceName @ ${addresses.join(", ")}:$port)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeerInfo &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId;

  @override
  int get hashCode => deviceId.hashCode;
}

/// Abstract interface for mDNS-based device discovery.
///
/// This interface defines the contract for discovering other devices
/// on the local network. Currently uses a mock implementation.
///
/// TODO: Replace with RustDiscovery.instance when FFI ready
abstract class DiscoveryInterface {
  /// Register this device on the network for discovery.
  Future<void> register(String deviceId, String deviceName, int port);

  /// Start browsing for other devices on the network.
  Future<void> startBrowsing();

  /// Stop browsing for devices.
  Future<void> stopBrowsing();

  /// Stream of discovered peers. Emits updated list when peers change.
  Stream<List<PeerInfo>> get discoveredPeers;

  /// Get the singleton instance of the discovery service.
  /// TODO: Replace with RustDiscovery.instance when FFI ready
  static DiscoveryInterface get instance => MockDiscovery();
}

/// Mock implementation of DiscoveryInterface for development.
///
/// TODO: Replace with RustDiscovery.instance when FFI ready
class MockDiscovery implements DiscoveryInterface {
  static final MockDiscovery _instance = MockDiscovery._internal();

  factory MockDiscovery() => _instance;

  MockDiscovery._internal();

  bool _isRegistered = false;
  bool _isBrowsing = false;

  final StreamController<List<PeerInfo>> _peersController =
      StreamController<List<PeerInfo>>.broadcast();

  final List<PeerInfo> _mockPeers = [];

  @override
  Future<void> register(String deviceId, String deviceName, int port) async {
    debugPrint(
        '[MockDiscovery] Registering device: $deviceName ($deviceId) on port $port');

    _isRegistered = true;

    debugPrint('[MockDiscovery] Device registered successfully');
  }

  @override
  Future<void> startBrowsing() async {
    if (_isBrowsing) {
      debugPrint('[MockDiscovery] Already browsing');
      return;
    }

    debugPrint('[MockDiscovery] Starting network browsing...');
    _isBrowsing = true;

    // Simulate finding devices after 1 second delay
    Future.delayed(const Duration(seconds: 1), () {
      if (!_isBrowsing) return;

      _mockPeers.clear();
      _mockPeers.addAll([
        PeerInfo(
          deviceId: 'mock-pc',
          deviceName: 'Windows PC',
          addresses: ['192.168.1.100'],
          port: 9876,
        ),
        PeerInfo(
          deviceId: 'mock-phone',
          deviceName: 'Android Phone',
          addresses: ['192.168.1.101'],
          port: 9876,
        ),
      ]);

      debugPrint('[MockDiscovery] Found ${_mockPeers.length} mock peers');
      _peersController.add(List.unmodifiable(_mockPeers));
    });
  }

  @override
  Future<void> stopBrowsing() async {
    debugPrint('[MockDiscovery] Stopping network browsing');
    _isBrowsing = false;
    _mockPeers.clear();
    _peersController.add([]);
  }

  @override
  Stream<List<PeerInfo>> get discoveredPeers => _peersController.stream;

  /// Check if currently browsing.
  bool get isBrowsing => _isBrowsing;

  /// Check if device is registered.
  bool get isRegistered => _isRegistered;

  /// Add a mock peer (for testing).
  void addMockPeer(PeerInfo peer) {
    if (!_mockPeers.contains(peer)) {
      _mockPeers.add(peer);
      _peersController.add(List.unmodifiable(_mockPeers));
      debugPrint('[MockDiscovery] Added mock peer: ${peer.deviceName}');
    }
  }

  /// Remove a mock peer (for testing).
  void removeMockPeer(String deviceId) {
    _mockPeers.removeWhere((p) => p.deviceId == deviceId);
    _peersController.add(List.unmodifiable(_mockPeers));
    debugPrint('[MockDiscovery] Removed mock peer: $deviceId');
  }
}
