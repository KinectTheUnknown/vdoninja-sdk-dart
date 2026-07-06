import "dart:async";
import "whep_client_stub.dart"
    if (dart.library.js_interop) "whep_client_web.dart" as platform;

/// Base abstract class for WHEP (WebRTC-HTTP Egress Protocol) Client.
///
/// Used to view live streams from WHEP-compatible endpoints.
abstract class WHEPClient {
  /// Create a new WHEPClient instance.
  factory WHEPClient({
    /// The WHEP endpoint URL (required).
    required String endpoint,

    /// The Bearer auth token for endpoint authentication.
    String? authToken,

    /// Whether to request an audio track (defaults to true).
    bool? audio,

    /// Whether to request a video track (defaults to true).
    bool? video,

    /// Whether to enable trickle ICE (defaults to true).
    bool? trickleIce,
  }) => platform.createWHEPClient(
    endpoint: endpoint,
    authToken: authToken,
    audio: audio,
    video: video,
    trickleIce: trickleIce,
  );

  /// Check if the WHEP client library is loaded.
  static bool get isLibraryLoaded => platform.isWHEPLibraryLoaded;

  /// Dynamically load the WHEP client library script from jsDelivr CDN.
  static Future<void> initialize({String? cdnUrl}) => platform.initializeWHEP(cdnUrl: cdnUrl);

  // --- Methods ---

  /// Start viewing the egress endpoint, returning the received MediaStream.
  Future<dynamic> view();

  /// Retrieve the currently received MediaStream.
  dynamic getStream();

  /// Mute or unmute the audio track locally.
  void muteAudio(bool muted);

  /// Mute or unmute the video track locally.
  void muteVideo(bool muted);

  /// Stop viewing and cleanup all resources.
  void stop();

  /// Retrieve the underlying WebRTC stats report.
  Future<dynamic> getStats();

  // --- Event Streams ---

  /// Stream fired when starting to connect to the egress endpoint.
  Stream<void> get onConnecting;

  /// Stream fired when connection is established.
  Stream<void> get onConnected;

  /// Stream fired when a new WebRTC track is received (e.g. `web.RTCTrackEvent`).
  Stream<dynamic> get onTrack;

  /// Stream fired when ICE state updates.
  Stream<String> get onIceState;

  /// Stream fired when PeerConnection state updates.
  Stream<String> get onConnectionState;

  /// Stream fired when an error occurs during viewing.
  Stream<dynamic> get onError;

  /// Stream fired when connection is closed.
  Stream<void> get onDisconnected;

  /// Stream fired when viewing is stopped.
  Stream<void> get onStopped;
}
