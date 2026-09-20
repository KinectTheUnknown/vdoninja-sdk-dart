import "dart:async";
import "dart:js_interop";
import "dart:js_interop_unsafe";
import "package:web/web.dart" as web;
import "whip_client_base.dart";

JSObject _mapToJSObject(Map<String, dynamic> map) {
  return map.jsify() as JSObject;
}

@JS("WHIPClient")
extension type WHIPClientJS._(JSObject _) implements JSObject {
  external WHIPClientJS(JSString endpoint, [JSObject? options]);

  external JSPromise publish(JSObject stream);
  external JSPromise replaceTrack(JSObject oldTrack, JSObject newTrack);
  external void stop();
  external JSPromise getStats();
  external JSPromise restartIce();

  external void addEventListener(JSString type, JSFunction callback);
  external void removeEventListener(JSString type, JSFunction callback);
}

/// Web-specific implementation of the WHIPClient.
class WHIPClientWeb implements WHIPClient {
  final WHIPClientJS _jsClient;
  final Map<String, StreamController<dynamic>> _controllers = {};
  final Map<String, JSFunction> _jsCallbacks = {};

  WHIPClientWeb({
    required String endpoint,
    String? authToken,
    String? videoCodec,
    int? videoBitrate,
    int? audioBitrate,
    bool? trickleIce,
  }) : _jsClient = _createJsInstance(
         endpoint: endpoint,
         authToken: authToken,
         videoCodec: videoCodec,
         videoBitrate: videoBitrate,
         audioBitrate: audioBitrate,
         trickleIce: trickleIce,
       );

  static WHIPClientJS _createJsInstance({
    required String endpoint,
    String? authToken,
    String? videoCodec,
    int? videoBitrate,
    int? audioBitrate,
    bool? trickleIce,
  }) {
    if (!isWHIPLibraryLoaded) {
      throw StateError(
        "WHIPClient library has not been loaded. Call WHIPClient.initialize() first.",
      );
    }

    final options = <String, dynamic>{};
    if (authToken != null) options["authToken"] = authToken;
    if (videoCodec != null) options["videoCodec"] = videoCodec;
    if (videoBitrate != null) options["videoBitrate"] = videoBitrate;
    if (audioBitrate != null) options["audioBitrate"] = audioBitrate;
    if (trickleIce != null) options["trickleIce"] = trickleIce;

    return WHIPClientJS(endpoint.toJS, _mapToJSObject(options));
  }

  @override
  Future<void> publish(dynamic stream) async {
    final JSObject jsStream;
    try {
      jsStream = stream as JSObject;
    } catch (_) {
      throw ArgumentError("stream must be a JSObject representing MediaStream");
    }

    final jsPromise = _jsClient.publish(jsStream);
    await jsPromise.toDart;
  }

  @override
  Future<void> replaceTrack(dynamic oldTrack, dynamic newTrack) async {
    final JSObject jsOldTrack;
    final JSObject jsNewTrack;
    try {
      jsOldTrack = oldTrack as JSObject;
      jsNewTrack = newTrack as JSObject;
    } catch (_) {
      throw ArgumentError(
        "tracks must be JSObjects representing MediaStreamTracks",
      );
    }

    final jsPromise = _jsClient.replaceTrack(jsOldTrack, jsNewTrack);
    await jsPromise.toDart;
  }

  @override
  void stop() => dispose();

  @override
  void dispose() {
    _jsClient.stop();

    for (final entry in _jsCallbacks.entries) {
      final type = entry.key;
      final callback = entry.value;
      _jsClient.removeEventListener(type.toJS, callback);
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
  Future<dynamic> getStats() async {
    final jsPromise = _jsClient.getStats();
    final result = await jsPromise.toDart;
    return result;
  }

  @override
  Future<void> restartIce() async {
    final jsPromise = _jsClient.restartIce();
    await jsPromise.toDart;
  }

  Stream<T> _getStream<T>(String type, T Function(web.Event event) mapEvent) {
    if (_controllers.containsKey(type)) {
      return _controllers[type]!.stream as Stream<T>;
    }

    late final StreamController<T> controller;
    controller = StreamController<T>.broadcast(
      onListen: () {
        final JSFunction callback = ((web.Event event) {
          try {
            controller.add(mapEvent(event));
          } catch (e) {
            controller.addError(e);
          }
        }).toJS;

        _jsCallbacks[type] = callback;
        _jsClient.addEventListener(type.toJS, callback);
      },
      onCancel: () {
        final callback = _jsCallbacks.remove(type);
        if (callback != null) {
          _jsClient.removeEventListener(type.toJS, callback);
        }
      },
    );
    _controllers[type] = controller;
    return controller.stream;
  }

  @override
  Stream<void> get onConnecting => _getStream("connecting", (_) {});

  @override
  Stream<void> get onConnected => _getStream("connected", (_) {});

  @override
  Stream<String> get onIceState => _getStream("icestate", (event) {
    // Performance optimization: Avoid dynamic property lookups inside hot callbacks
    if (event.isA<web.CustomEvent>()) {
      final detail = (event as web.CustomEvent).detail;
      if (detail != null && detail.isA<JSString>()) {
        return (detail as JSString).toDart;
      }
    }
    return "unknown";
  });

  @override
  Stream<String> get onConnectionState => _getStream("connectionstate", (
    event,
  ) {
    // Performance optimization: Eliminate unnecessary string allocation on property lookup
    if (event.isA<web.CustomEvent>()) {
      final detail = (event as web.CustomEvent).detail;
      if (detail != null && detail.isA<JSString>()) {
        return (detail as JSString).toDart;
      }
    }
    return "unknown";
  });

  @override
  Stream<dynamic> get onError => _getStream("error", (event) {
    // Performance optimization: Fast path for CustomEvent details without stringify
    if (event.isA<web.CustomEvent>()) {
      return (event as web.CustomEvent).detail;
    }
    return event;
  });

  @override
  Stream<void> get onDisconnected => _getStream("disconnected", (_) {});

  @override
  Stream<void> get onStopped => _getStream("stopped", (_) {});
}

/// Helper function to create a WHIP client.
WHIPClient createWHIPClient({
  required String endpoint,
  String? authToken,
  String? videoCodec,
  int? videoBitrate,
  int? audioBitrate,
  bool? trickleIce,
}) {
  return WHIPClientWeb(
    endpoint: endpoint,
    authToken: authToken,
    videoCodec: videoCodec,
    videoBitrate: videoBitrate,
    audioBitrate: audioBitrate,
    trickleIce: trickleIce,
  );
}

/// Library status check.
bool get isWHIPLibraryLoaded => () {
  final val = web.window.getProperty("WHIPClient".toJS);
  return val != null && !val.isUndefinedOrNull;
}();

// Cache the initialization future to prevent redundant <script> injections
// and race conditions if initialize() is called concurrently.
Future<void>? _initWhipFuture;

/// Dynamically loads the WHIP Client JavaScript.
Future<void> initializeWHIP({String? cdnUrl, String version = "latest"}) async {
  if (cdnUrl != null) {
    final parsed = Uri.tryParse(cdnUrl);
    if (parsed == null || parsed.scheme != "https") {
      throw ArgumentError(
        "cdnUrl must be an HTTPS URL to prevent malicious injection.",
      );
    }
  }
  if (isWHIPLibraryLoaded) return;
  if (_initWhipFuture != null) return _initWhipFuture;

  final completer = Completer<void>();
  _initWhipFuture = completer.future;

  final script = web.document.createElement("script") as web.HTMLScriptElement;
  final safeVersion = Uri.encodeComponent(version);
  script.src =
      cdnUrl ??
      "https://cdn.jsdelivr.net/gh/steveseguin/ninjasdk@$safeVersion/whip-client.js";
  script.type = "text/javascript";
  script.async = true;
  script.crossOrigin = "anonymous";

  script.onload = (web.Event event) {
    _initWhipFuture = null;
    completer.complete();
  }.toJS;

  script.onerror = (web.Event event) {
    _initWhipFuture = null;
    completer.completeError(
      Exception("Failed to load WHIPClient script from ${script.src}"),
    );
  }.toJS;

  web.document.head!.appendChild(script);
  return completer.future;
}
