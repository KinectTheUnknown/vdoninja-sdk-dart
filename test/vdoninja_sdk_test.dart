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

    test(
      "instantiates VDONinjaSDK stub correctly on VM with union type parameters",
      () {
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
      },
    );

    test("connect throws UnsupportedError on native VM", () async {
      final sdk = VDONinjaSDK();
      expect(
        () => sdk.connect(host: "wss://test.vdo.ninja", room: "room"),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test("publish throws UnsupportedError on native VM", () async {
      final sdk = VDONinjaSDK();
      expect(() => sdk.publish(Object()), throwsA(isA<UnsupportedError>()));
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
      expect(() => sdk.stopPublishing(), throwsA(isA<UnsupportedError>()));
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

    group("Model Tests", () {
      test("VDONinjaPassword masking and equality", () {
        const passwordString = VDONinjaPassword.string("secret");
        expect(
          passwordString.toString(),
          equals("VDONinjaPassword.string(***)"),
        );
        expect(passwordString, equals(const VDONinjaPassword.string("secret")));
        expect(
          passwordString,
          isNot(equals(const VDONinjaPassword.string("other"))),
        );

        const passwordBool = VDONinjaPassword.boolean(false);
        expect(
          passwordBool.toString(),
          equals("VDONinjaPassword.boolean(false)"),
        );
        expect(passwordBool, equals(const VDONinjaPassword.boolean(false)));
      });

      test("VDONinjaIceServer credential masking and equality", () {
        final serverConfig = VDONinjaIceServer(
          urls: ["turn:test.vdo.ninja:443"],
          username: "user",
          credential: "password123",
        );
        expect(serverConfig.toString(), contains("credential: ***"));
        expect(serverConfig.toString(), isNot(contains("password123")));

        final serverObject = VDONinjaIceServer.object({
          "urls": "turn:test.vdo.ninja:443",
          "username": "user",
          "credential": "password123",
        });
        expect(serverObject.toString(), contains("credential: ***"));
        expect(serverObject.toString(), isNot(contains("password123")));

        final sameServerConfig = VDONinjaIceServer(
          urls: ["turn:test.vdo.ninja:443"],
          username: "user",
          credential: "password123",
        );
        expect(serverConfig, equals(sameServerConfig));
      });

      test("VDONinjaTurnServers equality", () {
        final servers1 = VDONinjaTurnServers.list([
          VDONinjaIceServer(urls: ["turn:test.vdo.ninja:443"]),
        ]);
        final servers2 = VDONinjaTurnServers.list([
          VDONinjaIceServer(urls: ["turn:test.vdo.ninja:443"]),
        ]);
        expect(servers1, equals(servers2));
        expect(
          VDONinjaTurnServers.disable,
          equals(VDONinjaTurnServers.disable),
        );
      });
    });

    test("initialize throws ArgumentError for non-HTTPS URL", () async {
      await expectLater(
        VDONinjaSDK.initialize(cdnUrl: "http://example.com/sdk.js"),
        throwsArgumentError,
      );
      await expectLater(
        VDONinjaSDK.initialize(cdnUrl: "//example.com/sdk.js"),
        throwsArgumentError,
      );
    });
  });
}
