import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../services/clipboard_service.dart';
import '../services/device_service.dart';
import '../services/crypto_service.dart';
import '../services/auth_service.dart';
import '../services/discovery_service.dart';
import '../services/sync_coordinator.dart' hide CryptoService;
import '../services/p2p_service.dart';
import '../core/interfaces/discovery_interface.dart';
import 'pairing_screen.dart';
import 'widgets/status_badge.dart';
import 'widgets/encryption_badge.dart';
import 'widgets/peer_list.dart';
import 'widgets/network_graph.dart';
import 'widgets/sync_indicator.dart';

/// Home Screen with WebSocket integration and network visualization
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WebSocketService _wsService = WebSocketService();
  final ClipboardService _clipboardService = ClipboardService();
  final DeviceService _deviceService = DeviceService();
  final AuthService _authService = AuthService();
  late final CryptoService _cryptoService;

  final TextEditingController _urlController =
      TextEditingController(text: 'ws://localhost:8080/ws');
  final TextEditingController _messageController = TextEditingController();

  final GlobalKey<NetworkGraphState> _graphKey = GlobalKey<NetworkGraphState>();

  // Stream subscriptions for cleanup
  final List<StreamSubscription> _subscriptions = [];

  String _connectionStatus = 'Disconnected';
  String _currentClipboard = 'No clipboard data yet';
  String _deviceId = 'calculating...';
  String? _authToken;
  bool _isConnected = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastSyncedContent;

  // Real peer data from DiscoveryService
  List<PeerInfo> _discoveredPeers = [];
  int _connectedPeerCount = 0;

  @override
  void initState() {
    super.initState();
    _initCrypto();
    _initDevice();
    _startClipboardMonitoring();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      // Initialize the SyncCoordinator (which initializes P2P and Discovery)
      await SyncCoordinator.instance.initialize();
      await SyncCoordinator.instance.startSync();

      // Listen to discovered peers
      _subscriptions.add(DiscoveryService.instance.peers.listen((peers) {
        if (mounted) {
          setState(() {
            _discoveredPeers = peers;
          });
        }
      }));

      // Listen to connection events for peer count
      _subscriptions.add(P2PService.instance.connectionEvents.listen((event) {
        if (mounted) {
          setState(() {
            _connectedPeerCount = P2PService.instance.peerCount;
          });
        }
      }));

      // Listen to sync events for animations
      _subscriptions.add(SyncCoordinator.instance.syncEvents.listen((event) {
        if (mounted) {
          _graphKey.currentState?.playAnimation();
          setState(() {
            _isSyncing = false;
            _lastSyncTime = event.timestamp;
            _lastSyncedContent = event.contentPreview;
          });
        }
      }));

      // Set callback for received clipboard
      SyncCoordinator.instance.onClipboardReceived = (content) {
        if (mounted) {
          setState(() {
            _currentClipboard = content;
          });
          _clipboardService.setClipboard(content);
        }
      };

      if (mounted) {
        setState(() {
          _connectedPeerCount = P2PService.instance.peerCount;
        });
      }
    } catch (e) {
      debugPrint('Error initializing services: $e');
    }
  }

  Future<void> _initAuth() async {
    try {
      final uri = Uri.parse(_urlController.text);
      final baseUrl = 'http://${uri.host}:${uri.port}';

      final token = await _authService.getOrRegister(baseUrl);
      if (mounted) {
        setState(() {
          _authToken = token;
        });
      }
    } catch (e) {
      debugPrint('Auth initialization failed: $e');
    }
  }

  void _initCrypto() {
    _cryptoService = CryptoService();
  }

  Future<void> _initDevice() async {
    final id = await _deviceService.getDeviceId();
    if (mounted) {
      setState(() {
        _deviceId = id;
      });
    }
  }

  void _startClipboardMonitoring() {
    _clipboardService.startMonitoring();
    _subscriptions.add(_clipboardService.onClipboardChange.listen((text) {
      if (mounted) {
        setState(() {
          _currentClipboard = text;
        });
        if (_isConnected) {
          _triggerSyncAnimation(text);
          _wsService.sendEncrypted(
            content: text,
            sender: _deviceId,
          );
        }
        // Also send via P2P if available
        if (SyncCoordinator.instance.isInitialized) {
          _triggerSyncAnimation(text);
          SyncCoordinator.instance.sendClipboard(text);
        }
      }
    }));
  }

  void _triggerSyncAnimation(String content) {
    setState(() {
      _isSyncing = true;
    });
    _graphKey.currentState?.playAnimation();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _lastSyncTime = DateTime.now();
          _lastSyncedContent =
              content.length > 30 ? '${content.substring(0, 30)}...' : content;
        });
      }
    });
  }

  Future<void> _connect() async {
    try {
      await _initAuth();

      if (_authToken == null) {
        throw Exception('Authentication failed');
      }

      _wsService.connect(
        _urlController.text,
        cryptoService: _cryptoService,
        token: _authToken,
      );
      setState(() {
        _connectionStatus = 'Connected (🔐 Encrypted)';
        _isConnected = true;
      });

      // We track this one separately via logic control, but ideally wsService manages its own stream
      // _wsService.messages returns a stream that closes on disconnect.
      _subscriptions.add(_wsService.messages.listen(
        (message) async {
          try {
            final data = jsonDecode(message.toString());
            if (data is Map && data['type'] == 'clipboard') {
              final sender = data['sender'] as String;

              if (sender == _deviceId) return;

              final content =
                  await _wsService.decryptMessage(data as Map<String, dynamic>);
              if (content == null) {
                debugPrint('Failed to decrypt message');
                return;
              }

              if (mounted) {
                _triggerSyncAnimation(content);
                setState(() {
                  _currentClipboard = content;
                });
                _clipboardService.setClipboard(content);
              }
            }
          } catch (e) {
            debugPrint('Error parsing message: $e');
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _connectionStatus = 'Error: $error';
              _isConnected = false;
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _connectionStatus = 'Disconnected';
              _isConnected = false;
            });
          }
        },
      ));
    } catch (e) {
      setState(() {
        _connectionStatus = 'Failed to connect: $e';
        _isConnected = false;
      });
    }
  }

  void _disconnect() {
    _wsService.dispose();
    setState(() {
      _connectionStatus = 'Disconnected';
      _isConnected = false;
    });
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty && _isConnected) {
      _triggerSyncAnimation(_messageController.text);
      _wsService.sendEncrypted(
        content: _messageController.text,
        sender: _deviceId,
      );
      _messageController.clear();
    }
    // Also send via P2P
    if (_messageController.text.isNotEmpty &&
        SyncCoordinator.instance.isInitialized) {
      _triggerSyncAnimation(_messageController.text);
      SyncCoordinator.instance.sendClipboard(_messageController.text);
      _messageController.clear();
    }
  }

  void _handlePeerConnect(PeerData peer) {
    // Find the real PeerInfo and connect
    final realPeer =
        _discoveredPeers.where((p) => p.deviceId == peer.deviceId).firstOrNull;
    if (realPeer != null) {
      P2PService.instance.connectToPeer(realPeer);
    }
  }

  void _handlePeerDisconnect(PeerData peer) {
    debugPrint('Disconnecting from peer: ${peer.deviceName}');
    // P2P disconnect would need to be implemented in P2PService
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _wsService.dispose();
    _clipboardService.dispose();
    _urlController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Build network nodes from real discovered peers
    final networkNodes = [
      DeviceNode(
        id: 'self',
        name: _deviceId.length > 8 ? _deviceId.substring(0, 8) : _deviceId,
        isThisDevice: true,
        isConnected: true,
      ),
      ..._discoveredPeers.map((peer) {
        final isConnected = P2PService.instance.connectedPeers.any(
          (p) => p.address == peer.addresses.firstOrNull,
        );
        return DeviceNode(
          id: peer.deviceId,
          name: peer.deviceName,
          isThisDevice: false,
          isConnected: isConnected,
        );
      }),
    ];

    // Convert PeerInfo to PeerData for the widget
    final peerDataList = _discoveredPeers.map((peer) {
      final isConnected = P2PService.instance.connectedPeers.any(
        (p) => p.address == peer.addresses.firstOrNull,
      );
      return PeerData(
        deviceId: peer.deviceId,
        deviceName: peer.deviceName,
        address: peer.addresses.isNotEmpty ? peer.addresses.first : 'Unknown',
        port: peer.port,
        isConnected: isConnected,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SyncMist'),
        centerTitle: true,
        actions: [
          StatusBadge(
            isConnected: _isConnected || _connectedPeerCount > 0,
            peerCount: _connectedPeerCount,
          ),
          const SizedBox(width: 8),
          const EncryptionBadge(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Pair Device',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PairingScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Network Graph Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Network',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        height: 200,
                        width: 200,
                        child: NetworkGraph(
                          key: _graphKey,
                          devices: networkNodes,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sync Indicator Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SyncIndicator(
                  isSyncing: _isSyncing,
                  lastSyncTime: _lastSyncTime,
                  lastSyncedContent: _lastSyncedContent,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Connection URL TextField
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'WebSocket URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              enabled: !_isConnected,
            ),
            const SizedBox(height: 12),

            // Connect/Disconnect Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isConnected ? _disconnect : _connect,
                icon: Icon(_isConnected ? Icons.link_off : Icons.link),
                label: Text(_isConnected ? 'Disconnect' : 'Connect'),
              ),
            ),
            const SizedBox(height: 16),

            // Connection Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _isConnected ? Icons.cloud_done : Icons.cloud_off,
                      color:
                          _isConnected ? Colors.green : theme.colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: theme.textTheme.labelMedium,
                        ),
                        Text(
                          _connectionStatus,
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Current Clipboard Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.content_paste,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Current Clipboard',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentClipboard,
                        style: theme.textTheme.bodyLarge,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nearby Devices Section
            Text(
              'Nearby Devices (${peerDataList.length})',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: PeerList(
                peers: peerDataList,
                onConnect: _handlePeerConnect,
                onDisconnect: _handlePeerDisconnect,
              ),
            ),
            const SizedBox(height: 16),

            // Manual Send Section (for testing)
            Text(
              'Manual Send (Testing)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _graphKey.currentState?.playAnimation();
        },
        tooltip: 'Trigger Sync Animation',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
