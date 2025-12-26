/// PWA display modes
enum DisplayMode {
  /// App is running in standalone mode (installed PWA)
  standalone('Standalone'),

  /// App is running in fullscreen mode
  fullscreen('Fullscreen'),

  /// App is running with minimal UI
  minimalUi('Minimal UI'),

  /// App is running in a regular browser tab
  browser('Browser');

  const DisplayMode(this.displayName);

  /// Human-readable display mode name
  final String displayName;

  /// Check if the app is installed (not running in browser)
  bool get isInstalled => this != DisplayMode.browser;
}
