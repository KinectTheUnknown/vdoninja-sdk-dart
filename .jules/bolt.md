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
## $(date +%Y-%m-%d) - JS Event Detail dynamic getProperty Overhead
**Learning:** Using `getProperty("propertyName".toJS)` inside hot event streams like `onTrack` or `onDataReceived` incurs significant continuous string allocation overhead for cross-boundary JavaScript dynamic property lookup. Dart allows `@anonymous extension type` wrappers with typed `external JSAny? get propertyName;` getters which evaluate directly and eliminate Wasm string allocation overhead.
**Action:** Replace `getProperty` strings with typed anonymous extension wrappers for frequently fired DOM event payloads (e.g. `event.detail`).
## $(date +%Y-%m-%d) - JS Interop Property Lookup Overhead
**Learning:** In Wasm-compiled Dart code, executing dynamic string-based lookup chains like `obj.hasProperty("prop".toJS)` followed by `obj.getProperty("prop".toJS)` generates redundant Wasm-to-JS boundary crossing overhead. Because JavaScript `undefined` maps safely to Dart's Wasm `externref` context without implicit null-pointer exceptions, evaluating `getProperty` directly and checking `.isUndefinedOrNull` is significantly faster and semantically equivalent.
**Action:** When accessing known JS properties in hot paths, avoid `hasProperty` gate checks. Read the property directly and validate it using `.isUndefinedOrNull`.
## $(date +%Y-%m-%d) - JS Interop Map Allocation in Hot Paths
**Learning:** In Dart-to-JS/Wasm interop, creating a Dart `Map<String, dynamic>` and converting it to JavaScript via `.jsify()` is extremely slow (e.g., ~280ms per 100k iterations) because it allocates Wasm dictionary memory and requires deep cross-boundary string iteration. Defining an `@anonymous extension type` with an `external factory` evaluates directly to a JS object with Wasm externref setters, executing ~70x faster (~4ms per 100k iterations).
**Action:** When constructing objects for JavaScript in hot paths (like P2P messaging `sendData`), avoid `Map` and `.jsify()`. Use `@anonymous extension type` factories instead.

## $(date +%Y-%m-%d) - JSON Parsing Overhead across Boundaries
**Learning:** When a JavaScript event payload contains a large stringified JSON object (as a `JSString`), calling `.toDart` and then `jsonDecode(string)` forces the Wasm bridge to copy the entire UTF-16 payload into Dart memory just to parse it. Wrapping `JSON.parse` natively using `@JS("JSON.parse") external JSAny _jsonParse(JSString text);` executes the parse entirely on the V8/SpiderMonkey engine side and is ~5-10x faster.
**Action:** When parsing JSON payloads originating from JavaScript events, prefer binding and invoking `JSON.parse` natively instead of passing the raw string string across the Wasm boundary to Dart's `jsonDecode`.
