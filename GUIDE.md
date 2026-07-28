# VDO.Ninja SDK - Dart AI/LLM Integration Guide

## Complete SDK Knowledge for Dart AI Systems

This document contains all the information needed for AI systems to understand and implement the VDO.Ninja SDK in Dart/Flutter. Use this guide as a complete, comprehensive context for Dart-based integrations.

---

## ⚠️ CRITICAL: Usage Requirements

**IMPORTANT**: Direct WebSocket API access is NOT permitted. Your AI system MUST use this SDK.

- **SDK ONLY**: Direct WebSocket connections to VDO.Ninja servers will be blocked.
- **API Changes**: The WebSocket API may change without notice - only the SDK is guaranteed to work.
- **Rate Limits**: Excessive requests will result in throttling or blocking.
- **Data Policy**: Only WebRTC handshake data through WebSocket - all application data must use P2P.
- **Connection Limits**: ~80 connections per room maximum.
- **Serverless Design**: No state management or data relay through signaling server.

Failure to follow these guidelines may result in your application being blocked.

## What is VDO.Ninja SDK Dart?

VDO.Ninja SDK Dart is a type-safe Dart P2P communication framework wrapping the official JavaScript SDK. It enables direct audio, video, and low-latency data streaming in Flutter Web applications without requiring servers, user accounts, or complex infrastructure.

## Key Features for Dart AI Implementation

- **No Human Intervention Required**: No CAPTCHA, no account creation, no email verification.
- **Server-Free Architecture**: After initial WebRTC handshake, all communication is direct P2P.
- **Free Forever**: No hosting costs, no API fees, no usage limits.
- **Data Channel Focus**: Perfect for AI bots that need bidirectional data communication.
- **Works Locally**: Can run without SSL for local development/testing.
- **Simple Type-Safe API**: Minimal Dart code required to establish connections.

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  vdoninja_sdk:
    path: path/to/vdoninja-sdk-dart
```

Ensure you initialize the SDK at startup before creating any SDK instances. This dynamically injects the official VDO.Ninja library:

```dart
import "package:vdoninja_sdk/vdoninja_sdk.dart";

void main() async {
  // Dynamically load the VDO.Ninja JS library
  await VDONinjaSDK.initialize();
  runApp(const MyApp());
}
```

> **Viewer workflow tip:** When sharing **room-based** links from publishers, append `?scene&room=ROOMNAME` so viewers land in listen-only mode. For **direct view links** (`?view=STREAMID` without a room), do NOT add `&scene` or `&solo`. Keep room and stream identifiers alphanumeric/underscore. If you choose `password: VDONinjaPassword.disable`, remind viewers to include `&password=false` in the URL; with the default password you can share the hashed `sdk.streamID` directly.

## Core Concepts

1. **Rooms**: Virtual spaces identified by a string where peers meet.
2. **Publish**: Capability to send data/media to others.
3. **View**: Capability to receive data/media from others.
4. **Data Channels**: Low-latency bidirectional data streams.
5. **No Persistent Server**: The signaling server only facilitates initial connection.

## Basic Implementation

### 1. Minimal Data Channel Setup

```dart
import "package:vdoninja_sdk/vdoninja_sdk.dart";

void main() async {
  await VDONinjaSDK.initialize();

  // Create SDK instance (salt is optional, set for compatibility with vdo.ninja)
  final vdo = VDONinjaSDK(
    salt: "vdo.ninja",
  );

  // Handle incoming data
  vdo.onDataReceived.listen((event) {
    print("Received: ${event.data} from: ${event.uuid}");
  });

  // Connect to signaling server
  await vdo.connect(host: "wss://wss.vdo.ninja");

  // Join a room
  await vdo.joinRoom(room: "my-ai-room");

  // Announce as data-only publisher
  await vdo.announce(streamID: "ai_bot_1");

  // Send data to all peers
  vdo.sendData({"type": "greeting", "message": "Hello from Dart AI!"});
}
```

### 2. AI Bot Pattern

```dart
import "dart:async";
import "package:vdoninja_sdk/vdoninja_sdk.dart";

class AIBot {
  final String roomId;
  late final VDONinjaSDK vdo;
  final Map<String, int> peers = {};
  final List<StreamSubscription> _subs = [];

  AIBot(this.roomId) {
    vdo = VDONinjaSDK();
  }

  Future<void> start() async {
    // Handle peer connections
    _subs.add(vdo.onPeerConnected.listen((event) {
      final uuid = event["uuid"] as String;
      print("Peer connected: $uuid");
      peers[uuid] = DateTime.now().millisecondsSinceEpoch;
    }));

    // Handle peer disconnections
    _subs.add(vdo.onDisconnected.listen((_) {
      print("Disconnected from server");
    }));

    // Handle incoming messages
    _subs.add(vdo.onDataReceived.listen((event) async {
      final response = await processMessage(event.data, event.uuid);
      if (response != null) {
        vdo.sendData(response, uuid: event.uuid);
      }
    }));

    // Connect to server and join room
    await vdo.connect(host: "wss://wss.vdo.ninja");
    await vdo.joinRoom(room: roomId);
    await vdo.announce(streamID: "ai_bot_${DateTime.now().millisecondsSinceEpoch}");
  }

  Future<Map<String, dynamic>?> processMessage(dynamic data, String uuid) async {
    if (data is Map && data["type"] == "query") {
      return {
        "type": "response",
        "result": await aiProcess(data["content"] as String),
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      };
    }
    return null;
  }

  Future<String> aiProcess(String content) async {
    return "AI response to: $content";
  }

  void stop() {
    for (final sub in _subs) {
      sub.cancel();
    }
    vdo.disconnect();
  }
}
```

## Connection Methods Reference

```dart
// Constructor options
final vdo = VDONinjaSDK(
  host: 'wss://wss.vdo.ninja',                        // WebSocket server URL
  room: 'myroom',                                      // Initial room name (optional)
  password: VDONinjaPassword.string('password123'),    // Room password (optional)
  salt: 'vdo.ninja',                                   // Set for vdo.ninja stream compatibility (important!)
  debug: true,                                         // Enable debug logging
  turnServers: null,                                   // null=auto-fetch, disable=disable, list=custom
  forceTURN: false,                                    // Force relay mode
  maxReconnectAttempts: 5                              // Max reconnection attempts
);

// Connect to signaling server
await vdo.connect(
  host: 'wss://wss.vdo.ninja',
  room: 'myroom',
  password: VDONinjaPassword.string('password123'),
);

// Join a room
await vdo.joinRoom(
  room: 'myroom',
  password: VDONinjaPassword.string('password123'),
  claim: false,                                        // Claim director status (optional)
);

// Publish a media stream (stream is a dynamic JSObject representing MediaStream on web)
await vdo.publish(mediaStream,
  streamID: 'custom_id',                               // Custom stream ID (optional)
  room: 'myroom',                                      // Room name (optional if already joined)
  label: 'Main Camera',                                // Stream label (optional)
);

// Announce as data-only publisher
await vdo.announce(
  streamID: 'bot_1',                                   // Stream ID (recommended)
);

// View a stream
await vdo.view('streamID',
  audio: true,                                         // Request audio (default: true)
  video: true,                                         // Request video (default: true)
  label: 'Viewer 1',                                   // Viewer label (optional)
);
```

## Event Listeners (Streams)

In Dart, event handlers are exposed as type-safe Dart streams (`Stream`):

```dart
// Connection events
vdo.onConnected.listen((_) {
  print('Connected to signaling server');
});

vdo.onDisconnected.listen((_) {
  print('Disconnected from server');
});

vdo.onPeerConnected.listen((event) {
  final uuid = event['uuid'];
  final connection = event['connection']; // Underlying RTCPeerConnection object on web
  print('Peer connected: $uuid');
});

vdo.onConnectionFailed.listen((event) {
  print('Connection failed to peer: ${event['uuid']} reason: ${event['reason']}');
});

// Media events  
vdo.onTrack.listen((event) {
  // event.track is the native MediaStreamTrack
  // event.streams is the list of MediaStreams
  print('Track received: ${event.track} from: ${event.uuid}');
});

// Data events
vdo.onDataReceived.listen((event) {
  print('Data received: ${event.data} from: ${event.uuid}');
});

// Room events
vdo.onRoomJoined.listen((event) {
  print('Joined room: ${event['room']}');
});

vdo.onListing.listen((list) {
  print('Room members: $list');
});

// Error handling
vdo.onError.listen((event) {
  print('Error: ${event.message}');
});
```

## Core Methods

### Connection Management
```dart
await vdo.connect();                     // Connect to signaling server
vdo.disconnect();                        // Disconnect from server
await vdo.joinRoom(room: "myroom");      // Join a room
vdo.leaveRoom();                         // Leave current room
```

### Publishing
```dart
await vdo.publish(stream, options);      // Publish media stream
await vdo.announce(options);             // Announce as data-only publisher
vdo.stopPublishing();                    // Stop publishing
```

### Viewing
```dart
await vdo.view(streamID, options);       // View a stream
vdo.stopViewing(streamID);               // Stop viewing a stream
```

### Data Communication
```dart
vdo.sendData(data, {uuid, type, streamID, allowFallback, preference, excludeSender});
vdo.sendPing(uuid);                      // Send ping (either role; DC-only)

// Target options passed as named parameters:
// - uuid: Send to specific peer UUID
// - type: Send to all "viewer" or "publisher" channels
// - streamID: Send to connections associated with the stream ID
// - allowFallback: Set to true to use WebSocket if P2P is unavailable
// - excludeSender: Peer UUID to exclude from broadcasting
```

### Track Management
```dart
await vdo.addTrack(track, [stream]);      // Add track to publishers
await vdo.removeTrack(track);             // Remove track from publishers
await vdo.replaceTrack(oldTrack, newTrack); // Replace track
```

### Statistics & Utilities
```dart
final stats = await vdo.getStats(uuid);   // Get connection statistics (returns Map or JSObject)

// Quick methods (convenience wrappers)
await vdo.quickPublish(stream, ...);      // Connect, join, and publish
await vdo.quickView(streamID: streamID);  // Connect, join, and view
```

## Common AI Use Cases in Dart

### 1. Customer Support Bot
```dart
final supportBot = VDONinjaSDK();

supportBot.onDataReceived.listen((event) async {
  final data = event.data;
  if (data is Map && data['type'] == 'support_request') {
    final solution = await analyzeIssue(data['issue']);
    
    supportBot.sendData({
      'type': 'support_response',
      'solution': solution,
      'confidence': 0.95
    }, uuid: event.uuid);
  }
});

await supportBot.connect(host: 'wss://wss.vdo.ninja');
await supportBot.joinRoom(room: 'support_channel');
await supportBot.announce(streamID: 'support_bot');
```

### 2. Real-time Translation Bot
```dart
final translatorBot = VDONinjaSDK();

translatorBot.onDataReceived.listen((event) async {
  final data = event.data;
  if (data is Map && data['type'] == 'translate') {
    final translated = await translateText(data['text'], data['targetLang']);
    
    translatorBot.sendData({
      'type': 'translation',
      'original': data['text'],
      'translated': translated,
      'fromLang': data['fromLang'],
      'toLang': data['targetLang']
    }, excludeSender: event.uuid);
  }
});

await translatorBot.connect(host: 'wss://wss.vdo.ninja');
await translatorBot.joinRoom(room: 'global_chat');
await translatorBot.announce(streamID: 'translator_bot');
```

### 3. IoT Data Aggregator
```dart
final iotHub = VDONinjaSDK();
final sensorData = <String, Map<String, dynamic>>{};

iotHub.onDataReceived.listen((event) {
  final data = event.data;
  if (data is Map && data['type'] == 'sensor_data') {
    sensorData[event.uuid] = {
      ...data,
      'lastUpdate': DateTime.now().millisecondsSinceEpoch
    };
    
    if (detectAnomaly(sensorData)) {
      iotHub.sendData({
        'type': 'alert',
        'message': 'Anomaly detected',
        'data': sensorData.values.toList()
      });
    }
  }
});

await iotHub.connect(host: 'wss://wss.vdo.ninja');
await iotHub.joinRoom(room: 'sensor_network');
```

### 4. Collaborative AI Assistant
```dart
final aiAssistant = VDONinjaSDK();

final handlers = {
  'code_review': (payload) => reviewCode(payload),
  'generate': (payload) => generateContent(payload),
  'analyze': (payload) => analyzeData(payload),
  'chat': (payload) => chatResponse(payload),
};

aiAssistant.onDataReceived.listen((event) async {
  final data = event.data;
  if (data is Map) {
    final handler = handlers[data['type']];
    if (handler != null) {
      final result = await handler(data['payload']);
      aiAssistant.sendData({
        'type': 'response',
        'requestId': data['requestId'],
        'result': result
      }, uuid: event.uuid);
    }
  }
});

await aiAssistant.connect(host: 'wss://wss.vdo.ninja');
await aiAssistant.joinRoom(room: 'ai_workspace');
await aiAssistant.announce(streamID: 'ai_assistant');
```

## Binary Data Handling

You can send binary payloads (like files or image bytes) directly from Dart using standard typed lists like `Uint8List` or `ByteBuffer`:

```dart
// Send binary data (e.g., file bytes)
final Uint8List fileBytes = await file.readAsBytes();
vdo.sendData(fileBytes);

// Receive binary data
vdo.onDataReceived.listen((event) {
  if (event.data is ByteBuffer || event.data is Uint8List) {
    final bytes = event.data is ByteBuffer ? (event.data as ByteBuffer).asUint8List() : event.data as Uint8List;
    // Process the raw bytes...
  }
});
```

## Error Handling

Exposed via `onError` stream:

```dart
vdo.onError.listen((event) {
  print('VDO.Ninja Error: ${event.message}');
  
  if (event.message.contains('Permission')) {
    // Handle camera/mic permission errors
  } else if (event.message.contains('Network')) {
    // Handle network drops
  } else if (event.message.contains('TURN')) {
    // Firewall/NAT constraints
  }
});
```

Additionally monitor reconnection statuses:
```dart
vdo.onReconnecting.listen((event) {
  print('Reconnecting... Attempt ${event['attempt']}/${event['maxAttempts']}');
});

vdo.onReconnected.listen((_) {
  print('Reconnected successfully');
});
```

## Platform Support

- **Web target**: Fully compiles and interacts directly with the JavaScript VDO.Ninja core.
- **Native targets** (Android, iOS, Windows, macOS, Linux): Automatically falls back to safe stubs. Standard API calls will throw an `UnsupportedError` allowing your app to compile cleanly without conditional import clutter.

## Quick Copy-Paste Examples

### Minimal Bot Setup
```dart
final vdo = VDONinjaSDK();
vdo.onDataReceived.listen((event) {
  print('Received: ${event.data} from: ${event.uuid}');
});
await vdo.connect(host: "wss://wss.vdo.ninja");
await vdo.joinRoom(room: "test");
await vdo.announce(streamID: "bot_1");
vdo.sendData({"message": "Bot is ready!"});
```

### Request-Response Pattern
```dart
final vdo = VDONinjaSDK();
vdo.onDataReceived.listen((event) async {
  final data = event.data;
  if (data is Map && data.containsKey('request')) {
    final response = await processRequest(data['request']);
    vdo.sendData({'response': response}, uuid: event.uuid);
  }
});
await vdo.connect(host: "wss://wss.vdo.ninja");
await vdo.joinRoom(room: "api-room");
await vdo.announce(streamID: "api-bot");
```

### Broadcast Pattern
```dart
final vdo = VDONinjaSDK();
await vdo.connect(host: "wss://wss.vdo.ninja");
await vdo.joinRoom(room: "broadcast");
await vdo.announce(streamID: "broadcaster");

Timer.periodic(const Duration(seconds: 1), (timer) {
  vdo.sendData({
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'data': getLatestData()
  });
});
```
