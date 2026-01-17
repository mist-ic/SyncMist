import 'dart:async';
import 'dart:typed_data';

/// Abstract interface for P2P transport layer.
/// 
/// This interface defines the contract for peer-to-peer communication.
/// Currently uses a mock implementation for development.
/// 
/// TODO: Replace with RustTransport.instance when FFI ready
abstract class TransportInterface {
  /// Start listening for incoming connections on the specified port.
  Future<void> startServer({int port = 9876});

  /// Connect to a peer at the given address and port.
  Future<PeerConnection> connectToPeer(String address, int port);

  /// Stream of incoming data from all connected peers.
  Stream<Uint8List> get incomingData;

  /// Disconnect from all peers and stop the server.
  Future<void> disconnect();

  /// Get the singleton instance of the transport.
  /// TODO: Replace with RustTransport.instance when FFI ready
  static TransportInterface get instance => MockTransport();
}

/// Represents a connection to a single peer.
class PeerConnection {
  /// Unique identifier for this peer.
  final String peerId;

  /// Network address of the peer.
  final String address;

  /// Port number of the peer.
  final int port;

  /// Whether the connection is currently active.
  bool isConnected;

  /// Controller for incoming data from this peer.
  final StreamController<Uint8List> _dataController =
      StreamController<Uint8List>.broadcast();

  PeerConnection({
    required this.peerId,
    required this.address,
    required this.port,
    this.isConnected = true,
  });

  /// Stream of data received from this peer.
  Stream<Uint8List> get dataStream => _dataController.stream;

  /// Send data to this peer.
  Future<void> send(Uint8List data) async {
    if (!isConnected) {
      throw StateError('Cannot send data: peer is disconnected');
    }
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 50));
    print('[PeerConnection] Sent ${data.length} bytes to $peerId');
  }

  /// Simulate receiving data (used by mock transport).
  void receiveData(Uint8List data) {
    if (isConnected) {
      _dataController.add(data);
    }
  }

  /// Close the connection.
  Future<void> close() async {
    isConnected = false;
    await _dataController.close();
    print('[PeerConnection] Closed connection to $peerId');
  }
}

/// Mock implementation of TransportInterface for development.
/// 
/// TODO: Replace with RustTransport.instance when FFI ready
class MockTransport implements TransportInterface {
  static final MockTransport _instance = MockTransport._internal();

  factory MockTransport() => _instance;

  MockTransport._internal();

  bool _isServerRunning = false;
  int _serverPort = 9876;
  final List<PeerConnection> _connections = [];
  final StreamController<Uint8List> _incomingDataController =
      StreamController<Uint8List>.broadcast();

  @override
  Future<void> startServer({int port = 9876}) async {
    if (_isServerRunning) {
      print('[MockTransport] Server already running on port $_serverPort');
      return;
    }

    // Simulate startup latency
    await Future.delayed(const Duration(milliseconds: 50));
    
    _serverPort = port;
    _isServerRunning = true;
    print('[MockTransport] Server started on port $port');
  }

  @override
  Future<PeerConnection> connectToPeer(String address, int port) async {
    print('[MockTransport] Connecting to $address:$port...');
    
    // Simulate connection latency
    await Future.delayed(const Duration(milliseconds: 50));

    final peerId = 'peer-${DateTime.now().millisecondsSinceEpoch}';
    final connection = PeerConnection(
      peerId: peerId,
      address: address,
      port: port,
      isConnected: true,
    );

    // Forward peer data to the main incoming stream
    connection.dataStream.listen((data) {
      _incomingDataController.add(data);
    });

    _connections.add(connection);
    print('[MockTransport] Connected to $address:$port as $peerId');

    return connection;
  }

  @override
  Stream<Uint8List> get incomingData => _incomingDataController.stream;

  @override
  Future<void> disconnect() async {
    print('[MockTransport] Disconnecting all peers...');

    for (final connection in _connections) {
      await connection.close();
    }
    _connections.clear();
    _isServerRunning = false;

    print('[MockTransport] All connections closed, server stopped');
  }

  /// Get list of active connections (for testing/debugging).
  List<PeerConnection> get activeConnections => List.unmodifiable(_connections);

  /// Check if server is running.
  bool get isServerRunning => _isServerRunning;

  /// Simulate receiving data from a peer (for testing).
  void simulateIncomingData(String peerId, Uint8List data) {
    final connection = _connections.where((c) => c.peerId == peerId).firstOrNull;
    if (connection != null) {
      print('[MockTransport] Simulating incoming data from $peerId');
      Future.delayed(const Duration(milliseconds: 50), () {
        connection.receiveData(data);
      });
    }
  }
}
