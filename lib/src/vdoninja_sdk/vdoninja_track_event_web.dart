import "package:web/web.dart" as web;
import "vdoninja_sdk_base.dart";

extension VDONinjaTrackEventWebExt on VDONinjaTrackEvent {
  web.MediaStreamTrack? get webTrack => track as web.MediaStreamTrack?;
  // ⚡ Bolt: Use List.from() instead of .cast() to avoid lazy CastList dynamic type-checking overhead on every element access.
  List<web.MediaStream> get webStreams => List<web.MediaStream>.from(streams);
}
