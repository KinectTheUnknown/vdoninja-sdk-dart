@TestOn("browser")
library;

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:vdoninja_sdk/vdoninja_sdk.dart";

import "integration_test_app.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint("FLUTTER ERROR: ${details.exception}");
    debugPrint(details.stack.toString());
  };

  group("VDO.Ninja SDK Integration Test App", () {
    testWidgets("app renders with connection form", (tester) async {
      await tester.pumpWidget(const VDONinjaTestApp());
      await tester.pumpAndSettle();

      // Title is visible
      expect(find.byKey(const Key("app-title")), findsOneWidget);

      // Connection form fields are present
      expect(find.byKey(const Key("host-field")), findsOneWidget);
      expect(find.byKey(const Key("room-field")), findsOneWidget);
      expect(find.byKey(const Key("password-field")), findsOneWidget);

      // Connect button is present
      expect(find.byKey(const Key("connect-btn")), findsOneWidget);

      // Status badge shows disconnected
      expect(find.byKey(const Key("status-badge")), findsOneWidget);
      expect(find.text("Disconnected"), findsOneWidget);

      // Event log is empty
      expect(find.text("No events yet"), findsOneWidget);
    });

    testWidgets("host field has default value", (tester) async {
      await tester.pumpWidget(const VDONinjaTestApp());
      await tester.pumpAndSettle();

      final hostField =
          tester.widget<TextField>(find.byKey(const Key("host-field")));
      expect(hostField.controller?.text, "wss://wss.vdo.ninja");
    });

    testWidgets("can enter room and password", (tester) async {
      await tester.pumpWidget(const VDONinjaTestApp());
      await tester.pumpAndSettle();

      // Enter room name
      await tester.enterText(find.byKey(const Key("room-field")), "test-room");
      await tester.pumpAndSettle();

      // Enter password
      await tester.enterText(
          find.byKey(const Key("password-field")), "secret123");
      await tester.pumpAndSettle();

      final roomField =
          tester.widget<TextField>(find.byKey(const Key("room-field")));
      expect(roomField.controller?.text, "test-room");

      final passwordField =
          tester.widget<TextField>(find.byKey(const Key("password-field")));
      expect(passwordField.controller?.text, "secret123");
    });

    testWidgets("shows error log when room is empty and connect pressed",
        (tester) async {
      await tester.pumpWidget(const VDONinjaTestApp());
      await tester.pumpAndSettle();

      // Wait for SDK initialization to complete
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Press connect without entering room
      await tester.tap(find.byKey(const Key("connect-btn")));
      await tester.pumpAndSettle();

      // Should show an error event in the log
      expect(find.text("Room name is required"), findsOneWidget);
    });

    testWidgets("clear log button works", (tester) async {
      await tester.pumpWidget(const VDONinjaTestApp());
      await tester.pumpAndSettle();

      // Wait for SDK initialization log entry
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Trigger an error log entry
      await tester.tap(find.byKey(const Key("connect-btn")));
      await tester.pumpAndSettle();

      // Verify at least one entry exists
      expect(find.text("No events yet"), findsNothing);

      // Clear the log
      await tester.tap(find.byKey(const Key("clear-log-btn")));
      await tester.pumpAndSettle();

      // Log should be empty again
      expect(find.text("No events yet"), findsOneWidget);
    });

    testWidgets("SDK isSDKLoaded returns true after initialization",
        (tester) async {
      await tester.pumpWidget(const VDONinjaTestApp());
      await tester.pumpAndSettle();

      // Wait for SDK initialization
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(VDONinjaSDK.isSDKLoaded, isTrue);
    });

    testWidgets("SDK instantiates with room config", (tester) async {
      await tester.pumpWidget(const VDONinjaTestApp());
      await tester.pumpAndSettle();

      // Wait for SDK initialization
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      final sdk = VDONinjaSDK(
        host: "wss://wss.vdo.ninja",
        room: "test-room",
        password: VDONinjaPassword.string("secret"),
        debug: true,
      );

      expect(sdk, isNotNull);
      expect(sdk.isConnected, isFalse);
      expect(sdk.isRoomJoined, isFalse);
      expect(sdk.isPublishing, isFalse);
    });

    testWidgets("SDK event streams are accessible", (tester) async {
      await tester.pumpWidget(const VDONinjaTestApp());
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      final sdk = VDONinjaSDK(room: "test-room");

      // Verify all event streams are non-null and accessible
      expect(sdk.onConnected, isA<Stream<void>>());
      expect(sdk.onDisconnected, isA<Stream<void>>());
      expect(sdk.onReconnecting, isA<Stream<Map<String, dynamic>>>());
      expect(sdk.onReconnected, isA<Stream<void>>());
      expect(sdk.onReconnectFailed, isA<Stream<void>>());
      expect(sdk.onRoomJoined, isA<Stream<Map<String, dynamic>>>());
      expect(sdk.onRoomLeft, isA<Stream<Map<String, dynamic>>>());
      expect(sdk.onPublishing, isA<Stream<Map<String, dynamic>>>());
      expect(sdk.onViewingStopped, isA<Stream<Map<String, dynamic>>>());
      expect(sdk.onTrack, isA<Stream<VDONinjaTrackEvent>>());
      expect(sdk.onDataReceived, isA<Stream<VDONinjaDataReceivedEvent>>());
      expect(sdk.onPeerConnected, isA<Stream<Map<String, dynamic>>>());
      expect(sdk.onPeerLatency, isA<Stream<VDONinjaPeerLatencyEvent>>());
      expect(sdk.onPeerInfo, isA<Stream<VDONinjaPeerInfoEvent>>());
      expect(sdk.onRemoteVideoMuteState,
          isA<Stream<VDONinjaRemoteVideoMuteStateEvent>>());
      expect(sdk.onError, isA<Stream<VDONinjaErrorEvent>>());
    });

    testWidgets("VDONinjaPassword types work correctly", (tester) async {
      await tester.pumpWidget(const VDONinjaTestApp());
      await tester.pumpAndSettle();

      // String password
      const pw = VDONinjaPassword.string("abc");
      expect(pw.value, "abc");
      expect(pw, isA<VDONinjaPasswordString>());

      // Boolean password (disable)
      const disable = VDONinjaPassword.boolean(false);
      expect(disable.value, false);
      expect(disable, isA<VDONinjaPasswordBoolean>());

      // Static disable
      expect(VDONinjaPassword.disable.value, false);

      // Equality
      expect(const VDONinjaPassword.string("abc"),
          const VDONinjaPassword.string("abc"));
      expect(const VDONinjaPassword.string("abc"),
          isNot(const VDONinjaPassword.string("xyz")));
    });

    testWidgets("VDONinjaIceServer configuration works", (tester) async {
      await tester.pumpWidget(const VDONinjaTestApp());
      await tester.pumpAndSettle();

      // Standard constructor
      final server = VDONinjaIceServer(
        urls: ["stun:stun.l.google.com:19302"],
        username: "user",
        credential: "pass",
      );
      expect(server.value, isA<Map<String, dynamic>>());
      expect((server.value as Map)["urls"], ["stun:stun.l.google.com:19302"]);

      // Object constructor
      const rawServer = VDONinjaIceServer.object({"urls": ["stun:example.com"]});
      expect(rawServer.value, {"urls": ["stun:example.com"]});
    });

    testWidgets("VDONinjaTurnServers configuration works", (tester) async {
      await tester.pumpWidget(const VDONinjaTestApp());
      await tester.pumpAndSettle();

      // Disable
      expect(VDONinjaTurnServers.disable.value, false);

      // List
      const servers = VDONinjaTurnServers.list([
        VDONinjaIceServer.object({"urls": ["turn:example.com"]}),
      ]);
      expect(servers.value, isA<List<VDONinjaIceServer>>());
      expect(servers.value.length, 1);
    });
  });
}
