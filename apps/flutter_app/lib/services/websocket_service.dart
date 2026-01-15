import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  void connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
  }

  void send(dynamic message) {
    if (message is Map || message is List) {
      _channel?.sink.add(jsonEncode(message));
    } else {
      _channel?.sink.add(message);
    }
  }

  Stream get messages => _channel!.stream;

  void dispose() {
    _channel?.sink.close();
  }
}
