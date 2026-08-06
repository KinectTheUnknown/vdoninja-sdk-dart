## 2024-07-09 - JS Array parsing memory allocation
**Learning:** Calling `List<dynamic>.generate` relies on dynamic memory allocation mapping for each array element, which creates significant execution overhead on `JSArray` conversions in dart:js_interop logic. Pre-allocating a fixed `List<dynamic>.filled(length, null)` buffer and indexing manually runs faster and scales better. We shouldn't use `JSON.stringify()` serialization due to data loss of non-stringifiable elements like `NaN`, `Infinity` and JS Functions when iterating array indices in Flutter web boundaries.
**Action:** Always prefer statically pre-allocated lists `List.filled(length)` over `List.generate()` when traversing large JavaScript arrays across Dart JS interop.

## 2026-07-12 - JS Event Listener Memory Leak on Stream Getters
**Learning:** Creating a new `StreamController.broadcast` every time a getter like `onTrack` is accessed registers duplicate JavaScript event listeners via `addEventListener`. Since getters are often evaluated multiple times (e.g. by Flutter's `StreamBuilder` across rebuilds), this creates severe memory leaks and CPU overhead due to redundant JS callbacks firing.
**Action:** Always cache the `StreamController` internally (e.g., using a `Map<String, StreamController>` keyed by event type) when exposing JavaScript events as Dart streams to ensure only one listener is bound to the JS SDK.

## 2024-05-24 - JS Interop Serialization Overhead
**Learning:** Using `JSON.parse(jsonEncode(obj))` and `jsonDecode(JSON.stringify(obj))` for bridging Dart Maps/Lists and JavaScript Objects across boundaries creates immense string allocation and serialization overhead. Dart's native `.jsify()` and `.dartify()` avoid intermediate strings and lossy JSON conversions while keeping interop fast.
**Action:** Always use `.jsify()` to cast Dart maps/iterables to JS objects and `.dartify()` with a `try/catch` block for safe backward mapping instead of bridging via JSON.
## $(date +%Y-%m-%d) - Prevent Redundant SDK Script Loading
**Learning:** Calling `initialize()` concurrently across multiple UI components (e.g. WHIP and WHEP widgets mounting simultaneously) can cause race conditions in the DOM, where the same large JavaScript SDK `<script>` tag is injected multiple times before the first one finishes loading.
**Action:** When creating asynchronous initialization methods that inject DOM elements or load external scripts, always use a cached file-level or class-level `Future` variable (`_initFuture`) to track the in-progress state and return it immediately to prevent redundant network requests and DOM pollution.
## 2024-08-06 - Removing web.console.log statements for performance and security
**Learning:** Using `web.console.log` directly in JS interop hot event callbacks creates significant cross-boundary overhead as the raw event object has to be continuously marshaled across the JS-Dart interop barrier before being processed. In addition, logging WebRTC `CustomEvent` or raw `DataChannel` message data can leak sensitive user information (like keys, passwords, IP addresses via ICE candidates) to end-users and malicious browser extensions.
**Action:** Never use `web.console.log` to output raw unparsed event and data channel objects directly to the browser console inside hot JS interop callbacks.
