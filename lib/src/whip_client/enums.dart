/// WHIP video codec.
enum WHIPVideoCodec {
  h264("h264"),
  vp8("vp8"),
  vp9("vp9"),
  av1("av1");

  final String value;
  const WHIPVideoCodec(this.value);
}
