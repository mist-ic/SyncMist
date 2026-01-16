import 'package:flutter_test/flutter_test.dart';
import 'package:syncmist/services/crypto_service.dart';
import 'package:syncmist/src/rust/frb_generated.dart';

void main() {
  // We need to initialize the Rust library before running tests that use it
  setUpAll(() async {
    await RustLib.init();
  });

  group('CryptoService Tests', () {
    test('Encryption and Decryption Roundtrip', () async {
      final cryptoService = CryptoService();
      const plaintext = "Hello from Flutter with Rust encryption!";

      final ciphertext = await cryptoService.encrypt(plaintext);
      expect(ciphertext, isNot(plaintext));
      expect(ciphertext.length, greaterThan(plaintext.length));

      final decrypted = await cryptoService.decrypt(ciphertext);
      expect(decrypted, equals(plaintext));
    });

    test('Ciphertext is different for same plaintext (nonce randomization)',
        () async {
      final cryptoService = CryptoService();
      const plaintext = "Stable content";

      final ciphertext1 = await cryptoService.encrypt(plaintext);
      final ciphertext2 = await cryptoService.encrypt(plaintext);

      expect(ciphertext1, isNot(equals(ciphertext2)));
    });
  });
}
