import "vdoninja_sdk_base.dart";

extension VDONinjaTrackEventWebExt on VDONinjaTrackEvent {
  dynamic get webTrack =>
      throw UnsupportedError("webTrack is only supported on the web platform.");
  List<dynamic> get webStreams => throw UnsupportedError(
    "webStreams is only supported on the web platform.",
  );
}
