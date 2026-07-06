import "package:flutter_test/flutter_test.dart";
import "package:vdoninja_sdk/vdoninja_sdk.dart";

void main() {
  group("VDONinjaSDK VM/Native Stub Tests", () {
    test("isSDKLoaded returns false on native VM", () {
      expect(VDONinjaSDK.isSDKLoaded, isFalse);
    });

    test("initialize resolves successfully as a no-op on VM", () async {
      await expectLater(VDONinjaSDK.initialize(), completes);
    });

    test("instantiates VDONinjaSDK stub correctly on VM", () {
      final sdk = VDONinjaSDK(
        host: "wss://test.vdo.ninja",
        room: "test_room",
        debug: true,
      );

      expect(sdk, isNotNull);
      expect(sdk.isConnected, isFalse);
      expect(sdk.isRoomJoined, isFalse);
      expect(sdk.isPublishing, isFalse);
      expect(sdk.room, isNull);
      expect(sdk.streamID, isNull);
      expect(sdk.uuid, isNull);
    });

    test("instantiates VDONinjaSDK stub correctly on VM with union type parameters", () {
      final sdk = VDONinjaSDK(
        host: "wss://test.vdo.ninja",
        room: "test_room",
        password: .disable,
        turnServers: .list([
          .new(urls: ["turn:test.vdo.ninja:443"]),
          const .object({
            "urls": "stun:test2.vdo.ninja:3478",
            "username": "user",
          }),
        ]),
        stunServers: [
          .new(urls: ["stun:stun.l.google.com:19302"]),
        ],
        allowChunked: .integer(16384),
        debug: true,
      );

      expect(sdk, isNotNull);
    });

    test("connect throws UnsupportedError on native VM", () async {
      final sdk = VDONinjaSDK();
      expect(
        () => sdk.connect(host: "wss://test.vdo.ninja", room: "room"),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test("publish throws UnsupportedError on native VM", () async {
      final sdk = VDONinjaSDK();
      expect(
        () => sdk.publish(Object()),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test("announce throws UnsupportedError on native VM", () async {
      final sdk = VDONinjaSDK();
      expect(
        () => sdk.announce(streamID: "test"),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test("stopPublishing throws UnsupportedError on native VM", () {
      final sdk = VDONinjaSDK();
      expect(
        () => sdk.stopPublishing(),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test("quickPublish throws UnsupportedError on native VM", () async {
      final sdk = VDONinjaSDK();
      expect(
        () => sdk.quickPublish(Object()),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test("quickView throws UnsupportedError on native VM", () async {
      final sdk = VDONinjaSDK();
      expect(
        () => sdk.quickView(streamID: "test"),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test("quickSubscribe throws UnsupportedError on native VM", () async {
      final sdk = VDONinjaSDK();
      expect(
        () => sdk.quickSubscribe(streamID: "test"),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test("autoConnect throws UnsupportedError on native VM", () async {
      final sdk = VDONinjaSDK();
      expect(
        () => sdk.autoConnect(room: "test"),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test("getStreams returns empty list on VM", () {
      final sdk = VDONinjaSDK();
      expect(sdk.getStreams(), isEmpty);
    });

    test("getStreamInfo returns null on VM", () {
      final sdk = VDONinjaSDK();
      expect(sdk.getStreamInfo("test"), isNull);
    });

    test("event streams are empty on VM", () async {
      final sdk = VDONinjaSDK();
      final onConnectedList = await sdk.onConnected.toList();
      expect(onConnectedList, isEmpty);
    });

  });
}
