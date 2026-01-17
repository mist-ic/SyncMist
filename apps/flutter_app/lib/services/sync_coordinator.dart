import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'p2p_service.dart';
import 'discovery_service.dart';
import '../core/interfaces/discovery_interface.dart';

/// Direction of a sync operation.
enum SyncDirection {
  outgoing,
  incoming,
}

/// Represents a sync event for UI animations.
class SyncEvent {
  /// Direction of the sync (outgoing or incoming).
  final SyncDirection direction;

  /// Preview of the content (first 50 characters).
  final String contentPreview;

  /// ID of the peer involved in the sync.
  final String peerId;

  /// When the sync occurred.
  final DateTime timestamp;

  /// Whether the sync was successful.
  final bool success;

  SyncEvent({
    required this.direction,
    required this.contentPreview,
    required this.peerId,
    required this.success,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'SyncEvent($direction, "$contentPreview", peer: $peerId, success: $success)';
}

/// Mock crypto service for development.
///
/// TODO: Replace with real CryptoService when available
class _MockCryptoService {
  static final _MockCryptoService _instance = _MockCryptoService._internal();
  factory _MockCryptoService() => _instance;
  _MockCryptoService._internal();

  static _MockCryptoService get instance => _instance;

  // Simple XOR-based mock encryption (NOT SECURE - for demo only)
  final int _mockKey = 0x5A;

  /// Mock encrypt data.
  Uint8List encrypt(Uint8List data) {
    print('[MockCrypto] Encrypting ${data.length} bytes');
    return Uint8List.fromList(data.map((b) => b ^ _mockKey).toList());
  }

  /// Mock decrypt data.
  Uint8List decrypt(Uint8List data) {
    print('[MockCrypto] Decrypting ${data.length} bytes');
    // XOR is symmetric
    return Uint8List.fromList(data.map((b) => b ^ _mockKey).toList());
  }

  /// Get room key (mock).
  String getRoomKey() {
    return 'mock-room-key-12345';
  }
}

/// Coordinator for clipboard synchronization.
///
/// This singleton service orchestrates:
/// - P2P connections
/// - Device discovery
/// - Encryption/decryption
/// - Sync event emission for UI
class SyncCoordinator {
  static final SyncCoordinator _instance = SyncCoordinator._internal();

  /// Get the singleton instance.
  static SyncCoordinator get instance => _instance;

  SyncCoordinator._internal();

  /// P2P service for communication.
  late P2PService _p2pService;

  /// Discovery service for finding devices.
  late DiscoveryService _discoveryService;

  /// Crypto service for encryption.
  late _MockCryptoService _cryptoService;

  /// Whether the coordinator has been initialized.
  bool isInitialized = false;

  /// Whether syncing is currently active.
  bool isSyncing = false;

  /// Stream controller for sync events.
  final StreamController<SyncEvent> _syncEvents =
      StreamController<SyncEvent>.broadcast();

  /// Subscription to incoming data.
  StreamSubscription<Uint8List>? _incomingDataSubscription;

  /// Callback for received clipboard content.
  void Function(String content)? onClipboardReceived;

  /// Initialize the sync coordinator.
  Future<void> initialize() async {
    if (isInitialized) {
      print('[SyncCoordinator] Already initialized');
      return;
    }

    print('[SyncCoordinator] Initializing...');

    // Initialize services
    _p2pService = P2PService.instance;
    _discoveryService = DiscoveryService.instance;
    _cryptoService = _MockCryptoService.instance;

    await _p2pService.initialize();
    await _discoveryService.initialize();

    // Start discovery
    await _discoveryService.startDiscovery();

    // Start as server to accept incoming connections
    await _p2pService.startAsServer();

    isInitialized = true;
    print('[SyncCoordinator] Initialized successfully');
  }

  /// Start syncing clipboard content.
  Future<void> startSync() async {
    _ensureInitialized();

    if (isSyncing) {
      print('[SyncCoordinator] Already syncing');
      return;
    }

    print('[SyncCoordinator] Starting sync...');

    // Listen for incoming data
    _incomingDataSubscription = _p2pService.incomingData.listen(
      _handleIncomingData,
      onError: (error) {
        print('[SyncCoordinator] Error receiving data: $error');
      },
    );

    // Auto-connect to discovered peers
    _discoveryService.peers.listen((peers) {
      for (final peer in peers) {
        _connectToPeerIfNeeded(peer);
      }
    });

    isSyncing = true;
    print('[SyncCoordinator] Sync started');
  }

  /// Stop syncing.
  Future<void> stopSync() async {
    _ensureInitialized();

    if (!isSyncing) {
      print('[SyncCoordinator] Not currently syncing');
      return;
    }

    print('[SyncCoordinator] Stopping sync...');

    await _incomingDataSubscription?.cancel();
    _incomingDataSubscription = null;

    isSyncing = false;
    print('[SyncCoordinator] Sync stopped');
  }

  /// Send clipboard content to all connected peers.
  Future<void> sendClipboard(String content) async {
    _ensureInitialized();

    print('[SyncCoordinator] Sending clipboard content...');

    try {
      // Convert to bytes
      final contentBytes = Uint8List.fromList(utf8.encode(content));

      // Encrypt
      final encryptedBytes = _cryptoService.encrypt(contentBytes);

      // Broadcast to all peers
      await _p2pService.broadcast(encryptedBytes);

      // Emit success event
      _syncEvents.add(SyncEvent(
        direction: SyncDirection.outgoing,
        contentPreview: _getPreview(content),
        peerId: 'broadcast',
        success: true,
      ));

      print('[SyncCoordinator] Clipboard sent successfully');
    } catch (e) {
      print('[SyncCoordinator] Error sending clipboard: $e');

      // Emit failure event
      _syncEvents.add(SyncEvent(
        direction: SyncDirection.outgoing,
        contentPreview: _getPreview(content),
        peerId: 'broadcast',
        success: false,
      ));
    }
  }

  /// Handle incoming data from peers.
  void _handleIncomingData(Uint8List encryptedData) {
    try {
      print('[SyncCoordinator] Received ${encryptedData.length} bytes');

      // Decrypt
      final decryptedBytes = _cryptoService.decrypt(encryptedData);

      // Convert to string
      final content = utf8.decode(decryptedBytes);

      // Emit success event
      _syncEvents.add(SyncEvent(
        direction: SyncDirection.incoming,
        contentPreview: _getPreview(content),
        peerId: 'unknown', // Could track peer ID if needed
        success: true,
      ));

      // Notify callback
      onClipboardReceived?.call(content);

      print('[SyncCoordinator] Clipboard received: ${_getPreview(content)}');
    } catch (e) {
      print('[SyncCoordinator] Error processing incoming data: $e');

      // Emit failure event
      _syncEvents.add(SyncEvent(
        direction: SyncDirection.incoming,
        contentPreview: '[Error]',
        peerId: 'unknown',
        success: false,
      ));
    }
  }

  /// Connect to a peer if not already connected.
  Future<void> _connectToPeerIfNeeded(PeerInfo peer) async {
    final isConnected = _p2pService.connectedPeers.any(
      (p) => p.address == peer.addresses.firstOrNull,
    );

    if (!isConnected) {
      await _p2pService.connectToPeer(peer);
    }
  }

  /// Get a preview of content (first 50 chars).
  String _getPreview(String content) {
    if (content.length <= 50) {
      return content;
    }
    return '${content.substring(0, 47)}...';
  }

  /// Stream of sync events for UI animations.
  Stream<SyncEvent> get syncEvents => _syncEvents.stream;

  /// List of current peers.
  List<PeerInfo> get peers => _discoveryService.currentPeers;

  /// Number of connected peers.
  int get connectedPeerCount => _p2pService.peerCount;

  /// Ensure the coordinator is initialized.
  void _ensureInitialized() {
    if (!isInitialized) {
      throw StateError(
          'SyncCoordinator not initialized. Call initialize() first.');
    }
  }

  /// Shutdown the coordinator.
  Future<void> shutdown() async {
    print('[SyncCoordinator] Shutting down...');

    await stopSync();
    await _discoveryService.stopDiscovery();
    await _p2pService.disconnectAll();

    isInitialized = false;
    print('[SyncCoordinator] Shutdown complete');
  }
}
