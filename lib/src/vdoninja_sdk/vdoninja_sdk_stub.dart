import "dart:async";
import "vdoninja_sdk_base.dart";

/// Stub implementation of the VDO.Ninja SDK for non-web platforms.
class VDONinjaSDKStub implements VDONinjaSDK {
  VDONinjaSDKStub({
    String? host,
    String? room,
    VDONinjaPassword? password,
    bool? debug,
    VDONinjaTurnServers? turnServers,
    bool? forceTURN,
    int? turnCacheTTL,
    List<VDONinjaIceServer>? stunServers,
    int? maxReconnectAttempts,
    int? reconnectDelay,
    bool? autoPingViewer,
    int? autoPingInterval,
    String? label,
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

  @override
  bool get isConnected => false;

  @override
  String? get room => null;

  @override
  String? get streamID => null;

  @override
  String? get uuid => null;

  @override
  bool get isRoomJoined => false;

  @override
  bool get isPublishing => false;

  @override
  Future<void> connect({String? host, String? room, VDONinjaPassword? password}) {
    throw UnsupportedError("VDO.Ninja SDK is only supported on the Web platform.");
  }

  @override
  void disconnect() {
    throw UnsupportedError("VDO.Ninja SDK is only supported on the Web platform.");
  }

  @override
  Future<void> joinRoom({String? room, VDONinjaPassword? password, bool? claim}) {
    throw UnsupportedError("VDO.Ninja SDK is only supported on the Web platform.");
  }

  @override
  void leaveRoom() {
    throw UnsupportedError("VDO.Ninja SDK is only supported on the Web platform.");
  }

  @override
  Future<dynamic> publish(dynamic stream, {
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
  }) {
    throw UnsupportedError("VDO.Ninja SDK is only supported on the Web platform.");
  }

  @override
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
  }) {
    throw UnsupportedError("VDO.Ninja SDK is only supported on the Web platform.");
  }

  @override
  void stopPublishing() {
    throw UnsupportedError("VDO.Ninja SDK is only supported on the Web platform.");
  }

  @override
  Future<String> quickPublish(dynamic stream, {
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
  }) {
    throw UnsupportedError("VDO.Ninja SDK is only supported on the Web platform.");
  }

  @override
  void stopViewing(String streamID) {
    throw UnsupportedError("VDO.Ninja SDK is only supported on the Web platform.");
  }

  @override
  Future<dynamic> view(String streamID, {
    VDONinjaPassword? password,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? viewPreferences,
  }) {
    throw UnsupportedError("VDO.Ninja SDK is only supported on the Web platform.");
  }

  @override
  Future<dynamic> quickView({
    required String streamID,
    String? room,
    VDONinjaPassword? password,
    bool? audio,
    bool? video,
    String? label,
    bool? dataOnly,
  }) {
    throw UnsupportedError("VDO.Ninja SDK is only supported on the Web platform.");
  }

  @override
  Future<dynamic> quickSubscribe({
    required String streamID,
    String? room,
    VDONinjaPassword? password,
    bool? audio,
    bool? video,
    String? label,
    bool? dataOnly,
  }) {
    throw UnsupportedError("VDO.Ninja SDK is only supported on the Web platform.");
  }

  @override
  Future<VDONinjaAutoConnectController> autoConnect({
    required String room,
    String? mode,
    String? streamID,
    String? label,
    VDONinjaPassword? password,
    bool Function(Map<String, dynamic> item)? filter,
    Map<String, dynamic>? view,
  }) {
    throw UnsupportedError("VDO.Ninja SDK is only supported on the Web platform.");
  }

  @override
  void sendData(dynamic data, {
    String? uuid,
    String? type,
    String? streamID,
    bool? allowFallback,
    String? preference,
  }) {
    throw UnsupportedError("VDO.Ninja SDK is only supported on the Web platform.");
  }

  @override
  List<Map<String, dynamic>> getStreams() => [];

  @override
  Map<String, dynamic>? getStreamInfo(String streamID) => null;

  // --- Streams returning empty streams for safety ---

  @override
  Stream<void> get onConnected => const Stream.empty();

  @override
  Stream<void> get onDisconnected => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onReconnecting => const Stream.empty();

  @override
  Stream<void> get onReconnected => const Stream.empty();

  @override
  Stream<void> get onReconnectFailed => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onRoomJoined => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onRoomLeft => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onPublishing => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onViewingStopped => const Stream.empty();

  @override
  Stream<VDONinjaTrackEvent> get onTrack => const Stream.empty();

  @override
  Stream<VDONinjaDataReceivedEvent> get onDataReceived => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onPeerConnected => const Stream.empty();

  @override
  Stream<VDONinjaPeerLatencyEvent> get onPeerLatency => const Stream.empty();

  @override
  Stream<VDONinjaPeerInfoEvent> get onPeerInfo => const Stream.empty();

  @override
  Stream<VDONinjaRemoteVideoMuteStateEvent> get onRemoteVideoMuteState => const Stream.empty();

  @override
  Stream<VDONinjaErrorEvent> get onError => const Stream.empty();
}

/// Helper function to create an SDK instance on non-web platforms.
VDONinjaSDK createSDK({
  String? host,
  String? room,
  VDONinjaPassword? password,
  bool? debug,
  VDONinjaTurnServers? turnServers,
  bool? forceTURN,
  int? turnCacheTTL,
  List<VDONinjaIceServer>? stunServers,
  int? maxReconnectAttempts,
  int? reconnectDelay,
  bool? autoPingViewer,
  int? autoPingInterval,
  String? label,
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
}) {
  return VDONinjaSDKStub(
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
}

/// Stub getter for library loading check.
bool get isSDKLoaded => false;

/// Stub function for script initialization.
Future<void> initialize({String? cdnUrl}) async {}
