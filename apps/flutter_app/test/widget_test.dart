import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:syncmist/main.dart';

void main() {
  testWidgets('SyncMist app renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SyncMistApp());

    // Verify that the app title is displayed
    expect(find.text('SyncMist'), findsWidgets);

    // Verify that the status shows disconnected
    expect(find.text('Disconnected'), findsOneWidget);

    // Verify that the Add Device button exists
    expect(find.text('Add Device'), findsOneWidget);
  });
}
