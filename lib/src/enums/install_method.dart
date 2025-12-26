/// PWA installation method
enum InstallMethod {
  /// Browser provides native install prompt (Chrome, Edge, Samsung)
  native('Native'),

  /// User must manually add to home screen (iOS Safari)
  manual('Manual'),

  /// Browser does not support PWA installation
  unsupported('Unsupported');

  const InstallMethod(this.displayName);

  /// Human-readable install method name
  final String displayName;

  /// Check if browser supports any form of installation
  bool get isSupported => this != InstallMethod.unsupported;

  /// Check if we can show automated install prompt
  bool get canShowPrompt => this == InstallMethod.native;
}
