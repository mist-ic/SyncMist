import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'crypto_service.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  CryptoService? _cryptoService;

  void connect(String url, {CryptoService? cryptoService}) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _cryptoService = cryptoService;
  }

  /// Send a message (plain JSON if no encryption, encrypted if CryptoService is set)
  void send(dynamic message) {
    if (message is Map || message is List) {
      _channel?.sink.add(jsonEncode(message));
    } else {
      _channel?.sink.add(message);
    }
  }

  /// Send encrypted clipboard content
  void sendEncrypted({
    required String content,
    required String sender,
  }) {
    if (_cryptoService == null) {
      // Fallback to plaintext if no encryption service
      send({
        'type': 'clipboard',
        'content': content,
        'sender': sender,
      });
      return;
    }

    // Encrypt the content
    final ciphertext = _cryptoService!.encrypt(content);

    // Encode to base64 for JSON transport
    final base64Content = base64Encode(ciphertext);

    send({
      'type': 'clipboard',
      'content': base64Content,
      'sender': sender,
      'encrypted': true, // Flag to indicate encryption
    });
  }

  /// Decrypt a received message
  String? decryptMessage(Map<String, dynamic> data) {
    if (_cryptoService == null) {
      // No encryption service, return plaintext
      return data['content'] as String?;
    }

    final isEncrypted = data['encrypted'] == true;
    if (!isEncrypted) {
      // Message is not encrypted
      return data['content'] as String?;
    }

    try {
      final base64Content = data['content'] as String;
      final ciphertext = base64Decode(base64Content);
      return _cryptoService!.decrypt(ciphertext);
    } catch (e) {
      debugPrint('❌ Failed to decrypt message: $e');
      return null;
    }
  }

  Stream get messages => _channel!.stream;

  void dispose() {
    _channel?.sink.close();
  }
}
