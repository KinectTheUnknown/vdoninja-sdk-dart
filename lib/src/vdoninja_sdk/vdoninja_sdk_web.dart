import "dart:async";
import "dart:convert";
import "dart:js_interop";
import "dart:js_interop_unsafe";
import "package:web/web.dart" as web;
import "vdoninja_sdk_base.dart";

@JS("JSON.parse")
external JSObject _jsJsonParse(JSString jsonStr);

@JS("JSON.stringify")
external JSString _jsJsonStringify(JSObject obj);

/// Helper to convert a Dart Map or List to a JSObject or JSArray.
JSObject _mapToJSObject(Map<String, dynamic> map) {
  final jsonStr = jsonEncode(map);
  return _jsJsonParse(jsonStr.toJS);
}

/// Helper to convert a JSObject to a Dart Map.
Map<String, dynamic> _jsObjectToMap(JSObject obj) {
  final jsonStr = _jsJsonStringify(obj).toDart;
  return jsonDecode(jsonStr) as Map<String, dynamic>;
}

/// Helper to convert a JS object/primitive to a Dart value.
dynamic _jsAnyToDart(JSAny? value) {
  if (value == null || value.isUndefinedOrNull) return null;
  if (value.isA<JSBoolean>()) return (value as JSBoolean).toDart;
  if (value.isA<JSNumber>()) return (value as JSNumber).toDartDouble;
  if (value.isA<JSString>()) return (value as JSString).toDart;
  if (value.isA<JSArray>()) {
    final dartList = (value as JSArray).toDart;
    final length = dartList.length;
    final list = List<dynamic>.filled(length, null, growable: true);
    for (var i = 0; i < length; i++) {
      list[i] = _jsAnyToDart(dartList[i]);
    }
    return list;
  }
  if (value.isA<JSObject>()) {
    try {
      final jsonStr = _jsJsonStringify(value as JSObject).toDart;
      return jsonDecode(jsonStr);
    } catch (_) {
      return value; // Return as-is if it's a complex JS object (e.g. MediaStream)
    }
  }
  return value;
}

@JS("VDONinjaSDK")
extension type VDONinjaSDKJS._(JSObject _) implements JSObject {
  external VDONinjaSDKJS([JSObject? options]);

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

  external void addEventListener(JSString type, JSFunction callback);
  external void removeEventListener(JSString type, JSFunction callback);
}

/// Web-specific implementation of the VDO.Ninja SDK using JS interop.
class VDONinjaSDKWeb implements VDONinjaSDK {
  final VDONinjaSDKJS _jsSdk;
  final Map<String, StreamController> _controllers = {};
  final Map<String, JSFunction> _jsCallbacks = {};

  VDONinjaSDKWeb({
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
  }) : _jsSdk = _createJsInstance(
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

  static VDONinjaSDKJS _createJsInstance({
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
    if (!isSDKLoaded) {
      throw StateError(
        "VDO.Ninja SDK has not been loaded. Call VDO.Ninja SDK.initialize() first.",
      );
    }

    final options = <String, dynamic>{};
    if (host != null) options["host"] = host;
    if (room != null) options["room"] = room;
    if (password != null) options["password"] = password.value;
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
    return web.window.hasProperty("VDONinjaSDK".toJS).toDart;
  }

  /// Dynamically inject the VDO.Ninja SDK JavaScript library into the page.
  static Future<void> initialize({String? cdnUrl}) async {
    if (isSDKLoaded) return;
    final completer = Completer<void>();
    final script =
        web.document.createElement("script") as web.HTMLScriptElement;
    script.src = cdnUrl ?? "https://unpkg.com/@vdoninja/sdk/vdoninja-sdk.js";
    script.type = "text/javascript";
    script.async = true;

    script.onload = (web.Event event) {
      completer.complete();
    }.toJS;

    script.onerror = (web.Event event) {
      completer.completeError(
        Exception("Failed to load VDO.Ninja SDK script from ${script.src}"),
      );
    }.toJS;

    web.document.head!.appendChild(script);
    return completer.future;
  }

  JSObject? get _state {
    if (_jsSdk.hasProperty("state".toJS).toDart) {
      return _jsSdk.getProperty<JSObject?>("state".toJS);
    }
    return null;
  }

  @override
  bool get isConnected {
    final state = _state;
    if (state == null) return false;
    return state.getProperty<JSBoolean?>("connected".toJS)?.toDart ?? false;
  }

  @override
  String? get room {
    final state = _state;
    if (state == null) return null;
    return state.getProperty<JSString?>("room".toJS)?.toDart;
  }

  @override
  String? get streamID {
    final state = _state;
    if (state == null) return null;
    return state.getProperty<JSString?>("streamID".toJS)?.toDart;
  }

  @override
  String? get uuid {
    final state = _state;
    if (state == null) return null;
    return state.getProperty<JSString?>("uuid".toJS)?.toDart;
  }

  @override
  bool get isRoomJoined {
    final state = _state;
    if (state == null) return false;
    return state.getProperty<JSBoolean?>("roomJoined".toJS)?.toDart ?? false;
  }

  @override
  bool get isPublishing {
    final state = _state;
    if (state == null) return false;
    return state.getProperty<JSBoolean?>("publishing".toJS)?.toDart ?? false;
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
    VDONinjaPassword? password,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? viewPreferences,
  }) async {
    final options = <String, dynamic>{};
    if (password != null) options["password"] = password.value;
    if (preferences != null) options["preferences"] = preferences;
    if (viewPreferences != null) options["viewPreferences"] = viewPreferences;

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

    final controllerObj = result as JSObject;
    final finalStreamID =
        (controllerObj.getProperty("streamID".toJS) as JSString).toDart;
    final stopFunc = controllerObj.getProperty("stop".toJS) as JSFunction;

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
  }) {
    final options = <String, dynamic>{};
    if (uuid != null) options["uuid"] = uuid;
    if (type != null) options["type"] = type;
    if (streamID != null) options["streamID"] = streamID;
    if (allowFallback != null) options["allowFallback"] = allowFallback;
    if (preference != null) options["preference"] = preference;

    JSAny jsData;
    if (data is Map || data is List) {
      jsData = _jsJsonParse(jsonEncode(data).toJS);
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
    return _jsSdk
        .getStreams()
        .toDart
        .where((item) => item != null && item.isA<JSObject>())
        .map((item) => _jsObjectToMap(item as JSObject))
        .toList();
  }

  @override
  Map<String, dynamic>? getStreamInfo(String streamID) {
    final jsInfo = _jsSdk.getStreamInfo(streamID.toJS);
    if (jsInfo == null || jsInfo.isUndefinedOrNull) return null;
    return _jsObjectToMap(jsInfo);
  }

  // --- Helper to create and cache Event Streams ---

  Stream<T> _getStream<T>(
    String type,
    T Function(web.CustomEvent event) mapEvent,
  ) {
    late final StreamController<T> controller;
    controller = StreamController<T>.broadcast(
      onListen: () {
        final JSFunction callback = ((web.Event event) {
          try {
            if (event.isA<web.CustomEvent>()) {
              controller.add(mapEvent(event as web.CustomEvent));
            }
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
      final detailObj = detail as JSObject;
      final track = detailObj.getProperty("track".toJS);
      final streamsAny = detailObj.getProperty("streams".toJS);
      final uuid = detailObj.getProperty("uuid".toJS) as JSString?;
      final streamID = detailObj.getProperty("streamID".toJS) as JSString?;
      final streamsList = streamsAny != null && streamsAny.isA<JSArray>()
          ? List<dynamic>.from((streamsAny as JSArray).toDart)
          : <dynamic>[];

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
        final detail = event.detail;
        if (detail != null && detail.isA<JSObject>()) {
          final detailObj = detail as JSObject;
          final data = detailObj.getProperty("data".toJS);
          final uuid = detailObj.getProperty("uuid".toJS) as JSString?;
          final streamID = detailObj.getProperty("streamID".toJS) as JSString?;

          return VDONinjaDataReceivedEvent(
            data: _jsAnyToDart(data),
            uuid: uuid?.toDart ?? "",
            streamID: streamID?.toDart,
          );
        }
        return VDONinjaDataReceivedEvent(data: null, uuid: "");
      });

  @override
  Stream<Map<String, dynamic>> get onPeerConnected =>
      _getStream("peerConnected", (event) {
        final detail = event.detail;
        if (detail != null && detail.isA<JSObject>()) {
          final detailObj = detail as JSObject;
          final uuid = detailObj.getProperty("uuid".toJS) as JSString?;
          return {"uuid": uuid?.toDart ?? ""};
        }
        return <String, dynamic>{};
      });

  @override
  Stream<VDONinjaPeerLatencyEvent> get onPeerLatency =>
      _getStream("peerLatency", (event) {
        final detail = event.detail;
        if (detail != null && detail.isA<JSObject>()) {
          final detailObj = detail as JSObject;
          final uuid = detailObj.getProperty("uuid".toJS) as JSString?;
          final latency = detailObj.getProperty("latency".toJS) as JSNumber?;
          final streamID = detailObj.getProperty("streamID".toJS) as JSString?;

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
          final detailObj = detail as JSObject;
          final uuid = detailObj.getProperty("uuid".toJS) as JSString?;
          final streamID = detailObj.getProperty("streamID".toJS) as JSString?;
          final info = detailObj.getProperty("info".toJS) as JSObject?;

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
          final detailObj = detail as JSObject;
          final muted = detailObj.getProperty("muted".toJS) as JSBoolean?;
          final trackId = detailObj.getProperty("trackId".toJS) as JSString?;
          final streamID = detailObj.getProperty("streamID".toJS) as JSString?;
          final uuid = detailObj.getProperty("uuid".toJS) as JSString?;
          final connectionType =
              detailObj.getProperty("connectionType".toJS) as JSString?;

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
      final detailObj = detail as JSObject;
      final message =
          detailObj.getProperty("error".toJS) as JSString? ??
          detailObj.getProperty("message".toJS) as JSString? ??
          "Unknown error".toJS;
      final details = detailObj.getProperty("details".toJS);

      return VDONinjaErrorEvent(
        message: message.toDart,
        details: _jsAnyToDart(details),
      );
    }
    return VDONinjaErrorEvent(message: "Unknown error");
  });
}

/// Helper function to create an SDK instance on the Web platform.
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
  return VDONinjaSDKWeb(
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

/// Web getter for library loading check.
bool get isSDKLoaded => VDONinjaSDKWeb.isSDKLoaded;

/// Web function for script initialization.
Future<void> initialize({String? cdnUrl}) =>
    VDONinjaSDKWeb.initialize(cdnUrl: cdnUrl);
