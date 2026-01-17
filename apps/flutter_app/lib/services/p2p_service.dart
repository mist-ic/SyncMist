import 'dart:async';
import 'dart:typed_data';

import '../core/interfaces/transport_interface.dart';
import '../core/interfaces/discovery_interface.dart';

/// Types of connection events.
enum ConnectionEventType {
  connected,
  disconnected,
}

/// Represents a connection state change event.
class ConnectionEvent {
  /// The ID of the peer that connected/disconnected.
  final String peerId;

  /// The type of event (connected or disconnected).
  final ConnectionEventType type;

  /// When this event occurred.
  final DateTime timestamp;

  ConnectionEvent({
    required this.peerId,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'ConnectionEvent($type: $peerId at $timestamp)';
}

/// Service for managing peer-to-peer connections.
///
/// This singleton service handles:
/// - Starting as a server to accept incoming connections
/// - Connecting to discovered peers
/// - Broadcasting data to all connected peers
/// - Sending data to specific peers
class P2PService {
  static final P2PService _instance = P2PService._internal();

  /// Get the singleton instance.
  static P2PService get instance => _instance;

  P2PService._internal();

  /// The underlying transport layer.
  late TransportInterface _transport;

  /// List of currently connected peers.
  final List<PeerConnection> _connectedPeers = [];

  /// Whether this instance is running as a server.
  bool isServer = false;

  /// Whether the service has been initialized.
  bool _isInitialized = false;

  /// Stream controller for connection events.
  final StreamController<ConnectionEvent> _connectionEvents =
      StreamController<ConnectionEvent>.broadcast();

  /// Stream controller for merged incoming data from all peers.
  final StreamController<Uint8List> _incomingDataController =
      StreamController<Uint8List>.broadcast();

  /// Initialize the P2P service.
  Future<void> initialize() async {
    if (_isInitialized) {
      print('[P2PService] Already initialized');
      return;
    }

    print('[P2PService] Initializing...');
    _transport = TransportInterface.instance;
    _isInitialized = true;

    // Listen to transport's incoming data and forward it
    _transport.incomingData.listen(
      (data) {
        _incomingDataController.add(data);
      },
      onError: (error) {
        print('[P2PService] Error receiving data: $error');
      },
    );

    print('[P2PService] Initialized successfully');
  }

  /// Start listening for incoming connections.
  Future<void> startAsServer({int port = 9876}) async {
    _ensureInitialized();

    try {
      print('[P2PService] Starting server on port $port...');
      await _transport.startServer(port: port);
      isServer = true;
      print('[P2PService] Server started successfully');
    } catch (e) {
      print('[P2PService] Error starting server: $e');
      rethrow;
    }
  }

  /// Connect to a discovered peer.
  Future<void> connectToPeer(PeerInfo peer) async {
    _ensureInitialized();

    // Don't connect if already connected
    if (_connectedPeers.any((p) => p.peerId == peer.deviceId)) {
      print('[P2PService] Already connected to ${peer.deviceName}');
      return;
    }

    try {
      print('[P2PService] Connecting to ${peer.deviceName}...');

      // Use the first available address
      final address = peer.addresses.isNotEmpty
          ? peer.addresses.first
          : throw StateError('No address available for peer');

      final connection = await _transport.connectToPeer(address, peer.port);
      _connectedPeers.add(connection);

      // Listen for data from this peer
      connection.dataStream.listen(
        (data) {
          _incomingDataController.add(data);
        },
        onError: (error) {
          print('[P2PService] Error from peer ${connection.peerId}: $error');
        },
        onDone: () {
          _handlePeerDisconnected(connection.peerId);
        },
      );

      // Emit connection event
      _connectionEvents.add(ConnectionEvent(
        peerId: connection.peerId,
        type: ConnectionEventType.connected,
      ));

      print('[P2PService] Connected to ${peer.deviceName}');
    } catch (e) {
      print('[P2PService] Error connecting to ${peer.deviceName}: $e');
      // Don't crash on single peer failure
    }
  }

  /// Broadcast data to all connected peers.
  Future<void> broadcast(Uint8List data) async {
    _ensureInitialized();

    if (_connectedPeers.isEmpty) {
      print('[P2PService] No peers connected, nothing to broadcast');
      return;
    }

    print(
        '[P2PService] Broadcasting ${data.length} bytes to ${_connectedPeers.length} peers...');

    final futures = <Future>[];
    for (final peer in _connectedPeers) {
      futures.add(_sendToPeerSafe(peer, data));
    }

    await Future.wait(futures);
    print('[P2PService] Broadcast complete');
  }

  /// Send data to a specific peer.
  Future<void> sendToPeer(String peerId, Uint8List data) async {
    _ensureInitialized();

    final peer = _connectedPeers.where((p) => p.peerId == peerId).firstOrNull;
    if (peer == null) {
      print('[P2PService] Peer $peerId not found');
      return;
    }

    await _sendToPeerSafe(peer, data);
  }

  /// Send data to a peer with error handling.
  Future<void> _sendToPeerSafe(PeerConnection peer, Uint8List data) async {
    try {
      await peer.send(data);
    } catch (e) {
      print('[P2PService] Error sending to ${peer.peerId}: $e');
      _handlePeerDisconnected(peer.peerId);
    }
  }

  /// Handle peer disconnection.
  void _handlePeerDisconnected(String peerId) {
    _connectedPeers.removeWhere((p) => p.peerId == peerId);
    _connectionEvents.add(ConnectionEvent(
      peerId: peerId,
      type: ConnectionEventType.disconnected,
    ));
    print('[P2PService] Peer $peerId disconnected');
  }

  /// Stream of incoming data from all connected peers.
  Stream<Uint8List> get incomingData => _incomingDataController.stream;

  /// Stream of connection events (connect/disconnect).
  Stream<ConnectionEvent> get connectionEvents => _connectionEvents.stream;

  /// List of currently connected peers.
  List<PeerConnection> get connectedPeers => List.unmodifiable(_connectedPeers);

  /// Number of connected peers.
  int get peerCount => _connectedPeers.length;

  /// Whether the service is initialized.
  bool get isInitialized => _isInitialized;

  /// Disconnect from all peers.
  Future<void> disconnectAll() async {
    print('[P2PService] Disconnecting from all peers...');
    await _transport.disconnect();

    for (final peer in _connectedPeers) {
      _connectionEvents.add(ConnectionEvent(
        peerId: peer.peerId,
        type: ConnectionEventType.disconnected,
      ));
    }
    _connectedPeers.clear();
    isServer = false;
    print('[P2PService] All peers disconnected');
  }

  /// Ensure the service is initialized before use.
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('P2PService not initialized. Call initialize() first.');
    }
  }
}
