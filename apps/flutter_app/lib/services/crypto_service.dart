import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../src/rust/crypto.dart' as rust_crypto;

/// Service for encrypting and decrypting clipboard content
///
/// Uses AES-256-GCM encryption via Rust FFI with X25519 key exchange for pairing
class CryptoService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _keyPrivate = 'keypair_private';
  static const String _keyPublic = 'keypair_public';
  static const String _sharedSecretPrefix = 'shared_secret_';
  static const String _legacyKeyName = 'legacy_encryption_key';

  Uint8List? _cachedPrivateKey;
  Uint8List? _cachedPublicKey;
  Uint8List? _legacyKey; // Temporary fallback key for Phase 2 compatibility

  /// Get or create the device's X25519 keypair
  /// Returns (privateKey, publicKey)
  Future<(Uint8List, Uint8List)> getOrCreateKeypair() async {
    // Check cache first
    if (_cachedPrivateKey != null && _cachedPublicKey != null) {
      return (_cachedPrivateKey!, _cachedPublicKey!);
    }

    // Try to load from secure storage
    final storedPrivate = await _secureStorage.read(key: _keyPrivate);
    final storedPublic = await _secureStorage.read(key: _keyPublic);

    if (storedPrivate != null && storedPublic != null) {
      _cachedPrivateKey = _hexToBytes(storedPrivate);
      _cachedPublicKey = _hexToBytes(storedPublic);
      debugPrint('🔑 Loaded existing keypair from secure storage');
      return (_cachedPrivateKey!, _cachedPublicKey!);
    }

    // Generate new keypair
    debugPrint('🔑 Generating new X25519 keypair...');
    final (secretKey, publicKey) = rust_crypto.generateKeypair();

    // Store in secure storage (hex-encoded)
    await _secureStorage.write(key: _keyPrivate, value: _bytesToHex(secretKey));
    await _secureStorage.write(key: _keyPublic, value: _bytesToHex(publicKey));

    _cachedPrivateKey = Uint8List.fromList(secretKey);
    _cachedPublicKey = Uint8List.fromList(publicKey);

    debugPrint('🔑 Generated and stored new keypair');
    return (_cachedPrivateKey!, _cachedPublicKey!);
  }

  /// Derive shared secret with a paired device and store it
  Future<Uint8List> deriveAndStoreSharedSecret(
    String deviceId,
    Uint8List theirPublicKey,
  ) async {
    final (myPrivateKey, _) = await getOrCreateKeypair();

    // Derive shared secret using X25519 ECDH
    final sharedSecret = rust_crypto.deriveSharedSecret(
      mySecret: myPrivateKey,
      theirPublic: theirPublicKey,
    );

    // Store the shared secret for this device
    await _secureStorage.write(
      key: '$_sharedSecretPrefix$deviceId',
      value: _bytesToHex(sharedSecret),
    );

    debugPrint('🔗 Derived and stored shared secret for device: $deviceId');
    return Uint8List.fromList(sharedSecret);
  }

  /// Get the shared secret for a specific device
  Future<Uint8List?> getSharedSecret(String deviceId) async {
    final stored =
        await _secureStorage.read(key: '$_sharedSecretPrefix$deviceId');
    if (stored == null) return null;
    return _hexToBytes(stored);
  }

  /// Get all paired device IDs
  Future<List<String>> getPairedDeviceIds() async {
    final allKeys = await _secureStorage.readAll();
    return allKeys.keys
        .where((key) => key.startsWith(_sharedSecretPrefix))
        .map((key) => key.substring(_sharedSecretPrefix.length))
        .toList();
  }

  /// Encrypt plaintext using the shared secret with a specific device
  Future<Uint8List> encryptForDevice(String plaintext, String deviceId) async {
    final sharedSecret = await getSharedSecret(deviceId);
    if (sharedSecret == null) {
      throw Exception('No shared secret found for device: $deviceId');
    }
    return rust_crypto.encryptText(plaintext: plaintext, key: sharedSecret);
  }

  /// Decrypt ciphertext using the shared secret from a specific device
  Future<String> decryptFromDevice(
      List<int> ciphertext, String deviceId) async {
    final sharedSecret = await getSharedSecret(deviceId);
    if (sharedSecret == null) {
      throw Exception('No shared secret found for device: $deviceId');
    }
    return rust_crypto.decryptText(ciphertext: ciphertext, key: sharedSecret);
  }

  /// Delete pairing with a specific device
  Future<void> unpairDevice(String deviceId) async {
    await _secureStorage.delete(key: '$_sharedSecretPrefix$deviceId');
    debugPrint('🗑️ Unpaired device: $deviceId');
  }

  // ========== Legacy API (for backward compatibility with Phase 2) ==========

  /// Get or create a legacy encryption key for backward compatibility
  /// TODO: Remove this once all code migrates to device-specific encryption
  Future<Uint8List> _getLegacyKey() async {
    if (_legacyKey != null) return _legacyKey!;

    final stored = await _secureStorage.read(key: _legacyKeyName);
    if (stored != null) {
      _legacyKey = _hexToBytes(stored);
      return _legacyKey!;
    }

    // Generate new legacy key
    final key = rust_crypto.generateKey();
    await _secureStorage.write(key: _legacyKeyName, value: _bytesToHex(key));
    _legacyKey = Uint8List.fromList(key);
    debugPrint('🔐 Generated legacy encryption key for backward compatibility');
    return _legacyKey!;
  }

  /// Encrypt plaintext (legacy method for Phase 2 compatibility)
  /// @deprecated Use encryptForDevice instead
  Future<Uint8List> encrypt(String plaintext) async {
    final key = await _getLegacyKey();
    return rust_crypto.encryptText(plaintext: plaintext, key: key);
  }

  /// Decrypt ciphertext (legacy method for Phase 2 compatibility)
  /// @deprecated Use decryptFromDevice instead
  Future<String> decrypt(List<int> ciphertext) async {
    final key = await _getLegacyKey();
    return rust_crypto.decryptText(ciphertext: ciphertext, key: key);
  }

  // Utility methods
  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Uint8List _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }
}
