# VDO.Ninja SDK Dart

A high-performance Flutter package providing a type-safe Dart wrapper around the official **VDO.Ninja SDK** (formerly OBS.Ninja) JavaScript library.

This package is a Dart wrapper around the official [VDO.Ninja JS SDK](https://github.com/steveseguin/vdo.ninja) created and maintained by [Steve Seguin](https://github.com/steveseguin).

This package allows Flutter Web applications to easily integrate low-latency WebRTC peer-to-peer audio, video, and data channels. By design, the package does not recreate any WebRTC or signaling logic in Dart; instead, it delegates all streaming operations to the official VDO.Ninja JS script.

## Features

- **Type-safe Dart Interface**: Wraps all core JS SDK options, methods, and classes in clean Dart classes.
- **Dynamic Script Injection**: Automatically downloads and injects the official VDO.Ninja JS library at runtime—no manual HTML edits required.
- **Stream-based Events**: Connect to type-safe Dart streams for all SDK lifecycle events (connection states, room updates, peer connections, remote video mute changes, and custom P2P data).
- **Comprehensive Options**: Full support for room hashing/passwords, custom STUN/TURN configurations, video/audio codecs, and bitrate preferences.
- **Cross-Platform Compilation**: Uses conditional imports to compile cleanly on all Flutter targets (Web, Android, iOS, Windows, macOS, and Linux), throwing friendly `UnsupportedError` warnings on non-web platforms.

## Getting started

Add `vdoninja_sdk` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  vdoninja_sdk:
    path: ../vdoninja-sdk-dart # Replace with package path or pub version
```

## Usage

### 1. Initialize the SDK
Before creating any SDK instances on the Web, you must initialize the library. This dynamically loads the official script into the browser context if it is not already loaded:

```dart
import "package:vdoninja_sdk/vdoninja_sdk.dart";

void main() async {
  // Initialize the VDO.Ninja JS SDK
  await VDONinjaSDK.initialize();
  
  runApp(const MyApp());
}
```

### 2. Connect & Join a Room
Create an instance of the SDK and connect to the VDO.Ninja signaling server:

```dart
final sdk = VDONinjaSDK(
  debug: true,
  password: .string("myRoomSecretPassword"), // Automatically hashes the room and encrypts SDP/ICE
  stunServers: [
    .new(urls: ["stun:stun.l.google.com:19302"]),
  ],
  turnServers: .list([
    .new(
      urls: ["turn:my-turn-server.com:443"],
      username: "user",
      credential: "password",
    ),
  ]),
);

// Subscribe to connection states
sdk.onConnected.listen((_) {
  print("Connected to VDO.Ninja signaling server!");
});

sdk.onRoomJoined.listen((details) {
  print("Successfully joined room: ${details["room"]}");
});

sdk.onError.listen((event) {
  print("SDK Error: ${event.message}");
});

// Connect to signaling and join the room
await sdk.connect(host: "wss://wss.vdo.ninja");
await sdk.joinRoom(room: "my_awesome_stage_room");
```

### 3. Publish Local Media
To publish video and audio, pass a native `MediaStream` (on Web, obtained via `web.window.navigator.mediaDevices.getUserMedia`) to the `publish` method:

```dart
// Obtain your HTML5 MediaStream
final mediaStream = await web.window.navigator.mediaDevices.getUserMedia(
  web.MediaStreamConstraints(video: true.toJS, audio: true.toJS),
).toDart;

// Publish the stream
await sdk.publish(
  mediaStream,
  streamID: "my_publisher_stream_id",
  label: "Presenter Video",
);
```

### 4. View a Stream & Receive Tracks
Listen to incoming track events to receive and play WebRTC media streams from other peers in the room:

```dart
sdk.onTrack.listen((event) {
  print("Received track from peer ${event.uuid} (Stream ID: ${event.streamID})");
  
  if (event.streams.isNotEmpty) {
    final remoteStream = event.streams.first;
    // Attach remoteStream to a video element in your UI
  }
});

// Subscribe to view a specific stream ID
await sdk.view("peer_stream_id");
```

### 5. Send & Receive Custom P2P Data
Send low-latency custom messages directly to other peers using WebRTC Data Channels:

```dart
// Listen to incoming messages
sdk.onDataReceived.listen((event) {
  print("Received message from ${event.uuid}: ${event.data}");
});

// Send custom data to a specific peer
sdk.sendData(
  {"chatMessage": "Hello there!", "timestamp": DateTime.now().millisecondsSinceEpoch},
  uuid: "peer_uuid",
);

// Broadcast data to all viewers
sdk.sendData(
  {"systemAlert": "The show is starting!"},
  type: "viewer",
);
```

### 6. WHIP & WHEP Standalone Clients
The package also includes standalone wrapper support for the standard WebRTC-HTTP Ingestion Protocol (WHIP) and WebRTC-HTTP Egress Protocol (WHEP) clients. These are isolated modules that do not use the VDO.Ninja WebSocket signaling system.

#### WHIP Client (Publishing/Ingestion)
To push video/audio streams to any WHIP-compatible server (e.g. Twitch, Cloudflare Stream, Dolby.io, or Meshcast.io):

```dart
import "package:vdoninja_sdk/whip_client.dart";

// Initialize the library
await WHIPClient.initialize();

final whip = WHIPClient(
  endpoint: "https://your-whip-endpoint.com/stream",
  videoCodec: "h264",
);

whip.onConnected.listen((_) => print("WHIP Ingest Connected!"));
whip.onError.listen((e) => print("WHIP Ingest Error: $e"));

// Publish a MediaStream
await whip.publish(mediaStream);
```

#### WHEP Client (Subscribing/Playback)
To play back live streams from any WHEP-compatible player URL:

```dart
import "package:vdoninja_sdk/whep_client.dart";

// Initialize the library
await WHEPClient.initialize();

final whep = WHEPClient(
  endpoint: "https://your-whep-endpoint.com/stream",
);

whep.onTrack.listen((event) {
  // Access and play the remote stream/track
});

// Start viewing
await whep.view();
```

## Additional information

### Running on Mobile & Desktop Platforms
Because the official VDO.Ninja SDK is built around browser APIs (WebRTC, MediaStreams, WebSockets, and `postMessage`), it cannot run in a headless native Dart environment. 

To use this SDK on non-web platforms (like iOS/Android/Windows/Mac):
1. Embed a WebView widget (e.g., using `webview_flutter` or `flutter_inappwebview`) loading an HTML page that includes the `vdoninja-sdk.js` script.
2. Communicate between your Dart application and the WebView using JavaScript Channels (postMessage/evalJavaScript).
3. The package includes safe stubs for all platform targets, allowing you to compile your code on all devices. Calling SDK methods on native platforms will throw an `UnsupportedError` to prevent silent failures.

## Credits & Attribution

This package is a community-driven wrapper and is not officially affiliated with the core VDO.Ninja project.

- **Original Author & Creator**: [Steve Seguin](https://github.com/steveseguin)
- **Official VDO.Ninja Website**: [vdo.ninja](https://vdo.ninja)
- **Official GitHub Repository**: [steveseguin/vdo.ninja](https://github.com/steveseguin/vdo.ninja)
- **Official JS SDK on NPM**: [@vdoninja/sdk](https://www.npmjs.com/package/@vdoninja/sdk)


## Contributing

To contribute to this project, you need to set up the pre-commit git hooks:

```bash
git config core.hooksPath .git_hooks
```
