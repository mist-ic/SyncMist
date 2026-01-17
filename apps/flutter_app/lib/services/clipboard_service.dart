import 'dart:async';
import 'package:flutter/services.dart';

/// Clipboard service using Flutter's built-in Clipboard class.
/// This works on all platforms without native code compilation.
/// For Phase 1 tracer bullet - text only.
/// TODO: Switch to super_clipboard in Phase 4/5 for rich clipboard support.
class ClipboardService {
  String? _lastClipboard;
  final _controller = StreamController<String>.broadcast();
  Timer? _pollTimer;
  bool _ignoreNextChange = false;

  Stream<String> get onClipboardChange => _controller.stream;

  void startMonitoring() {
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      try {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final text = data?.text;
        if (text != null && text.isNotEmpty && text != _lastClipboard) {
          if (_ignoreNextChange) {
            _ignoreNextChange = false;
            _lastClipboard = text;
            return;
          }
          _lastClipboard = text;
          _controller.add(text);
        }
      } catch (e) {
        // Clipboard access may fail on some platforms, ignore
      }
    });
  }

  Future<void> setClipboard(String text) async {
    _lastClipboard = text; // Avoid loop
    _ignoreNextChange = true;
    await Clipboard.setData(ClipboardData(text: text));
  }

  void dispose() {
    _pollTimer?.cancel();
    _controller.close();
  }
}
