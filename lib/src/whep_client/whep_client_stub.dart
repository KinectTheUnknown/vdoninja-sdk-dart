import "dart:async";
import "whep_client_base.dart";

/// Stub WHEPClient implementation for non-web platforms.
class WHEPClientStub implements WHEPClient {
  WHEPClientStub({
    required String endpoint,
    String? authToken,
    bool? audio,
    bool? video,
    bool? trickleIce,
  });

  @override
  Future<dynamic> view() {
    throw UnsupportedError("WHEPClient is only supported on the Web platform.");
  }

  @override
  dynamic getStream() {
    throw UnsupportedError("WHEPClient is only supported on the Web platform.");
  }

  @override
  void muteAudio(bool muted) {
    throw UnsupportedError("WHEPClient is only supported on the Web platform.");
  }

  @override
  void muteVideo(bool muted) {
    throw UnsupportedError("WHEPClient is only supported on the Web platform.");
  }

  @override
  void stop() {
    throw UnsupportedError("WHEPClient is only supported on the Web platform.");
  }

  @override
  Future<dynamic> getStats() {
    throw UnsupportedError("WHEPClient is only supported on the Web platform.");
  }

  @override
  Stream<void> get onConnecting => const Stream.empty();

  @override
  Stream<void> get onConnected => const Stream.empty();

  @override
  Stream<dynamic> get onTrack => const Stream.empty();

  @override
  Stream<String> get onIceState => const Stream.empty();

  @override
  Stream<String> get onConnectionState => const Stream.empty();

  @override
  Stream<dynamic> get onError => const Stream.empty();

  @override
  Stream<void> get onDisconnected => const Stream.empty();

  @override
  Stream<void> get onStopped => const Stream.empty();
}

/// Stub creation function for WHEP client.
WHEPClient createWHEPClient({
  required String endpoint,
  String? authToken,
  bool? audio,
  bool? video,
  bool? trickleIce,
}) {
  return WHEPClientStub(
    endpoint: endpoint,
    authToken: authToken,
    audio: audio,
    video: video,
    trickleIce: trickleIce,
  );
}

/// Stub library check.
bool get isWHEPLibraryLoaded => false;

/// Stub initialization.
Future<void> initializeWHEP({String? cdnUrl}) async {}
