import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:syncmist/services/sync_coordinator.dart';
import 'package:syncmist/services/discovery_service.dart';
import 'package:syncmist/services/p2p_service.dart';
import 'package:syncmist/core/interfaces/transport_interface.dart';
import 'package:syncmist/core/interfaces/discovery_interface.dart';

void main() {
  // Set up SharedPreferences mock and enable mock mode before tests
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Enable mock mode to avoid Rust FFI initialization
    TransportInterface.useMock = true;
    DiscoveryInterface.useMock = true;
    CryptoService.useMock = true;
  });

  group('SyncCoordinator', () {
    test('initializes without error', () async {
      // Arrange
      final coordinator = SyncCoordinator.instance;

      // Act & Assert - should not throw
      await expectLater(
        coordinator.initialize(),
        completes,
      );

      expect(coordinator.isInitialized, isTrue);
    });

    test('can send clipboard content', () async {
      // Arrange
      final coordinator = SyncCoordinator.instance;
      if (!coordinator.isInitialized) {
        await coordinator.initialize();
      }
      await coordinator.startSync();

      // Listen for sync events
      final events = <SyncEvent>[];
      final subscription = coordinator.syncEvents.listen(events.add);

      // Act
      await coordinator.sendClipboard('Hello World');

      // Allow time for async operations
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(events, isNotEmpty);
      expect(events.first.direction, equals(SyncDirection.outgoing));
      expect(events.first.contentPreview, contains('Hello'));
      expect(events.first.success, isTrue);

      // Cleanup
      await subscription.cancel();
    });
  });

  group('DiscoveryService', () {
    test('initializes without error', () async {
      // Arrange
      final discovery = DiscoveryService.instance;

      // Act & Assert - should not throw
      await expectLater(
        discovery.initialize(),
        completes,
      );

      expect(discovery.isInitialized, isTrue);
    });

    test('generates and persists device ID', () async {
      // Arrange
      final discovery = DiscoveryService.instance;
      if (!discovery.isInitialized) {
        await discovery.initialize();
      }

      // Act
      final deviceId1 = await discovery.getDeviceId();
      final deviceId2 = await discovery.getDeviceId();

      // Assert - should return same ID
      expect(deviceId1, isNotEmpty);
      expect(deviceId1, equals(deviceId2));
    });

    test('mock peers appear after starting discovery', () async {
      // Arrange
      final discovery = DiscoveryService.instance;
      if (!discovery.isInitialized) {
        await discovery.initialize();
      }

      // Listen for peers
      final completer = Completer<List>();
      discovery.peers.listen((peers) {
        if (peers.isNotEmpty && !completer.isCompleted) {
          completer.complete(peers);
        }
      });

      // Act
      await discovery.startDiscovery();

      // Wait for mock peers (should appear after ~1 second)
      final peers = await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () => [],
      );

      // Assert
      expect(peers, isNotEmpty);
      expect(peers.length, equals(2)); // Mock returns 2 peers

      // Cleanup
      await discovery.stopDiscovery();
    });
  });

  group('P2PService', () {
    test('initializes without error', () async {
      // Arrange
      final p2p = P2PService.instance;

      // Act & Assert
      await expectLater(
        p2p.initialize(),
        completes,
      );

      expect(p2p.isInitialized, isTrue);
    });

    test('can start as server', () async {
      // Arrange
      final p2p = P2PService.instance;
      if (!p2p.isInitialized) {
        await p2p.initialize();
      }

      // Act
      await p2p.startAsServer(port: 9877);

      // Assert
      expect(p2p.isServer, isTrue);
    });
  });
}
