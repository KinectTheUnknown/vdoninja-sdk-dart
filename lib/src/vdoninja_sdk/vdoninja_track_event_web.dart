import "package:web/web.dart" as web;
import "vdoninja_sdk_base.dart";

extension VDONinjaTrackEventWebExt on VDONinjaTrackEvent {
  web.MediaStreamTrack? get webTrack => track as web.MediaStreamTrack?;

  // ⚡ Bolt: Removed lazy `.cast()` and replaced it with an upfront List.from
  // to avoid Wasm/JS wrapper type-checking overhead on every array iteration.
  List<web.MediaStream> get webStreams => List<web.MediaStream>.from(streams);
}
