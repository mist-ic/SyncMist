import 'package:flutter/foundation.dart';
import '../src/rust/crypto.dart' as rust_crypto;

/// Service for encrypting and decrypting clipboard content
///
/// Uses AES-256-GCM encryption via Rust FFI
class CryptoService {
  late final Uint8List _key;

  CryptoService() {
    // Generate a random encryption key
    _key = rust_crypto.generateKey();
    // TODO: In the future, derive this key from device pairing
    debugPrint('🔐 Generated encryption key (${_key.length} bytes)');
  }

  /// Encrypt plaintext to ciphertext bytes
  Uint8List encrypt(String plaintext) {
    try {
      return rust_crypto.encryptText(plaintext: plaintext, key: _key);
    } catch (e) {
      debugPrint('❌ Encryption failed: $e');
      rethrow;
    }
  }

  /// Decrypt ciphertext bytes to plaintext
  String decrypt(List<int> ciphertext) {
    try {
      return rust_crypto.decryptText(ciphertext: ciphertext, key: _key);
    } catch (e) {
      debugPrint('❌ Decryption failed: $e');
      rethrow;
    }
  }
}
