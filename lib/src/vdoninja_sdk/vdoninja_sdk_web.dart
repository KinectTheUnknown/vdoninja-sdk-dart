import "dart:async";
import "dart:convert";
import "dart:js_interop";
import "dart:js_interop_unsafe";
import "package:web/web.dart" as web;
import "vdoninja_sdk_base.dart";

/// Helper to convert a Dart Map or List to a JSObject or JSArray.
JSObject _mapToJSObject(Map<String, dynamic> map) {
  return map.jsify() as JSObject;
}

/// Helper to convert a JSObject to a Dart Map.
Map<String, dynamic> _jsObjectToMap(JSObject obj) {
  try {
    final dartObj = obj.dartify();
    if (dartObj is Map) {
      return Map<String, dynamic>.from(dartObj);
    }
  } catch (_) {
    // Ignore error and fall through
  }
  return <String, dynamic>{};
}

/// Helper to convert a JS object/primitive to a Dart value.
dynamic _jsAnyToDart(JSAny? value) {
  if (value == null || value.isUndefinedOrNull) return null;
  if (value.isA<JSArray>()) {
    final dartList = (value as JSArray).toDart;
    final length = dartList.length;
    final list = List<dynamic>.filled(length, null, growable: true);
    for (var i = 0; i < length; i++) {
      list[i] = _jsAnyToDart(dartList[i]);
    }
    return list;
  }
  try {
    return value.dartify();
  } catch (_) {
    return value; // Return as-is if it's a complex JS object (e.g. MediaStream)
  }
}

@anonymous
extension type VDONinjaStateJS._(JSObject _) implements JSObject {
  external JSBoolean? get connected;
  external JSString? get room;
  external JSString? get streamID;
  external JSString? get uuid;
  external JSBoolean? get roomJoined;
  external JSBoolean? get publishing;
}

@anonymous
extension type VDONinjaAutoConnectControllerJS._(JSObject _)
    implements JSObject {
  external JSString get streamID;
  external JSFunction get stop;
}

@anonymous
extension type VDONinjaConnectionJS._(JSObject _) implements JSObject {
  external JSAny? get dataChannel;
  external JSString? get streamID;
}

@anonymous
extension type VDONinjaEventDetailJS._(JSObject _) implements JSObject {
  external JSAny? get track;
  external JSAny? get streams;
  external JSAny? get uuid;
  external JSAny? get streamID;
  external JSAny? get data;
  external JSAny? get connection;
  external JSAny? get latency;
  external JSAny? get info;
  external JSAny? get muted;
  external JSAny? get trackId;
  external JSAny? get connectionType;
  external JSAny? get error;
  external JSAny? get message;
  external JSAny? get details;
  external JSAny? get list;
  external JSAny? get reason;
}

@JS()
@anonymous
extension type _WindowVDONinjaExt(JSObject _) implements JSObject {
  @JS("VDONinjaSDK")
  external JSAny? get vdoNinjaSdk;
}

@JS("VDONinjaSDK")
extension type VDONinjaSDKJS._(JSObject _) implements JSObject {
  external VDONinjaSDKJS([JSObject? options]);

  external JSAny? get state;

  external JSPromise connect([JSObject? options]);
  external void disconnect();

  external JSPromise joinRoom([JSObject? options]);
  external void leaveRoom();

  external JSPromise publish(JSObject stream, [JSObject? options]);
  external JSPromise announce([JSObject? options]);
  external void stopPublishing();

  external JSPromise quickPublish([JSObject? options]);
  external JSPromise quickView([JSObject? options]);
  external JSPromise quickSubscribe([JSObject? options]);
  external JSPromise autoConnect(JSAny roomOrOptions, [JSFunction? filter]);

  external void stopViewing(JSString streamID);
  external JSPromise view(JSString streamID, [JSObject? options]);

  external void sendData(JSAny data, [JSObject? options]);
  external JSArray getStreams();
  external JSObject? getStreamInfo(JSString streamID);

  external JSPromise addTrack(JSObject track, [JSObject? stream]);
  external JSPromise removeTrack(JSObject track);
  external JSPromise replaceTrack(JSObject oldTrack, JSObject newTrack);
  external void sendPing(JSString uuid);
  external JSPromise getStats([JSString? uuid]);

  external void addEventListener(JSString type, JSFunction callback);
  external void removeEventListener(JSString type, JSFunction callback);
}

/// Web-specific implementation of the VDO.Ninja SDK using JS interop.
class VDONinjaSDKWeb implements VDONinjaSDK {
  final VDONinjaSDKJS _jsSdk;
  final Map<String, StreamController<dynamic>> _controllers = {};
  final Map<String, JSFunction> _jsCallbacks = {};

  StreamSubscription<Map<String, dynamic>>? _peerConnectedSub;
  StreamSubscription<Map<String, dynamic>>? _connectionFailedSub;
  StreamSubscription<Map<String, dynamic>>? _roomLeftSub;
  final Map<String, JSFunction> _dataChannelCallbacks = {};
  final Map<String, JSObject> _dataChannels = {};

  VDONinjaSDKWeb({
    String? host,
    String? room,
    VDONinjaPassword? password,
    String? salt,
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
  }) : _jsSdk = _createJsInstance(
         host: host,
         room: room,
         password: password,
         salt: salt,
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
       ) {
    _peerConnectedSub = onPeerConnected.listen((event) {
      final connection = event["connection"];
      if (connection != null && (connection as JSAny).isA<JSObject>()) {
        _hookDataChannel(connection as JSObject, event["uuid"] as String);
      }
    });
    _connectionFailedSub = onConnectionFailed.listen((event) {
      final uuid = event["uuid"] as String?;
      if (uuid != null) {
        _removeDataChannelHook(uuid);
      }
    });
    _roomLeftSub = onRoomLeft.listen((_) {
      _removeAllDataChannelHooks();
    });
  }

  static VDONinjaSDKJS _createJsInstance({
    String? host,
    String? room,
    VDONinjaPassword? password,
    String? salt,
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
    if (!isSDKLoaded) {
      throw StateError(
        "VDO.Ninja SDK has not been loaded. Call VDO.Ninja SDK.initialize() first.",
      );
    }

    final options = <String, dynamic>{};
    if (host != null) options["host"] = host;
    if (room != null) options["room"] = room;
    if (password != null) options["password"] = password.value;
    if (salt != null) options["salt"] = salt;
    if (debug != null) options["debug"] = debug;
    if (turnServers != null) {
      final val = turnServers.value;
      if (val is List<VDONinjaIceServer>) {
        options["turnServers"] = val.map((s) => s.value).toList();
      } else {
        options["turnServers"] = val;
      }
    }
    if (forceTURN != null) options["forceTURN"] = forceTURN;
    if (turnCacheTTL != null) options["turnCacheTTL"] = turnCacheTTL;
    if (stunServers != null) {
      options["stunServers"] = stunServers.map((s) => s.value).toList();
    }
    if (maxReconnectAttempts != null) {
      options["maxReconnectAttempts"] = maxReconnectAttempts;
    }
    if (reconnectDelay != null) options["reconnectDelay"] = reconnectDelay;
    if (autoPingViewer != null) options["autoPingViewer"] = autoPingViewer;
    if (autoPingInterval != null) {
      options["autoPingInterval"] = autoPingInterval;
    }
    if (label != null) options["label"] = label;
    if (meta != null) options["meta"] = meta;
    if (order != null) options["order"] = order;
    if (broadcast != null) options["broadcast"] = broadcast;
    if (allowDrawing != null) options["allowDrawing"] = allowDrawing;
    if (iframe != null) options["iframe"] = iframe;
    if (widget != null) options["widget"] = widget;
    if (allowMidi != null) options["allowMidi"] = allowMidi;
    if (allowResources != null) options["allowResources"] = allowResources;
    if (allowChunked != null) options["allowChunked"] = allowChunked.value;
    if (info != null) options["info"] = info;

    return VDONinjaSDKJS(_mapToJSObject(options));
  }

  /// Check if the VDO.Ninja JavaScript library is loaded in the browser.
  static bool get isSDKLoaded {
    return !(web.window as _WindowVDONinjaExt).vdoNinjaSdk.isUndefinedOrNull;
  }

  // Cache the initialization future to prevent redundant <script> injections
  // and race conditions if initialize() is called concurrently.
  static Future<void>? _initFuture;

  /// Dynamically inject the VDO.Ninja SDK JavaScript library into the page.
  static Future<void> initialize({
    String? cdnUrl,
    String version = "latest",
  }) async {
    if (cdnUrl != null) {
      final parsed = Uri.tryParse(cdnUrl);
      if (parsed == null || parsed.scheme != "https") {
        throw ArgumentError(
          "cdnUrl must be an HTTPS URL to prevent malicious injection.",
        );
      }
    }
    if (isSDKLoaded) return;
    if (_initFuture != null) return _initFuture;

    final completer = Completer<void>();
    _initFuture = completer.future;

    final script =
        web.document.createElement("script") as web.HTMLScriptElement;
    final safeVersion = Uri.encodeComponent(version);
    script.src =
        cdnUrl ??
        "https://unpkg.com/@vdoninja/sdk@$safeVersion/vdoninja-sdk.js";
    script.type = "text/javascript";
    script.async = true;
    script.crossOrigin = "anonymous";

    script.onload = (web.Event event) {
      _initFuture = null;
      completer.complete();
    }.toJS;

    script.onerror = (web.Event event) {
      _initFuture = null;
      completer.completeError(
        Exception("Failed to load VDO.Ninja SDK script from ${script.src}"),
      );
    }.toJS;

    web.document.head!.appendChild(script);
    return completer.future;
  }

  VDONinjaStateJS? get _state {
    // ⚡ Bolt: Removed dynamic getProperty string lookup for state to avoid Wasm allocation overhead
    final val = _jsSdk.state;
    if (val.isUndefinedOrNull) {
      return null;
    }
    return val as VDONinjaStateJS;
  }

  @override
  bool get isConnected {
    final state = _state;
    if (state == null) return false;
    return state.connected?.toDart ?? false;
  }

  @override
  String? get room {
    final state = _state;
    if (state == null) return null;
    return state.room?.toDart;
  }

  @override
  String? get streamID {
    final state = _state;
    if (state == null) return null;
    return state.streamID?.toDart;
  }

  @override
  String? get uuid {
    final state = _state;
    if (state == null) return null;
    return state.uuid?.toDart;
  }

  @override
  bool get isRoomJoined {
    final state = _state;
    if (state == null) return false;
    return state.roomJoined?.toDart ?? false;
  }

  @override
  bool get isPublishing {
    final state = _state;
    if (state == null) return false;
    return state.publishing?.toDart ?? false;
  }

  @override
  Future<void> connect({
    String? host,
    String? room,
    VDONinjaPassword? password,
  }) async {
    final options = <String, dynamic>{};
    if (host != null) options["host"] = host;
    if (room != null) options["room"] = room;
    if (password != null) options["password"] = password.value;

    final jsPromise = _jsSdk.connect(_mapToJSObject(options));
    await jsPromise.toDart;
  }

  @override
  void disconnect() => _jsSdk.disconnect();

  @override
  Future<void> joinRoom({
    String? room,
    VDONinjaPassword? password,
    bool? claim,
  }) async {
    final options = <String, dynamic>{};
    if (room != null) options["room"] = room;
    if (password != null) options["password"] = password.value;
    if (claim != null) options["claim"] = claim;

    final jsPromise = _jsSdk.joinRoom(_mapToJSObject(options));
    await jsPromise.toDart;
  }

  @override
  void leaveRoom() => _jsSdk.leaveRoom();

  @override
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
  }) async {
    final options = <String, dynamic>{};
    if (streamID != null) options["streamID"] = streamID;
    if (label != null) options["label"] = label;
    if (room != null) options["room"] = room;
    if (password != null) options["password"] = password.value;
    if (meta != null) options["meta"] = meta;
    if (order != null) options["order"] = order;
    if (broadcast != null) options["broadcast"] = broadcast;
    if (allowDrawing != null) options["allowDrawing"] = allowDrawing;
    if (iframe != null) options["iframe"] = iframe;
    if (widget != null) options["widget"] = widget;
    if (allowMidi != null) options["allowMidi"] = allowMidi;
    if (allowResources != null) options["allowResources"] = allowResources;
    if (allowChunked != null) options["allowChunked"] = allowChunked.value;
    if (info != null) options["info"] = info;
    if (media != null) options["media"] = media;
    if (webrtc != null) options["webrtc"] = webrtc;

    final JSObject jsStream;
    try {
      jsStream = stream as JSObject;
    } catch (_) {
      throw ArgumentError("stream must be a JSObject representing MediaStream");
    }

    final jsPromise = _jsSdk.publish(jsStream, _mapToJSObject(options));
    final result = await jsPromise.toDart;
    return _jsAnyToDart(result);
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
  }) async {
    final options = <String, dynamic>{};
    if (streamID != null) options["streamID"] = streamID;
    if (room != null) options["room"] = room;
    if (label != null) options["label"] = label;
    if (password != null) options["password"] = password.value;
    if (meta != null) options["meta"] = meta;
    if (order != null) options["order"] = order;
    if (broadcast != null) options["broadcast"] = broadcast;
    if (allowDrawing != null) options["allowDrawing"] = allowDrawing;
    if (iframe != null) options["iframe"] = iframe;
    if (widget != null) options["widget"] = widget;
    if (allowMidi != null) options["allowMidi"] = allowMidi;
    if (allowResources != null) options["allowResources"] = allowResources;
    if (allowChunked != null) options["allowChunked"] = allowChunked.value;
    if (info != null) options["info"] = info;

    final jsPromise = _jsSdk.announce(_mapToJSObject(options));
    final result = await jsPromise.toDart;
    return (result as JSString).toDart;
  }

  @override
  void stopPublishing() => _jsSdk.stopPublishing();

  @override
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
  }) async {
    final options = <String, dynamic>{};
    if (streamID != null) options["streamID"] = streamID;
    if (label != null) options["label"] = label;
    if (room != null) options["room"] = room;
    if (password != null) options["password"] = password.value;
    if (meta != null) options["meta"] = meta;
    if (order != null) options["order"] = order;
    if (broadcast != null) options["broadcast"] = broadcast;
    if (allowDrawing != null) options["allowDrawing"] = allowDrawing;
    if (iframe != null) options["iframe"] = iframe;
    if (widget != null) options["widget"] = widget;
    if (allowMidi != null) options["allowMidi"] = allowMidi;
    if (allowResources != null) options["allowResources"] = allowResources;
    if (allowChunked != null) options["allowChunked"] = allowChunked.value;
    if (info != null) options["info"] = info;
    if (media != null) options["media"] = media;
    if (webrtc != null) options["webrtc"] = webrtc;

    final JSObject jsStream;
    try {
      jsStream = stream as JSObject;
    } catch (_) {
      throw ArgumentError("stream must be a JSObject representing MediaStream");
    }
    options["stream"] = jsStream;

    final jsPromise = _jsSdk.quickPublish(_mapToJSObject(options));
    final result = await jsPromise.toDart;
    return (result as JSString).toDart;
  }

  @override
  void stopViewing(String streamID) => _jsSdk.stopViewing(streamID.toJS);

  @override
  Future<dynamic> view(
    String streamID, {
    bool audio = true,
    bool video = true,
    String? label,
  }) async {
    final options = <String, dynamic>{};
    options["audio"] = audio;
    options["video"] = video;
    if (label != null) options["label"] = label;

    final jsPromise = _jsSdk.view(streamID.toJS, _mapToJSObject(options));
    final result = await jsPromise.toDart;
    return result; // Returns the PeerConnection
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
  }) async {
    final options = <String, dynamic>{};
    options["streamID"] = streamID;
    if (room != null) options["room"] = room;
    if (password != null) options["password"] = password.value;
    if (audio != null) options["audio"] = audio;
    if (video != null) options["video"] = video;
    if (label != null) options["label"] = label;
    if (dataOnly != null) options["dataOnly"] = dataOnly;

    final jsPromise = _jsSdk.quickView(_mapToJSObject(options));
    final result = await jsPromise.toDart;
    return result;
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
  }) async {
    final options = <String, dynamic>{};
    options["streamID"] = streamID;
    if (room != null) options["room"] = room;
    if (password != null) options["password"] = password.value;
    if (audio != null) options["audio"] = audio;
    if (video != null) options["video"] = video;
    if (label != null) options["label"] = label;
    if (dataOnly != null) options["dataOnly"] = dataOnly;

    final jsPromise = _jsSdk.quickSubscribe(_mapToJSObject(options));
    final result = await jsPromise.toDart;
    return result;
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
  }) async {
    final options = <String, dynamic>{};
    options["room"] = room;
    if (mode != null) options["mode"] = mode;
    if (streamID != null) options["streamID"] = streamID;
    if (label != null) options["label"] = label;
    if (password != null) options["password"] = password.value;
    if (view != null) options["view"] = view;

    JSFunction? jsFilter;
    if (filter != null) {
      jsFilter = ((JSObject item) {
        final dartMap = _jsObjectToMap(item);
        return filter(dartMap).toJS;
      }).toJS;
    }

    final jsPromise = _jsSdk.autoConnect(
      _mapToJSObject(options) as JSAny,
      jsFilter,
    );
    final result = await jsPromise.toDart;

    final controllerObj = result as VDONinjaAutoConnectControllerJS;
    final finalStreamID = controllerObj.streamID.toDart;
    final stopFunc = controllerObj.stop;

    return VDONinjaAutoConnectController(
      streamID: finalStreamID,
      onStop: () {
        stopFunc.callAsFunction();
      },
    );
  }

  @override
  void sendData(
    dynamic data, {
    String? uuid,
    String? type,
    String? streamID,
    bool? allowFallback,
    String? preference,
    String? excludeSender,
  }) {
    final options = <String, dynamic>{};
    if (uuid != null) options["uuid"] = uuid;
    if (type != null) options["type"] = type;
    if (streamID != null) options["streamID"] = streamID;
    if (allowFallback != null) options["allowFallback"] = allowFallback;
    if (preference != null) options["preference"] = preference;
    if (excludeSender != null) options["excludeSender"] = excludeSender;

    JSAny jsData;
    if (data is Map || data is List) {
      jsData = (data as dynamic).jsify() as JSAny;
    } else if (data is String) {
      jsData = data.toJS;
    } else if (data is bool) {
      jsData = data.toJS;
    } else if (data is num) {
      jsData = data.toJS;
    } else {
      jsData = data as JSAny;
    }

    _jsSdk.sendData(jsData, _mapToJSObject(options));
  }

  @override
  List<Map<String, dynamic>> getStreams() {
    final rawDartList = _jsSdk.getStreams().toDart;
    final length = rawDartList.length;
    // Performance optimization: Pre-allocate List buffer to avoid dynamic
    // array resizing and reallocation overhead during JSArray conversion.
    final streamsList = List<Map<String, dynamic>>.filled(
      length,
      const <String, dynamic>{},
      growable: true,
    );
    var validCount = 0;
    for (var i = 0; i < length; i++) {
      final item = rawDartList[i];
      if (item != null && item.isA<JSObject>()) {
        streamsList[validCount++] = _jsObjectToMap(item as JSObject);
      }
    }
    streamsList.length = validCount;
    return streamsList;
  }

  @override
  Map<String, dynamic>? getStreamInfo(String streamID) {
    final jsInfo = _jsSdk.getStreamInfo(streamID.toJS);
    if (jsInfo == null || jsInfo.isUndefinedOrNull) return null;
    return _jsObjectToMap(jsInfo);
  }

  @override
  Future<dynamic> addTrack(dynamic track, [dynamic stream]) async {
    final jsTrack = track as JSObject;
    final jsStream = stream != null ? (stream as JSObject) : null;
    final promise = _jsSdk.addTrack(jsTrack, jsStream);
    final result = await promise.toDart;
    return _jsAnyToDart(result);
  }

  @override
  Future<dynamic> removeTrack(dynamic track) async {
    final jsTrack = track as JSObject;
    final promise = _jsSdk.removeTrack(jsTrack);
    final result = await promise.toDart;
    return _jsAnyToDart(result);
  }

  @override
  Future<dynamic> replaceTrack(dynamic oldTrack, dynamic newTrack) async {
    final jsOldTrack = oldTrack as JSObject;
    final jsNewTrack = newTrack as JSObject;
    final promise = _jsSdk.replaceTrack(jsOldTrack, jsNewTrack);
    final result = await promise.toDart;
    return _jsAnyToDart(result);
  }

  @override
  void sendPing(String uuid) {
    _jsSdk.sendPing(uuid.toJS);
  }

  @override
  Future<dynamic> getStats([String? uuid]) async {
    final promise = _jsSdk.getStats(uuid?.toJS);
    final result = await promise.toDart;
    return _jsAnyToDart(result);
  }

  // --- Helper to create and cache Event Streams ---

  Stream<T> _getStream<T>(
    String type,
    T Function(web.CustomEvent event) mapEvent,
  ) {
    if (_controllers.containsKey(type)) {
      return _controllers[type]!.stream as Stream<T>;
    }

    late final StreamController<T> controller;
    controller = StreamController<T>.broadcast(
      onListen: () {
        final JSFunction callback = ((web.Event event) {
          try {
            controller.add(mapEvent(event as web.CustomEvent));
          } catch (e) {
            controller.addError(e);
          }
        }).toJS;

        _jsCallbacks[type] = callback;
        _jsSdk.addEventListener(type.toJS, callback);
      },
      onCancel: () {
        final callback = _jsCallbacks.remove(type);
        if (callback != null) {
          _jsSdk.removeEventListener(type.toJS, callback);
        }
      },
    );
    _controllers[type] = controller;
    return controller.stream;
  }

  void _hookDataChannel(JSObject connection, String uuid) {
    // ⚡ Bolt: Removed redundant hasProperty check, relying on typed getter and isUndefinedOrNull
    final dataChannel = (connection as VDONinjaConnectionJS).dataChannel;
    if (dataChannel == null || dataChannel.isUndefinedOrNull) {
      return;
    }

    final jsDataChannel = dataChannel as JSObject;
    final streamID = connection.streamID?.toDart;

    final JSFunction messageCallback = ((web.MessageEvent event) {
      try {
        final rawData = event.data;

        dynamic parsedData;
        if (rawData.isA<JSString>()) {
          final stringData = (rawData as JSString).toDart;
          try {
            parsedData = jsonDecode(stringData);
          } catch (_) {
            parsedData = stringData;
          }
        } else {
          parsedData = _jsAnyToDart(rawData);
        }

        bool isControlMessage = false;
        if (parsedData is Map) {
          if (parsedData.containsKey("description") ||
              parsedData.containsKey("candidate") ||
              parsedData.containsKey("candidates") ||
              parsedData.containsKey("audio") ||
              parsedData.containsKey("video") ||
              parsedData.containsKey("info") ||
              parsedData.containsKey("ping") ||
              parsedData.containsKey("pong") ||
              parsedData.containsKey("bye") ||
              parsedData.containsKey("videoMuted") ||
              parsedData.containsKey("pipe") ||
              parsedData.containsKey("iceRestartRequest")) {
            isControlMessage = true;
          }
        }

        if (!isControlMessage) {
          final controller = _controllers["dataReceived"];
          if (controller != null && !controller.isClosed) {
            controller.add(
              VDONinjaDataReceivedEvent(
                data: parsedData,
                uuid: uuid,
                streamID: streamID,
              ),
            );
          }
        }
      } catch (_) {}
    }).toJS;

    _dataChannels[uuid] = jsDataChannel;
    _dataChannelCallbacks[uuid] = messageCallback;

    jsDataChannel.callMethod(
      "addEventListener".toJS,
      "message".toJS,
      messageCallback,
    );
  }

  void _removeDataChannelHook(String uuid) {
    final jsDataChannel = _dataChannels.remove(uuid);
    final callback = _dataChannelCallbacks.remove(uuid);

    if (jsDataChannel != null && callback != null) {
      try {
        jsDataChannel.callMethod(
          "removeEventListener".toJS,
          "message".toJS,
          callback,
        );
      } catch (_) {}
    }
  }

  void _removeAllDataChannelHooks() {
    final uuids = _dataChannels.keys.toList();
    for (final uuid in uuids) {
      _removeDataChannelHook(uuid);
    }
  }

  @override
  void dispose() {
    _peerConnectedSub?.cancel();
    _peerConnectedSub = null;
    _connectionFailedSub?.cancel();
    _connectionFailedSub = null;
    _roomLeftSub?.cancel();
    _roomLeftSub = null;

    _removeAllDataChannelHooks();

    for (final entry in _jsCallbacks.entries) {
      final type = entry.key;
      final callback = entry.value;
      _jsSdk.removeEventListener(type.toJS, callback);
    }
    _jsCallbacks.clear();

    for (final controller in _controllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _controllers.clear();
  }

  @override
  Stream<void> get onConnected => _getStream("connected", (_) {});

  @override
  Stream<void> get onDisconnected => _getStream("disconnected", (_) {});

  @override
  Stream<void> get onReconnected => _getStream("reconnected", (_) {});

  @override
  Stream<void> get onReconnectFailed => _getStream("reconnectFailed", (_) {});

  @override
  Stream<Map<String, dynamic>> get onReconnecting =>
      _getStream("reconnecting", (event) {
        final detail = event.detail;
        if (detail != null && detail.isA<JSObject>()) {
          return _jsObjectToMap(detail as JSObject);
        }
        return <String, dynamic>{};
      });

  @override
  Stream<Map<String, dynamic>> get onRoomJoined =>
      _getStream("roomJoined", (event) {
        final detail = event.detail;
        if (detail != null && detail.isA<JSObject>()) {
          return _jsObjectToMap(detail as JSObject);
        }
        return <String, dynamic>{};
      });

  @override
  Stream<Map<String, dynamic>> get onRoomLeft =>
      _getStream("roomLeft", (event) {
        final detail = event.detail;
        if (detail != null && detail.isA<JSObject>()) {
          return _jsObjectToMap(detail as JSObject);
        }
        return <String, dynamic>{};
      });

  @override
  Stream<Map<String, dynamic>> get onPublishing =>
      _getStream("publishing", (event) {
        final detail = event.detail;
        if (detail != null && detail.isA<JSObject>()) {
          return _jsObjectToMap(detail as JSObject);
        }
        return <String, dynamic>{};
      });

  @override
  Stream<Map<String, dynamic>> get onViewingStopped =>
      _getStream("viewingStopped", (event) {
        final detail = event.detail;
        if (detail != null && detail.isA<JSObject>()) {
          return _jsObjectToMap(detail as JSObject);
        }
        return <String, dynamic>{};
      });

  @override
  Stream<VDONinjaTrackEvent> get onTrack => _getStream("track", (event) {
    final detail = event.detail;
    if (detail != null && detail.isA<JSObject>()) {
      final detailObj = detail as VDONinjaEventDetailJS;
      final track = detailObj.track;
      final streamsAny = detailObj.streams;
      final uuid = detailObj.uuid as JSString?;
      final streamID = detailObj.streamID as JSString?;
      late final List<dynamic> streamsList;
      if (streamsAny != null && streamsAny.isA<JSArray>()) {
        final dartList = (streamsAny as JSArray).toDart;
        final length = dartList.length;
        streamsList = List<dynamic>.filled(length, null, growable: true);
        for (var i = 0; i < length; i++) {
          streamsList[i] = dartList[i];
        }
      } else {
        streamsList = <dynamic>[];
      }

      return VDONinjaTrackEvent(
        track: track,
        streams: streamsList,
        uuid: uuid?.toDart ?? "",
        streamID: streamID?.toDart,
      );
    }
    return VDONinjaTrackEvent(track: null, streams: [], uuid: "");
  });

  @override
  Stream<VDONinjaDataReceivedEvent> get onDataReceived =>
      _getStream("dataReceived", (event) {
        final jsEvent = event as VDONinjaEventDetailJS;
        JSAny? data;
        JSString? uuid;
        JSString? streamID;

        final detail = event.detail;
        if (detail != null && !detail.isUndefinedOrNull) {
          final detailObj = detail as VDONinjaEventDetailJS;
          data = detailObj.data;
          uuid = detailObj.uuid as JSString?;
          streamID = detailObj.streamID as JSString?;
        }

        if (data == null || data.isUndefinedOrNull) {
          data = jsEvent.data;
        }
        if (uuid == null || uuid.isUndefinedOrNull) {
          uuid = jsEvent.uuid as JSString?;
        }
        if (streamID == null || streamID.isUndefinedOrNull) {
          streamID = jsEvent.streamID as JSString?;
        }

        return VDONinjaDataReceivedEvent(
          data: _jsAnyToDart(data),
          uuid: uuid?.toDart ?? "",
          streamID: streamID?.toDart,
        );
      });

  @override
  Stream<Map<String, dynamic>> get onPeerConnected =>
      _getStream("peerConnected", (event) {
        final detail = event.detail;
        if (detail != null && detail.isA<JSObject>()) {
          final detailObj = detail as VDONinjaEventDetailJS;
          final uuid = detailObj.uuid as JSString?;
          final connection = detailObj.connection;
          return {
            "uuid": uuid?.toDart ?? "",
            if (connection != null && !connection.isUndefinedOrNull)
              "connection": connection,
          };
        }
        return <String, dynamic>{};
      });

  @override
  Stream<VDONinjaPeerLatencyEvent> get onPeerLatency =>
      _getStream("peerLatency", (event) {
        final detail = event.detail;
        if (detail != null && detail.isA<JSObject>()) {
          final detailObj = detail as VDONinjaEventDetailJS;
          final uuid = detailObj.uuid as JSString?;
          final latency = detailObj.latency as JSNumber?;
          final streamID = detailObj.streamID as JSString?;

          return VDONinjaPeerLatencyEvent(
            uuid: uuid?.toDart ?? "",
            latency: latency?.toDartDouble.toInt() ?? 0,
            streamID: streamID?.toDart,
          );
        }
        return VDONinjaPeerLatencyEvent(uuid: "", latency: 0);
      });

  @override
  Stream<VDONinjaPeerInfoEvent> get onPeerInfo =>
      _getStream("peerInfo", (event) {
        final detail = event.detail;
        if (detail != null && detail.isA<JSObject>()) {
          final detailObj = detail as VDONinjaEventDetailJS;
          final uuid = detailObj.uuid as JSString?;
          final streamID = detailObj.streamID as JSString?;
          final info = detailObj.info as JSObject?;

          return VDONinjaPeerInfoEvent(
            uuid: uuid?.toDart ?? "",
            streamID: streamID?.toDart,
            info: info != null ? _jsObjectToMap(info) : <String, dynamic>{},
          );
        }
        return VDONinjaPeerInfoEvent(uuid: "", info: <String, dynamic>{});
      });

  @override
  Stream<VDONinjaRemoteVideoMuteStateEvent> get onRemoteVideoMuteState =>
      _getStream("remoteVideoMuteState", (event) {
        final detail = event.detail;
        if (detail != null && detail.isA<JSObject>()) {
          final detailObj = detail as VDONinjaEventDetailJS;
          final muted = detailObj.muted as JSBoolean?;
          final trackId = detailObj.trackId as JSString?;
          final streamID = detailObj.streamID as JSString?;
          final uuid = detailObj.uuid as JSString?;
          final connectionType = detailObj.connectionType as JSString?;

          return VDONinjaRemoteVideoMuteStateEvent(
            muted: muted?.toDart ?? false,
            trackId: trackId?.toDart,
            streamID: streamID?.toDart,
            uuid: uuid?.toDart ?? "",
            connectionType: connectionType?.toDart ?? "unknown",
          );
        }
        return VDONinjaRemoteVideoMuteStateEvent(
          muted: false,
          uuid: "",
          connectionType: "unknown",
        );
      });

  @override
  Stream<VDONinjaErrorEvent> get onError => _getStream("error", (event) {
    final detail = event.detail;
    if (detail != null && detail.isA<JSObject>()) {
      final detailObj = detail as VDONinjaEventDetailJS;
      final message =
          detailObj.error as JSString? ??
          detailObj.message as JSString? ??
          "Unknown error".toJS;
      final details = detailObj.details;

      return VDONinjaErrorEvent(
        message: message.toDart,
        details: _jsAnyToDart(details),
      );
    }
    return VDONinjaErrorEvent(message: "Unknown error");
  });

  @override
  Stream<List<dynamic>> get onListing => _getStream("listing", (event) {
    final detail = event.detail;
    if (detail != null && detail.isA<JSObject>()) {
      final detailObj = detail as VDONinjaEventDetailJS;
      final listAny = detailObj.list;
      if (listAny != null && listAny.isA<JSArray>()) {
        final dartList = (listAny as JSArray).toDart;
        final length = dartList.length;
        final resultList = List<dynamic>.filled(length, null, growable: true);
        for (var i = 0; i < length; i++) {
          resultList[i] = _jsAnyToDart(dartList[i]);
        }
        return resultList;
      }
    }
    return <dynamic>[];
  });

  @override
  Stream<Map<String, dynamic>> get onConnectionFailed =>
      _getStream("connectionFailed", (event) {
        final detail = event.detail;
        if (detail != null && detail.isA<JSObject>()) {
          final detailObj = detail as VDONinjaEventDetailJS;
          final uuid = detailObj.uuid as JSString?;
          final reason = detailObj.reason as JSString?;
          return {"uuid": uuid?.toDart ?? "", "reason": reason?.toDart ?? ""};
        }
        return <String, dynamic>{};
      });
}

/// Helper function to create an SDK instance on the Web platform.
VDONinjaSDK createSDK({
  String? host,
  String? room,
  VDONinjaPassword? password,
  String? salt,
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
  return VDONinjaSDKWeb(
    host: host,
    room: room,
    password: password,
    salt: salt,
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

/// Web getter for library loading check.
bool get isSDKLoaded => VDONinjaSDKWeb.isSDKLoaded;

/// Web function for script initialization.
Future<void> initialize({String? cdnUrl, String version = "latest"}) =>
    VDONinjaSDKWeb.initialize(cdnUrl: cdnUrl, version: version);
