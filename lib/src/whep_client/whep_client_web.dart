import "dart:async";
import "dart:js_interop";
import "dart:js_interop_unsafe";
import "package:web/web.dart" as web;
import "whep_client_base.dart";

JSObject _mapToJSObject(Map<String, dynamic> map) {
  return map.jsify() as JSObject;
}

@JS("WHEPClient")
extension type WHEPClientJS._(JSObject _) implements JSObject {
  external WHEPClientJS(JSString endpoint, [JSObject? options]);

  external JSPromise view();
  external JSObject? getStream();
  external void muteAudio(JSBoolean muted);
  external void muteVideo(JSBoolean muted);
  external void stop();
  external JSPromise getStats();

  external void addEventListener(JSString type, JSFunction callback);
  external void removeEventListener(JSString type, JSFunction callback);
}

/// Web-specific implementation of the WHEPClient.
class WHEPClientWeb implements WHEPClient {
  final WHEPClientJS _jsClient;
  final Map<String, StreamController> _controllers = {};
  final Map<String, JSFunction> _jsCallbacks = {};

  WHEPClientWeb({
    required String endpoint,
    String? authToken,
    bool? audio,
    bool? video,
    bool? trickleIce,
  }) : _jsClient = _createJsInstance(
         endpoint: endpoint,
         authToken: authToken,
         audio: audio,
         video: video,
         trickleIce: trickleIce,
       );

  static WHEPClientJS _createJsInstance({
    required String endpoint,
    String? authToken,
    bool? audio,
    bool? video,
    bool? trickleIce,
  }) {
    if (!isWHEPLibraryLoaded) {
      throw StateError(
        "WHEPClient library has not been loaded. Call WHEPClient.initialize() first.",
      );
    }

    final options = <String, dynamic>{};
    if (authToken != null) options["authToken"] = authToken;
    if (audio != null) options["audio"] = audio;
    if (video != null) options["video"] = video;
    if (trickleIce != null) options["trickleIce"] = trickleIce;

    return WHEPClientJS(endpoint.toJS, _mapToJSObject(options));
  }

  @override
  Future<dynamic> view() async {
    final jsPromise = _jsClient.view();
    final result = await jsPromise.toDart;
    return result;
  }

  @override
  dynamic getStream() => _jsClient.getStream();

  @override
  void muteAudio(bool muted) => _jsClient.muteAudio(muted.toJS);

  @override
  void muteVideo(bool muted) => _jsClient.muteVideo(muted.toJS);

  @override
  void stop() => _jsClient.stop();

  @override
  Future<dynamic> getStats() async {
    final jsPromise = _jsClient.getStats();
    final result = await jsPromise.toDart;
    return result;
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
  Stream<dynamic> get onTrack => _getStream("track", (event) {
    if (event.hasProperty("detail".toJS).toDart) {
      return event.getProperty("detail".toJS);
    }
    return event;
  });

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

/// Helper function to create a WHEP client.
WHEPClient createWHEPClient({
  required String endpoint,
  String? authToken,
  bool? audio,
  bool? video,
  bool? trickleIce,
}) {
  return WHEPClientWeb(
    endpoint: endpoint,
    authToken: authToken,
    audio: audio,
    video: video,
    trickleIce: trickleIce,
  );
}

/// Library status check.
bool get isWHEPLibraryLoaded =>
    web.window.hasProperty("WHEPClient".toJS).toDart;

/// Dynamically loads the WHEP Client JavaScript.
Future<void> initializeWHEP({String? cdnUrl, String version = "latest"}) async {
  if (cdnUrl != null) {
    final parsed = Uri.tryParse(cdnUrl);
    // Only throw if there is an explicit scheme and it's not https
    // This allows relative urls and protocol-relative urls to pass
    if (parsed != null && parsed.hasScheme && parsed.scheme != "https") {
      throw ArgumentError("If a scheme is provided in cdnUrl, it must be https");
    }
  }

  if (isWHEPLibraryLoaded) return;
  final completer = Completer<void>();
  final script = web.document.createElement("script") as web.HTMLScriptElement;
  final safeVersion = Uri.encodeComponent(version);
  script.src =
      cdnUrl ??
      "https://cdn.jsdelivr.net/gh/steveseguin/ninjasdk@$safeVersion/whep-client.js";
  script.type = "text/javascript";
  script.async = true;
  script.crossOrigin = "anonymous";

  script.onload = (web.Event event) {
    completer.complete();
  }.toJS;

  script.onerror = (web.Event event) {
    completer.completeError(
      Exception("Failed to load WHEPClient script from ${script.src}"),
    );
  }.toJS;

  web.document.head!.appendChild(script);
  return completer.future;
}
