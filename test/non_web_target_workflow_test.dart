import "dart:convert";
import "package:flutter_test/flutter_test.dart";
import "package:vdoninja_sdk/vdoninja_sdk.dart";

/// A mock controller to simulate sending commands from Dart to the WebView
class MockWebViewController {
  final List<String> evaluatedScripts = [];

  Future<void> runJavaScript(String script) async {
    evaluatedScripts.add(script);
  }

  void sendCommand(String action, [Map<String, dynamic>? data]) {
    final payload = <String, dynamic>{"action": action};
    if (data != null) {
      payload["data"] = data;
    }
    final jsonString = jsonEncode(payload);
    runJavaScript("window.postMessage($jsonString, '*');");
  }
}

void main() {
  group("Non-web target workflow tests", () {
    test("VDONinjaSDK throws UnsupportedError on native VM", () {
      final sdk = VDONinjaSDK();

      expect(
        () => sdk.connect(host: "wss://test.vdo.ninja", room: "room"),
        throwsA(isA<UnsupportedError>()),
      );
      expect(() => sdk.publish(Object()), throwsA(isA<UnsupportedError>()));
    });

    test("Mock WebView channel formats JSON payloads correctly", () async {
      final controller = MockWebViewController();

      // Simulate sending a connect command to the WebView
      controller.sendCommand("connect", {
        "room": "my_room",
        "password": "secret_password",
      });

      expect(controller.evaluatedScripts, isNotEmpty);
      expect(
        controller.evaluatedScripts.first,
        equals(
          "window.postMessage({\"action\":\"connect\",\"data\":{\"room\":\"my_room\",\"password\":\"secret_password\"}}, '*');",
        ),
      );

      // Simulate sending a publish command
      controller.sendCommand("publish", {"streamID": "my_stream_id"});

      expect(controller.evaluatedScripts.length, equals(2));
      expect(
        controller.evaluatedScripts.last,
        equals(
          "window.postMessage({\"action\":\"publish\",\"data\":{\"streamID\":\"my_stream_id\"}}, '*');",
        ),
      );
    });
  });
}
