import "package:flutter_test/flutter_test.dart";
import "package:vdoninja_sdk/whep_client.dart";

void main() {
  group("WHEPClient VM/Native Stub Tests", () {
    test("isLibraryLoaded returns false on native VM", () {
      expect(WHEPClient.isLibraryLoaded, isFalse);
    });

    test("initialize resolves successfully as a no-op on VM", () async {
      await expectLater(WHEPClient.initialize(), completes);
    });

    test("view throws UnsupportedError on native VM", () async {
      final client = WHEPClient(endpoint: "https://test.whep.endpoint");
      expect(() => client.view(), throwsA(isA<UnsupportedError>()));
    });
  });
}
