/// AutoConnect mode.
enum VDONinjaAutoConnectMode {
  half("half"),
  full("full");

  final String value;
  const VDONinjaAutoConnectMode(this.value);
}

/// Connection type.
enum VDONinjaConnectionType {
  viewer("viewer"),
  publisher("publisher"),
  unknown("unknown");

  final String value;
  const VDONinjaConnectionType(this.value);

  static VDONinjaConnectionType fromString(String val) {
    return VDONinjaConnectionType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => VDONinjaConnectionType.unknown,
    );
  }
}
