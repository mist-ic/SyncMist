import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'crypto_service.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  CryptoService? _cryptoService;

  void connect(String url, {CryptoService? cryptoService, String? token}) {
    String finalUrl = url;
    if (token != null && token.isNotEmpty) {
      final uri = Uri.parse(url);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      queryParams['token'] = token;
      finalUrl = uri.replace(queryParameters: queryParams).toString();
    }

    debugPrint('Connecting to WebSocket: $finalUrl');
    _channel = WebSocketChannel.connect(Uri.parse(finalUrl));
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

  /// Send clipboard content (plaintext for now, encryption after pairing complete)
  Future<void> sendEncrypted({
    required String content,
    required String sender,
  }) async {
    // TODO: Re-enable encryption once pairing establishes shared secrets
    // For now, send plaintext so clipboard sync works across devices
    send({
      'type': 'clipboard',
      'content': content,
      'sender': sender,
      'encrypted': false,
    });
  }

  /// Decrypt a received message
  Future<String?> decryptMessage(Map<String, dynamic> data) async {
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
      return await _cryptoService!.decrypt(ciphertext);
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
