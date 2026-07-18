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
  final Map<String, StreamController> _controllers = {};
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
  void stop() => _jsClient.stop();

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
    if (event.hasProperty("detail".toJS).toDart) {
      final detail = event.getProperty("detail".toJS);
      if (detail != null && detail.isA<JSString>()) {
        return (detail as JSString).toDart;
      }
    }
    return "unknown";
  });

  @override
  Stream<String> get onConnectionState =>
      _getStream("connectionstate", (event) {
        if (event.hasProperty("detail".toJS).toDart) {
          final detail = event.getProperty("detail".toJS);
          if (detail != null && detail.isA<JSString>()) {
            return (detail as JSString).toDart;
          }
        }
        return "unknown";
      });

  @override
  Stream<dynamic> get onError => _getStream("error", (event) {
    if (event.hasProperty("detail".toJS).toDart) {
      return event.getProperty("detail".toJS);
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
bool get isWHIPLibraryLoaded =>
    web.window.hasProperty("WHIPClient".toJS).toDart;

/// Dynamically loads the WHIP Client JavaScript.
Future<void> initializeWHIP({String? cdnUrl, String version = "latest"}) async {
  if (cdnUrl != null && Uri.tryParse(cdnUrl)?.scheme.toLowerCase() != "https") {
    throw ArgumentError.value(cdnUrl, "cdnUrl", "Must be a valid HTTPS URL");
  }

  if (isWHIPLibraryLoaded) return;
  final completer = Completer<void>();
  final script = web.document.createElement("script") as web.HTMLScriptElement;
  final safeVersion = Uri.encodeComponent(version);
  script.src =
      cdnUrl ??
      "https://cdn.jsdelivr.net/gh/steveseguin/ninjasdk@$safeVersion/whip-client.js";
  script.type = "text/javascript";
  script.async = true;
  script.crossOrigin = "anonymous";

  script.onload = (web.Event event) {
    completer.complete();
  }.toJS;

  script.onerror = (web.Event event) {
    completer.completeError(
      Exception("Failed to load WHIPClient script from ${script.src}"),
    );
  }.toJS;

  web.document.head!.appendChild(script);
  return completer.future;
}
