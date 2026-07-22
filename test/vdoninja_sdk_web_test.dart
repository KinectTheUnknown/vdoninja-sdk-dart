@TestOn("browser")
library;

import "package:flutter_test/flutter_test.dart";
import "package:web/web.dart" as web;
import "package:vdoninja_sdk/vdoninja_sdk.dart";
import "package:vdoninja_sdk/whip_client.dart";
import "package:vdoninja_sdk/whep_client.dart";

void injectJSMocks() {
  final script = web.document.createElement("script") as web.HTMLScriptElement;
  script.text = """
    class VDONinjaSDK {
      constructor(options) {
        this.options = options;
        this.state = {
          connected: false,
          roomJoined: false,
          publishing: false,
          room: null,
          streamID: null,
          uuid: null
        };
      }
      connect(options) { return Promise.resolve(); }
      disconnect() {}
      joinRoom(options) { return Promise.resolve(); }
      leaveRoom() {}
      publish(stream, options) { return Promise.resolve(); }
      addEventListener(type, callback) {}
      removeEventListener(type, callback) {}
    }
    window.VDONinjaSDK = VDONinjaSDK;

    class WHIPClient {
      constructor(endpoint, options) {}
      publish(stream) { return Promise.resolve(); }
      stop() {}
      addEventListener(type, callback) {}
      removeEventListener(type, callback) {}
    }
    window.WHIPClient = WHIPClient;

    class WHEPClient {
      constructor(endpoint, options) {}
      view() { return Promise.resolve(); }
      stop() {}
      addEventListener(type, callback) {}
      removeEventListener(type, callback) {}
    }
    window.WHEPClient = WHEPClient;
  """;
  web.document.head!.appendChild(script);
}

void main() {
  setUpAll(() {
    injectJSMocks();
  });

  group("VDO.Ninja SDK Web Integration Tests with JS Mocks", () {
    test("isSDKLoaded is true after mock injection", () {
      expect(VDONinjaSDK.isSDKLoaded, isTrue);
    });

    test("instantiates VDONinjaSDK correctly on Web", () {
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
    });

    test(
      "WHIPClient isLibraryLoaded is true and instantiates successfully",
      () {
        expect(WHIPClient.isLibraryLoaded, isTrue);

        final client = WHIPClient(endpoint: "https://whip.endpoint");
        expect(client, isNotNull);
      },
    );

    test(
      "WHEPClient isLibraryLoaded is true and instantiates successfully",
      () {
        expect(WHEPClient.isLibraryLoaded, isTrue);

        final client = WHEPClient(endpoint: "https://whep.endpoint");
        expect(client, isNotNull);
      },
    );
  });
}
