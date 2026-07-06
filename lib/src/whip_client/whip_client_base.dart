import "dart:async";
import "whip_client_stub.dart"
    if (dart.library.js_interop) "whip_client_web.dart" as platform;

/// Base abstract class for WHIP (WebRTC-HTTP Ingestion Protocol) Client.
///
/// Used to publish local MediaStreams to a WHIP-compatible endpoint.
abstract class WHIPClient {
  /// Create a new WHIPClient instance.
  factory WHIPClient({
    /// The WHIP endpoint URL (required).
    required String endpoint,

    /// The Bearer auth token for endpoint authentication.
    String? authToken,

    /// Preferred video codec ('h264', 'vp8', 'vp9', 'av1').
    String? videoCodec,

    /// Target video bitrate in kbps.
    int? videoBitrate,

    /// Target audio bitrate in kbps.
    int? audioBitrate,

    /// Whether to enable trickle ICE (defaults to true).
    bool? trickleIce,
  }) => platform.createWHIPClient(
    endpoint: endpoint,
    authToken: authToken,
    videoCodec: videoCodec,
    videoBitrate: videoBitrate,
    audioBitrate: audioBitrate,
    trickleIce: trickleIce,
  );

  /// Check if the WHIP client library is loaded.
  static bool get isLibraryLoaded => platform.isWHIPLibraryLoaded;

  /// Dynamically load the WHIP client library script from jsDelivr CDN.
  static Future<void> initialize({String? cdnUrl}) => platform.initializeWHIP(cdnUrl: cdnUrl);

  // --- Methods ---

  /// Publish a MediaStream (on web, `web.MediaStream`).
  Future<void> publish(dynamic stream);

  /// Replace a media track mid-session.
  Future<void> replaceTrack(dynamic oldTrack, dynamic newTrack);

  /// Stop publishing and cleanup all resources.
  void stop();

  /// Retrieve the underlying WebRTC stats report.
  Future<dynamic> getStats();

  /// Restart the ICE connection.
  Future<void> restartIce();

  // --- Event Streams ---

  /// Stream fired when starting to connect to the ingest endpoint.
  Stream<void> get onConnecting;

  /// Stream fired when connection is established.
  Stream<void> get onConnected;

  /// Stream fired when ICE state updates.
  Stream<String> get onIceState;

  /// Stream fired when PeerConnection state updates.
  Stream<String> get onConnectionState;

  /// Stream fired when an error occurs during ingest.
  Stream<dynamic> get onError;

  /// Stream fired when connection is closed.
  Stream<void> get onDisconnected;

  /// Stream fired when client is stopped.
  Stream<void> get onStopped;
}
