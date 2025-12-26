/// Device platform types
enum DevicePlatform {
  /// iOS devices (iPhone, iPad)
  ios('iOS'),

  /// Android devices
  android('Android'),

  /// macOS computers
  macos('macOS'),

  /// Windows computers
  windows('Windows'),

  /// Linux computers
  linux('Linux'),

  /// Unknown or unsupported platform
  unknown('Unknown');

  const DevicePlatform(this.displayName);

  /// Human-readable platform name
  final String displayName;
}
