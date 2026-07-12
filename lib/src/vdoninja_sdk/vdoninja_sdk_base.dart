import "dart:async";
import "package:collection/collection.dart";
import "vdoninja_sdk_stub.dart"
    if (dart.library.js_interop) "vdoninja_sdk_web.dart"
    as platform;

/// Base class for all VDO.Ninja SDK events.
abstract class VDONinjaEvent {
  final String type;
  VDONinjaEvent(this.type);
}

/// Event fired when a remote media track is received.
class VDONinjaTrackEvent extends VDONinjaEvent {
  /// The WebRTC MediaStreamTrack received. On web this is a `web.MediaStreamTrack`.
  final dynamic track;

  /// The list of WebRTC MediaStreams this track belongs to. On web this is a `List<web.MediaStream>`.
  final List<dynamic> streams;

  /// The UUID of the remote peer.
  final String uuid;

  /// The stream ID associated with the track, if any.
  final String? streamID;

  VDONinjaTrackEvent({
    /// The WebRTC MediaStreamTrack received. On web this is a `web.MediaStreamTrack`.
    required this.track,

    /// The list of WebRTC MediaStreams this track belongs to. On web this is a `List<web.MediaStream>`.
    required this.streams,

    /// The UUID of the remote peer.
    required this.uuid,

    /// The stream ID associated with the track, if any.
    this.streamID,
  }) : super("track");

  @override
  String toString() =>
      "VDONinjaTrackEvent(uuid: $uuid, streamID: $streamID, track: $track)";
}

/// Event fired when generic P2P data is received.
class VDONinjaDataReceivedEvent extends VDONinjaEvent {
  /// The decoded data payload (usually a Map or list).
  final dynamic data;

  /// The UUID of the sender.
  final String uuid;

  /// The stream ID associated with the connection, if any.
  final String? streamID;

  VDONinjaDataReceivedEvent({
    /// The decoded data payload.
    required this.data,

    /// The UUID of the sender.
    required this.uuid,

    /// The stream ID associated with the connection, if any.
    this.streamID,
  }) : super("dataReceived");

  @override
  String toString() =>
      "VDONinjaDataReceivedEvent(uuid: $uuid, streamID: $streamID, data: $data)";
}

/// Event fired when a peer's round-trip latency updates.
class VDONinjaPeerLatencyEvent extends VDONinjaEvent {
  /// The UUID of the peer.
  final String uuid;

  /// The latency in milliseconds.
  final int latency;

  /// The stream ID associated with the peer, if any.
  final String? streamID;

  VDONinjaPeerLatencyEvent({
    /// The UUID of the peer.
    required this.uuid,

    /// The round-trip latency in milliseconds.
    required this.latency,

    /// The stream ID associated with the peer, if any.
    this.streamID,
  }) : super("peerLatency");

  @override
  String toString() =>
      "VDONinjaPeerLatencyEvent(uuid: $uuid, streamID: $streamID, latency: ${latency}ms)";
}

/// Event fired when a peer's metadata/info updates.
class VDONinjaPeerInfoEvent extends VDONinjaEvent {
  /// The UUID of the peer.
  final String uuid;

  /// The stream ID of the peer, if any.
  final String? streamID;

  /// The info metadata Map.
  final Map<String, dynamic> info;

  VDONinjaPeerInfoEvent({
    /// The UUID of the peer.
    required this.uuid,

    /// The stream ID of the peer, if any.
    this.streamID,

    /// The metadata info Map.
    required this.info,
  }) : super("peerInfo");

  @override
  String toString() =>
      "VDONinjaPeerInfoEvent(uuid: $uuid, streamID: $streamID, info: $info)";
}

/// Event fired when a remote peer's video mute state changes.
class VDONinjaRemoteVideoMuteStateEvent extends VDONinjaEvent {
  /// Whether the video is muted.
  final bool muted;

  /// The track ID that changed.
  final String? trackId;

  /// The stream ID associated with the peer.
  final String? streamID;

  /// The UUID of the peer.
  final String uuid;

  /// The type of connection ('viewer' or 'publisher').
  final String connectionType;

  VDONinjaRemoteVideoMuteStateEvent({
    /// Set to `true` if the video is muted.
    required this.muted,

    /// The track ID that changed.
    this.trackId,

    /// The stream ID associated with the peer.
    this.streamID,

    /// The UUID of the peer.
    required this.uuid,

    /// The type of WebRTC connection ('viewer' or 'publisher').
    required this.connectionType,
  }) : super("remoteVideoMuteState");

  @override
  String toString() =>
      "VDONinjaRemoteVideoMuteStateEvent(uuid: $uuid, muted: $muted, connectionType: $connectionType)";
}

/// Event fired when an SDK error occurs.
class VDONinjaErrorEvent extends VDONinjaEvent {
  /// The error message.
  final String message;

  /// Additional raw details about the error, if any.
  final dynamic details;

  VDONinjaErrorEvent({
    /// The error message.
    required this.message,

    /// Raw details about the error.
    this.details,
  }) : super("error");

  @override
  String toString() =>
      "VDONinjaErrorEvent(message: $message, details: $details)";
}

/// Represents the password parameter for VDO.Ninja SDK.
///
/// Can be a [String] to enable AES-CBC encryption, or a [bool] (specifically `false`)
/// to explicitly disable encryption.
sealed class VDONinjaPassword {
  /// The underlying value.
  dynamic get value;

  const VDONinjaPassword();

  /// Enable AES-CBC encryption with the specified room password.
  const factory VDONinjaPassword.string(String password) =
      VDONinjaPasswordString;

  /// Set the password via a boolean value. Pass `false` to explicitly disable encryption.
  const factory VDONinjaPassword.boolean(bool enabled) =
      VDONinjaPasswordBoolean;

  /// Explicitly disable encryption.
  static const VDONinjaPassword disable = VDONinjaPasswordBoolean(false);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VDONinjaPassword &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class VDONinjaPasswordString extends VDONinjaPassword {
  @override
  final String value;
  const VDONinjaPasswordString(this.value);

  @override
  String toString() => "VDONinjaPassword.string($value)";
}

class VDONinjaPasswordBoolean extends VDONinjaPassword {
  @override
  final bool value;
  const VDONinjaPasswordBoolean(this.value);

  @override
  String toString() => "VDONinjaPassword.boolean($value)";
}

/// Represents a WebRTC ICE/STUN/TURN server configuration.
sealed class VDONinjaIceServer {
  /// The underlying JS-compatible value.
  dynamic get value;

  const VDONinjaIceServer._();

  /// Standard type-safe ICE server configuration.
  factory VDONinjaIceServer({
    required List<String> urls,
    String? username,
    String? credential,
  }) = VDONinjaIceServerConfig;

  /// Escape hatch to pass a raw JSON Object (Map) directly.
  const factory VDONinjaIceServer.object(Map<String, dynamic> raw) =
      VDONinjaIceServerObject;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VDONinjaIceServer &&
          runtimeType == other.runtimeType &&
          const DeepCollectionEquality().equals(value, other.value);

  @override
  int get hashCode => const DeepCollectionEquality().hash(value);
}

class VDONinjaIceServerConfig extends VDONinjaIceServerObject {
  VDONinjaIceServerConfig({
    required List<String> urls,
    String? username,
    String? credential,
  }) : super({
          "urls": urls,
          "username": ?username,
          "credential": ?credential,
        });

  @override
  String toString() =>
      "VDONinjaIceServer(urls: ${value['urls']}, username: ${value['username']}, credential: ${value['credential']})";
}

class VDONinjaIceServerObject extends VDONinjaIceServer {
  @override
  final Map<String, dynamic> value;
  const VDONinjaIceServerObject(this.value) : super._();

  @override
  String toString() => "VDONinjaIceServer.object($value)";
}

/// Represents the custom TURN servers configuration option.
///
/// Can be a [bool] (specifically `false`) to disable TURN servers,
/// or a [List] of TURN server configuration maps.
sealed class VDONinjaTurnServers {
  /// The underlying value.
  dynamic get value;

  const VDONinjaTurnServers();

  /// Provide a custom list of TURN server configuration maps.
  const factory VDONinjaTurnServers.list(List<VDONinjaIceServer> servers) =
      VDONinjaTurnServersList;

  /// Disable TURN servers explicitly.
  static const VDONinjaTurnServers disable = VDONinjaTurnServersBoolean(false);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VDONinjaTurnServers &&
          runtimeType == other.runtimeType &&
          const DeepCollectionEquality().equals(value, other.value);

  @override
  int get hashCode => const DeepCollectionEquality().hash(value);
}

class VDONinjaTurnServersBoolean extends VDONinjaTurnServers {
  @override
  final bool value;
  const VDONinjaTurnServersBoolean(this.value);

  @override
  String toString() => "VDONinjaTurnServers.boolean($value)";
}

class VDONinjaTurnServersList extends VDONinjaTurnServers {
  @override
  final List<VDONinjaIceServer> value;
  const VDONinjaTurnServersList(this.value);

  @override
  String toString() => "VDONinjaTurnServers.list($value)";
}

/// Represents the chunked transmission configuration option.
///
/// Can be a [bool] to enable/disable chunked data transmission, or an [int]
/// to specify a block size.
sealed class VDONinjaAllowChunked {
  /// The underlying value.
  dynamic get value;

  const VDONinjaAllowChunked();

  /// Enable or disable chunked data transmission.
  const factory VDONinjaAllowChunked.boolean(bool enabled) =
      VDONinjaAllowChunkedBoolean;

  /// Enable chunked data transmission with a specific block size.
  const factory VDONinjaAllowChunked.integer(int size) =
      VDONinjaAllowChunkedInteger;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VDONinjaAllowChunked &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class VDONinjaAllowChunkedBoolean extends VDONinjaAllowChunked {
  @override
  final bool value;
  const VDONinjaAllowChunkedBoolean(this.value);

  @override
  String toString() => "VDONinjaAllowChunked.boolean($value)";
}

class VDONinjaAllowChunkedInteger extends VDONinjaAllowChunked {
  @override
  final int value;
  const VDONinjaAllowChunkedInteger(this.value);

  @override
  String toString() => "VDONinjaAllowChunked.integer($value)";
}

/// The base abstract class for the VDO.Ninja SDK.
///
/// Use [VDONinjaSDK] to initialize and interact with the VDO.Ninja SDK.
///
/// Note: Call [VDONinjaSDK.initialize] once on web startup before creating any SDK instances.
abstract class VDONinjaSDK {
  /// Create a new VDONinjaSDK instance.
  ///
  /// Configuration options can be passed to configure host, room, password, STUN/TURN, etc.
  factory VDONinjaSDK({
    /// The signaling server WebSocket URL (defaults to "wss://wss.vdo.ninja").
    String? host,

    /// The room ID to join.
    String? room,

    /// The room password. String value enables AES-CBC encryption for SDP and ICE candidates.
    /// Pass `false` to explicitly disable encryption.
    VDONinjaPassword? password,

    /// Set to `true` to enable verbose console logging.
    bool? debug,

    /// Custom TURN server list configuration. Pass `false` to disable TURN servers,
    /// or `null` to auto-fetch optimal TURN servers.
    VDONinjaTurnServers? turnServers,

    /// Set to `true` to force relaying WebRTC connections through TURN servers for privacy.
    bool? forceTURN,

    /// The cache time-to-live (in minutes) for auto-fetched TURN servers.
    int? turnCacheTTL,

    /// Custom list of STUN server configurations.
    List<VDONinjaIceServer>? stunServers,

    /// Maximum number of WebSocket reconnection attempts.
    int? maxReconnectAttempts,

    /// Initial delay in milliseconds before attempting to reconnect.
    int? reconnectDelay,

    /// Set to `true` to enable automated viewer-side pinging to maintain connections.
    bool? autoPingViewer,

    /// The interval in milliseconds between automated pings.
    int? autoPingInterval,

    /// A human-readable label identifying this publisher client.
    String? label,

    /// Custom metadata associated with this stream.
    String? meta,

    /// Layout ordering index for the guest stream.
    String? order,

    /// Set to `true` to indicate this publisher stream should broadcast.
    bool? broadcast,

    /// Set to `true` to enable drawing/annotations support.
    bool? allowDrawing,

    /// Set to `true` if the publisher is embedded inside an iframe.
    bool? iframe,

    /// Set to `true` if the publisher is embedded as a widget.
    bool? widget,

    /// Set to `true` to enable MIDI message forwarding support.
    bool? allowMidi,

    /// Set to `true` to enable sharing resources.
    bool? allowResources,

    /// Set to `true` or an integer block size to enable chunked data transmission.
    VDONinjaAllowChunked? allowChunked,

    /// Additional publisher metadata information.
    Map<String, dynamic>? info,
  }) => platform.createSDK(
    host: host,
    room: room,
    password: password,
    debug: debug,
    turnServers: turnServers,
    forceTURN: forceTURN,
    turnCacheTTL: turnCacheTTL,
    stunServers: stunServers,
    maxReconnectAttempts: maxReconnectAttempts,
    reconnectDelay: reconnectDelay,
    autoPingViewer: autoPingViewer,
    autoPingInterval: autoPingInterval,
    label: label,
    meta: meta,
    order: order,
    broadcast: broadcast,
    allowDrawing: allowDrawing,
    iframe: iframe,
    widget: widget,
    allowMidi: allowMidi,
    allowResources: allowResources,
    allowChunked: allowChunked,
    info: info,
  );

  /// Check if the VDO.Ninja JavaScript library is loaded in the browser.
  /// Always returns false on non-web platforms.
  static bool get isSDKLoaded => platform.isSDKLoaded;

  /// Dynamically inject the VDO.Ninja SDK JavaScript library into the page.
  ///
  /// On Web, this appends a `<script>` tag referencing [cdnUrl] (default is unpkg).
  /// On other platforms, this is a no-op that resolves immediately.
  static Future<void> initialize({String? cdnUrl, String version = "1.4.1"}) =>
      platform.initialize(cdnUrl: cdnUrl, version: version);

  // --- SDK State Getters ---

  /// Whether the SDK is currently connected to the signaling server.
  bool get isConnected;

  /// The room name currently joined, or null.
  String? get room;

  /// The stream ID currently published by this instance, or null.
  String? get streamID;

  /// The unique client UUID assigned to this instance by the signaling server.
  String? get uuid;

  /// Whether a room has been successfully joined.
  bool get isRoomJoined;

  /// Whether this instance is currently publishing media.
  bool get isPublishing;

  // --- SDK Methods ---

  /// Connect to the signaling server.
  ///
  /// Can optionally override [host], [room], or [password].
  Future<void> connect({
    String? host,
    String? room,
    VDONinjaPassword? password,
  });

  /// Disconnect from the signaling server, closing all peer connections and data channels.
  void disconnect();

  /// Join a room.
  ///
  /// Requires a [room] name. Hashing is automatically done if [password] is set.
  /// Set [claim] to true to request director status.
  Future<void> joinRoom({
    String? room,
    VDONinjaPassword? password,
    bool? claim,
  });

  /// Leave the current room.
  void leaveRoom();

  /// Publish a media stream to the room.
  ///
  /// On web, [stream] must be a `web.MediaStream`.
  /// Returns a Future that resolves with publisher details.
  Future<dynamic> publish(
    dynamic stream, {
    String? streamID,
    String? label,
    String? room,
    VDONinjaPassword? password,
    String? meta,
    String? order,
    bool? broadcast,
    bool? allowDrawing,
    bool? iframe,
    bool? widget,
    bool? allowMidi,
    bool? allowResources,
    VDONinjaAllowChunked? allowChunked,
    Map<String, dynamic>? info,
    Map<String, dynamic>? media,
    Map<String, dynamic>? webrtc,
  });

  /// Announce availability without publishing media (data-only connection).
  ///
  /// This allows establishing peer connections for data channel communication only.
  /// Returns a Future resolving to the plain stream ID.
  Future<String> announce({
    String? streamID,
    String? room,
    String? label,
    VDONinjaPassword? password,
    String? meta,
    String? order,
    bool? broadcast,
    bool? allowDrawing,
    bool? iframe,
    bool? widget,
    bool? allowMidi,
    bool? allowResources,
    VDONinjaAllowChunked? allowChunked,
    Map<String, dynamic>? info,
  });

  /// Stop publishing/announcing local media or data channels.
  void stopPublishing();

  /// Quick publish method - connects, joins a room, and publishes in one call.
  ///
  /// Returns a Future resolving to the stream ID.
  Future<String> quickPublish(
    dynamic stream, {
    String? streamID,
    String? label,
    String? room,
    VDONinjaPassword? password,
    String? meta,
    String? order,
    bool? broadcast,
    bool? allowDrawing,
    bool? iframe,
    bool? widget,
    bool? allowMidi,
    bool? allowResources,
    VDONinjaAllowChunked? allowChunked,
    Map<String, dynamic>? info,
    Map<String, dynamic>? media,
    Map<String, dynamic>? webrtc,
  });

  /// Stop viewing a specific stream.
  void stopViewing(String streamID);

  /// View a specific stream ID.
  ///
  /// Returns a Future that resolves with the RTCPeerConnection of the viewer (on web, `web.RTCPeerConnection`).
  Future<dynamic> view(
    String streamID, {
    VDONinjaPassword? password,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? viewPreferences,
  });

  /// Quick view method - connects, joins a room, and views in one call.
  ///
  /// Returns a Future resolving to the RTCPeerConnection of the viewer.
  Future<dynamic> quickView({
    required String streamID,
    String? room,
    VDONinjaPassword? password,
    bool? audio,
    bool? video,
    String? label,
    bool? dataOnly,
  });

  /// Quick subscribe helper: connects, joins room, and subscribes.
  /// Defaults to dataOnly unless explicitly overridden.
  ///
  /// Returns a Future resolving to the RTCPeerConnection of the viewer.
  Future<dynamic> quickSubscribe({
    required String streamID,
    String? room,
    VDONinjaPassword? password,
    bool? audio,
    bool? video,
    String? label,
    bool? dataOnly,
  });

  /// Automatically connects to signaling, joins a room, announces presence,
  /// and automatically views other peers in the room based on the chosen mode.
  ///
  /// - [mode] can be "half" (default, single data channel per pair, best for data-only) or
  ///   "full" (dual connections per pair, required for audio/video exchange).
  /// - Provide an optional [filter] to conditionally view specific streams.
  /// Returns a [VDONinjaAutoConnectController] containing the plain streamID and a [stop] method.
  Future<VDONinjaAutoConnectController> autoConnect({
    required String room,
    String? mode,
    String? streamID,
    String? label,
    VDONinjaPassword? password,
    bool Function(Map<String, dynamic> item)? filter,
    Map<String, dynamic>? view,
  });

  /// Send generic data via open P2P data channels.
  ///
  /// If [uuid] is provided, sends to that peer. If [type] is 'viewer' or 'publisher',
  /// targets specific channel types.
  void sendData(
    dynamic data, {
    String? uuid,
    String? type,
    String? streamID,
    bool? allowFallback,
    String? preference,
  });

  /// Get list of all currently tracked streams.
  List<Map<String, dynamic>> getStreams();

  /// Get metadata/info about a specific stream ID.
  Map<String, dynamic>? getStreamInfo(String streamID);

  // --- Event Stream Getters ---

  /// Stream fired when successfully connected to signaling.
  Stream<void> get onConnected;

  /// Stream fired when disconnected from signaling.
  Stream<void> get onDisconnected;

  /// Stream fired when starting a reconnection attempt.
  Stream<Map<String, dynamic>> get onReconnecting;

  /// Stream fired when successfully reconnected.
  Stream<void> get onReconnected;

  /// Stream fired when all reconnection attempts fail.
  Stream<void> get onReconnectFailed;

  /// Stream fired when a room is successfully joined.
  Stream<Map<String, dynamic>> get onRoomJoined;

  /// Stream fired when leaving a room.
  Stream<Map<String, dynamic>> get onRoomLeft;

  /// Stream fired when media publishing starts.
  Stream<Map<String, dynamic>> get onPublishing;

  /// Stream fired when viewing a stream is stopped.
  Stream<Map<String, dynamic>> get onViewingStopped;

  /// Stream fired when a new WebRTC track is received from a viewed stream.
  Stream<VDONinjaTrackEvent> get onTrack;

  /// Stream fired when P2P data is received from a peer.
  Stream<VDONinjaDataReceivedEvent> get onDataReceived;

  /// Stream fired when a new peer WebRTC connection is fully established.
  Stream<Map<String, dynamic>> get onPeerConnected;

  /// Stream fired when round-trip latency data updates for a peer.
  Stream<VDONinjaPeerLatencyEvent> get onPeerLatency;

  /// Stream fired when metadata/info updates for a peer.
  Stream<VDONinjaPeerInfoEvent> get onPeerInfo;

  /// Stream fired when a remote peer video mute/unmute occurs.
  Stream<VDONinjaRemoteVideoMuteStateEvent> get onRemoteVideoMuteState;

  /// Stream fired when an error occurs in signaling or WebRTC.
  Stream<VDONinjaErrorEvent> get onError;
}

/// Controller returned by [VDONinjaSDK.autoConnect] to manage the connection.
class VDONinjaAutoConnectController {
  final void Function() _stopCallback;
  final String streamID;

  VDONinjaAutoConnectController({
    /// Callback triggered to stop the auto-connect loop.
    required void Function() onStop,

    /// The final stream ID assigned to the client.
    required this.streamID,
  }) : _stopCallback = onStop;

  /// Stop the auto-connect session, removing all event listeners.
  void stop() => _stopCallback();
}
