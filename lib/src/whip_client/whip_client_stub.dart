import "dart:async";
import "whip_client_base.dart";

/// Stub WHIPClient implementation for non-web platforms.
class WHIPClientStub implements WHIPClient {
  WHIPClientStub({
    required String endpoint,
    String? authToken,
    String? videoCodec,
    int? videoBitrate,
    int? audioBitrate,
    bool? trickleIce,
  });

  @override
  Future<void> publish(dynamic stream) {
    throw UnsupportedError("WHIPClient is only supported on the Web platform.");
  }

  @override
  Future<void> replaceTrack(dynamic oldTrack, dynamic newTrack) {
    throw UnsupportedError("WHIPClient is only supported on the Web platform.");
  }

  @override
  void stop() {
    throw UnsupportedError("WHIPClient is only supported on the Web platform.");
  }

  @override
  Future<dynamic> getStats() {
    throw UnsupportedError("WHIPClient is only supported on the Web platform.");
  }

  @override
  Future<void> restartIce() {
    throw UnsupportedError("WHIPClient is only supported on the Web platform.");
  }

  @override
  Stream<void> get onConnecting => const Stream.empty();

  @override
  Stream<void> get onConnected => const Stream.empty();

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

/// Stub creation function for WHIP client.
WHIPClient createWHIPClient({
  required String endpoint,
  String? authToken,
  String? videoCodec,
  int? videoBitrate,
  int? audioBitrate,
  bool? trickleIce,
}) {
  return WHIPClientStub(
    endpoint: endpoint,
    authToken: authToken,
    videoCodec: videoCodec,
    videoBitrate: videoBitrate,
    audioBitrate: audioBitrate,
    trickleIce: trickleIce,
  );
}

/// Stub library check.
bool get isWHIPLibraryLoaded => false;

/// Stub initialization.
Future<void> initializeWHIP({String? cdnUrl}) async {}
