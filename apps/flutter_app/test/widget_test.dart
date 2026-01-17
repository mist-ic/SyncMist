import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:syncmist/main.dart';

void main() {
  testWidgets('SyncMistApp builds without error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: Full widget tests require mocking services (WebSocket, Clipboard, Device)
    // For now, we verify the app builds without crashing.
    await tester.pumpWidget(const SyncMistApp());

    // Pump a few frames to let initialization complete
    await tester.pump(const Duration(milliseconds: 100));

    // Basic smoke test - app should build without throwing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
