import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';
import 'dart:convert';
import '../services/crypto_service.dart';
import '../services/device_service.dart';

/// Pairing screen with QR code generation and scanning
class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CryptoService _cryptoService = CryptoService();
  final DeviceService _deviceService = DeviceService();
  Timer? _countdownTimer;

  String? _qrData;
  String? _deviceId;
  String? _deviceName;
  DateTime? _qrGeneratedAt;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeQRCode();
    // Start countdown timer - updates UI every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initializeQRCode() async {
    try {
      // Get device info
      _deviceId = await _deviceService.getDeviceId();
      _deviceName = await _deviceService.getDeviceName();

      // Get or create keypair
      final (_, publicKey) = await _cryptoService.getOrCreateKeypair();

      // Create QR code JSON per protocol spec
      final qrJson = {
        'proto': 'syncmist',
        'v': 1,
        'pk': base64UrlEncode(publicKey)
            .replaceAll('=', ''), // Base64URL without padding
        'id': _deviceId,
        'name': _deviceName,
        'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unix timestamp
      };

      setState(() {
        _qrData = jsonEncode(qrJson);
        _qrGeneratedAt = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to initialize QR code: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate QR code: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.linux ||
        Theme.of(context).platform == TargetPlatform.macOS;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair Device'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(icon: Icon(Icons.qr_code), text: 'Show My QR'),
            Tab(
              icon: Icon(isDesktop ? Icons.keyboard : Icons.qr_code_scanner),
              text: isDesktop ? 'Enter Code' : 'Scan QR',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildShowQRTab(),
          isDesktop ? _buildManualEntryTab() : _buildScanQRTab(),
        ],
      ),
    );
  }

  Widget _buildManualEntryTab() {
    final TextEditingController codeController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.keyboard, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Enter the pairing code from the other device',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Copy the QR data from the other device and paste it here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: codeController,
            decoration: const InputDecoration(
              labelText: 'Pairing Code (JSON)',
              hintText: 'Paste the QR code data here...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              if (codeController.text.isNotEmpty) {
                _handleQRScanned(codeController.text);
              }
            },
            icon: const Icon(Icons.link),
            label: const Text('Pair Device'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowQRTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_qrData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to generate QR code'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeQRCode,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Calculate remaining time (5 minutes = 300 seconds)
    final timeRemaining = _qrGeneratedAt != null
        ? 300 - DateTime.now().difference(_qrGeneratedAt!).inSeconds
        : 0;

    final isExpired = timeRemaining <= 0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _deviceName ?? 'Unknown Device',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Scan this QR code from another device to pair',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isExpired ? Colors.red : Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  QrImageView(
                    data: _qrData!,
                    version: QrVersions.auto,
                    size: 250,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                  if (isExpired)
                    Container(
                      width: 250,
                      height: 250,
                      color: Colors.black.withOpacity(0.7),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer_off, size: 48, color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            'EXPIRED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Countdown timer
            if (!isExpired)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Expires in ${_formatTime(timeRemaining)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            if (isExpired)
              ElevatedButton.icon(
                onPressed: _initializeQRCode,
                icon: const Icon(Icons.refresh),
                label: const Text('Regenerate QR Code'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            const SizedBox(height: 24),
            // Copy button for manual pairing
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _qrData!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('QR data copied to clipboard!')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy QR Data'),
            ),
            const SizedBox(height: 16),
            // Device ID (for debugging)
            Text(
              'Device ID: ${_deviceId?.substring(0, 8)}...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanQRTab() {
    return MobileScanner(
      onDetect: (capture) {
        final List<Barcode> barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          if (barcode.rawValue != null) {
            _handleQRScanned(barcode.rawValue!);
            break;
          }
        }
      },
      errorBuilder: (context, error, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Camera Error: ${error.errorCode}'),
              const SizedBox(height: 8),
              Text(
                error.errorDetails?.message ?? 'Unknown error',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
      placeholderBuilder: (context, child) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Future<void> _handleQRScanned(String qrData) async {
    try {
      // Parse QR JSON
      final Map<String, dynamic> qrJson = jsonDecode(qrData);

      // Validate protocol
      if (qrJson['proto'] != 'syncmist') {
        throw Exception('Invalid QR code: not a SyncMist pairing code');
      }

      // Validate version
      if (qrJson['v'] != 1) {
        throw Exception('Unsupported protocol version: ${qrJson['v']}');
      }

      // Validate timestamp (must be within 5 minutes)
      final timestamp = qrJson['ts'] as int;
      final qrTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      final age = DateTime.now().difference(qrTime).inSeconds;
      if (age > 300) {
        throw Exception('QR code expired (${age}s old). Please regenerate.');
      }
      if (age < -60) {
        throw Exception(
            'QR code timestamp is in the future. Check device clocks.');
      }

      // Extract device info
      final remoteDeviceId = qrJson['id'] as String;
      final remoteDeviceName = qrJson['name'] as String;
      final remotePublicKeyB64 = qrJson['pk'] as String;

      // Decode public key (Base64URL without padding)
      final remotePublicKey = base64Url.decode(
        remotePublicKeyB64.padRight(
          (remotePublicKeyB64.length + 3) & ~3,
          '=',
        ),
      );

      if (remotePublicKey.length != 32) {
        throw Exception('Invalid public key length: ${remotePublicKey.length}');
      }

      // Derive and store shared secret
      await _cryptoService.deriveAndStoreSharedSecret(
        remoteDeviceId,
        Uint8List.fromList(remotePublicKey),
      );

      // Show success dialog
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Pairing Successful'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Successfully paired with:'),
                const SizedBox(height: 8),
                Text(
                  remoteDeviceName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Device ID: ${remoteDeviceId.substring(0, 12)}...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to home screen
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ QR scan failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
