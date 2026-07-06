import "package:flutter_test/flutter_test.dart";
import "package:vdoninja_sdk/whip_client.dart";

void main() {
  group("WHIPClient VM/Native Stub Tests", () {
    test("isLibraryLoaded returns false on native VM", () {
      expect(WHIPClient.isLibraryLoaded, isFalse);
    });

    test("initialize resolves successfully as a no-op on VM", () async {
      await expectLater(WHIPClient.initialize(), completes);
    });

    test("publish throws UnsupportedError on native VM", () async {
      final client = WHIPClient(endpoint: "https://test.whip.endpoint");
      expect(
        () => client.publish(Object()),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
