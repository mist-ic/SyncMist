import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../services/clipboard_service.dart';
import '../services/device_service.dart';
import '../services/crypto_service.dart';
import '../services/auth_service.dart';
import 'pairing_screen.dart';

/// Home Screen with WebSocket integration
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

  String _connectionStatus = 'Disconnected';
  String _currentClipboard = 'No clipboard data yet';
  String _deviceId = 'calculating...';
  String? _authToken;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initCrypto();
    _initDevice();
    // Auth is now done when user presses Connect (after they set the URL)
    _startClipboardMonitoring();
  }

  Future<void> _initAuth() async {
    // Get base URL for registration (same host/port as WS, just HTTP instead of WS)
    final uri = Uri.parse(_urlController.text);
    final baseUrl = 'http://${uri.host}:${uri.port}';

    final token = await _authService.getOrRegister(baseUrl);
    if (mounted) {
      setState(() {
        _authToken = token;
      });
    }
  }

  void _initCrypto() {
    // Rust is already initialized in main.dart
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
    _clipboardService.onClipboardChange.listen((text) {
      if (mounted) {
        setState(() {
          _currentClipboard = text;
        });
        // Sync to WebSocket if connected (with encryption)
        if (_isConnected) {
          _wsService.sendEncrypted(
            content: text,
            sender: _deviceId,
          );
        }
      }
    });
  }

  Future<void> _connect() async {
    try {
      // Get auth token with current URL (not default)
      await _initAuth();

      _wsService.connect(
        _urlController.text,
        cryptoService: _cryptoService,
        token: _authToken,
      );
      setState(() {
        _connectionStatus = 'Connected (🔐 Encrypted)';
        _isConnected = true;
      });

      // Listen for messages (remote clipboard changes)
      _wsService.messages.listen(
        (message) async {
          try {
            final data = jsonDecode(message.toString());
            if (data is Map && data['type'] == 'clipboard') {
              final sender = data['sender'] as String;

              // Loop avoidance: ignore if we are the sender
              if (sender == _deviceId) return;

              // Decrypt the content
              final content =
                  await _wsService.decryptMessage(data as Map<String, dynamic>);
              if (content == null) {
                debugPrint('Failed to decrypt message');
                return;
              }

              if (mounted) {
                setState(() {
                  _currentClipboard = content;
                });
                // Update local clipboard from remote
                _clipboardService.setClipboard(content);
              }
            }
          } catch (e) {
            // Handle non-JSON or malformed messages if necessary
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
      );
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
      _wsService.sendEncrypted(
        content: _messageController.text,
        sender: _deviceId,
      );
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    _wsService.dispose();
    _clipboardService.dispose();
    _urlController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('SyncMist ($_deviceId)'),
        centerTitle: true,
        actions: [
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    enabled: _isConnected,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isConnected ? _sendMessage : null,
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
