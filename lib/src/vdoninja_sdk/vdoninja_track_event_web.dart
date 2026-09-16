import "package:web/web.dart" as web;
import "vdoninja_sdk_base.dart";

extension VDONinjaTrackEventWebExt on VDONinjaTrackEvent {
  web.MediaStreamTrack? get webTrack => track as web.MediaStreamTrack?;
  List<web.MediaStream> get webStreams => streams.cast<web.MediaStream>();
}
