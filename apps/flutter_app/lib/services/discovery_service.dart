import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/interfaces/discovery_interface.dart';

/// Service for discovering other SyncMist devices on the network.
///
/// This singleton service handles:
/// - Device ID generation and persistence
/// - Device name retrieval
/// - Starting/stopping network discovery
/// - Exposing discovered peers stream
class DiscoveryService {
  static final DiscoveryService _instance = DiscoveryService._internal();

  /// Get the singleton instance.
  static DiscoveryService get instance => _instance;

  DiscoveryService._internal();

  /// Key for storing device ID in SharedPreferences.
  static const String _deviceIdKey = 'syncmist_device_id';

  /// The underlying discovery interface.
  late DiscoveryInterface _discovery;

  /// Whether the service has been initialized.
  bool _isInitialized = false;

  /// Whether discovery is currently active.
  bool _isScanning = false;

  /// Current list of discovered peers.
  List<PeerInfo> _discoveredPeers = [];

  /// Our own device ID (to filter from discovered peers).
  String? _ownDeviceId;

  /// Stream controller for peers (filtered to exclude self).
  final StreamController<List<PeerInfo>> _peersController =
      StreamController<List<PeerInfo>>.broadcast();

  /// Subscription to underlying discovery stream.
  StreamSubscription<List<PeerInfo>>? _discoverySubscription;

  /// Initialize the discovery service.
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[DiscoveryService] Already initialized');
      return;
    }

    debugPrint('[DiscoveryService] Initializing...');
    _discovery = DiscoveryInterface.instance;
    _ownDeviceId = await getDeviceId();
    _isInitialized = true;

    // Listen to discovered peers and filter out self
    _discoverySubscription = _discovery.discoveredPeers.listen((peers) {
      _discoveredPeers =
          peers.where((p) => p.deviceId != _ownDeviceId).toList();
      _peersController.add(_discoveredPeers);
      debugPrint(
          '[DiscoveryService] Updated peers: ${_discoveredPeers.length} devices');
    });

    debugPrint('[DiscoveryService] Initialized successfully');
  }

  /// Get or generate the device ID.
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
      debugPrint('[DiscoveryService] Generated new device ID: $deviceId');
    } else {
      debugPrint('[DiscoveryService] Loaded existing device ID: $deviceId');
    }

    return deviceId;
  }

  /// Get the device name.
  Future<String> getDeviceName() async {
    // Try to get a meaningful device name
    try {
      if (Platform.isWindows) {
        return Platform.environment['COMPUTERNAME'] ?? 'Windows Device';
      } else if (Platform.isMacOS) {
        return Platform.environment['USER'] != null
            ? "${Platform.environment['USER']}'s Mac"
            : 'Mac Device';
      } else if (Platform.isLinux) {
        return Platform.environment['HOSTNAME'] ?? 'Linux Device';
      } else if (Platform.isAndroid) {
        return 'Android Device';
      } else if (Platform.isIOS) {
        return 'iOS Device';
      }
    } catch (e) {
      debugPrint('[DiscoveryService] Error getting device name: $e');
    }

    return 'SyncMist Device';
  }

  /// Start device discovery.
  ///
  /// This will register this device on the network and start
  /// browsing for other devices.
  Future<void> startDiscovery({int port = 9876}) async {
    _ensureInitialized();

    if (_isScanning) {
      debugPrint('[DiscoveryService] Already scanning');
      return;
    }

    try {
      debugPrint('[DiscoveryService] Starting discovery...');

      final deviceId = await getDeviceId();
      final deviceName = await getDeviceName();

      // Register ourselves on the network
      await _discovery.register(deviceId, deviceName, port);

      // Start browsing for other devices
      await _discovery.startBrowsing();
      _isScanning = true;

      debugPrint('[DiscoveryService] Discovery started');
    } catch (e) {
      debugPrint('[DiscoveryService] Error starting discovery: $e');
      rethrow;
    }
  }

  /// Stop device discovery.
  Future<void> stopDiscovery() async {
    _ensureInitialized();

    if (!_isScanning) {
      debugPrint('[DiscoveryService] Not currently scanning');
      return;
    }

    try {
      debugPrint('[DiscoveryService] Stopping discovery...');
      await _discovery.stopBrowsing();
      _isScanning = false;
      _discoveredPeers = [];
      _peersController.add([]);
      debugPrint('[DiscoveryService] Discovery stopped');
    } catch (e) {
      debugPrint('[DiscoveryService] Error stopping discovery: $e');
      rethrow;
    }
  }

  /// Dispose the service resources.
  Future<void> dispose() async {
    await stopDiscovery();
    await _discoverySubscription?.cancel();
    await _peersController.close();
    _isInitialized = false;
    debugPrint('[DiscoveryService] Disposed');
  }

  /// Stream of discovered peers (excludes self).
  Stream<List<PeerInfo>> get peers => _peersController.stream;

  /// Current list of discovered peers (synchronous getter).
  List<PeerInfo> get currentPeers => List.unmodifiable(_discoveredPeers);

  /// Whether discovery is currently active.
  bool get isScanning => _isScanning;

  /// Whether the service is initialized.
  bool get isInitialized => _isInitialized;

  /// Ensure the service is initialized before use.
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'DiscoveryService not initialized. Call initialize() first.');
    }
  }
}
