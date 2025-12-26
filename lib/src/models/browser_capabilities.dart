import '../enums/browser.dart';
import '../enums/display_mode.dart';
import '../enums/install_method.dart';
import '../enums/platform.dart';

/// Comprehensive browser and platform capabilities
class BrowserCapabilities {
  const BrowserCapabilities({
    required this.supportsBeforeInstallPrompt,
    required this.supportsServiceWorker,
    required this.supportsWebManifest,
    required this.isStandalone,
    required this.platform,
    required this.browser,
    required this.installMethod,
    required this.displayMode,
  });

  /// Whether browser supports the beforeinstallprompt event
  final bool supportsBeforeInstallPrompt;

  /// Whether browser supports Service Workers
  final bool supportsServiceWorker;

  /// Whether browser supports Web App Manifest
  final bool supportsWebManifest;

  /// Whether app is currently running in standalone mode
  final bool isStandalone;

  /// Device platform (iOS, Android, etc.)
  final DevicePlatform platform;

  /// Browser type (Chrome, Safari, etc.)
  final BrowserType browser;

  /// Best installation method for this browser
  final InstallMethod installMethod;

  /// Current display mode
  final DisplayMode displayMode;

  /// Check if platform is iOS
  bool get isIOS => platform == DevicePlatform.ios;

  /// Check if platform is Android
  bool get isAndroid => platform == DevicePlatform.android;

  /// Check if browser is Safari
  bool get isSafari => browser == BrowserType.safari;

  /// Check if this is iOS Safari (requires special handling)
  bool get isIOSSafari => isIOS && isSafari;

  /// Check if browser can show native install prompt
  bool get canShowNativePrompt =>
      supportsBeforeInstallPrompt && !isStandalone;

  /// Check if we should show iOS instructions
  bool get shouldShowIOSInstructions =>
      isIOSSafari && !isStandalone;

  @override
  String toString() {
    return 'BrowserCapabilities('
        'platform: ${platform.displayName}, '
        'browser: ${browser.displayName}, '
        'displayMode: ${displayMode.displayName}, '
        'installMethod: ${installMethod.displayName}, '
        'isStandalone: $isStandalone'
        ')';
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'supportsBeforeInstallPrompt': supportsBeforeInstallPrompt,
      'supportsServiceWorker': supportsServiceWorker,
      'supportsWebManifest': supportsWebManifest,
      'isStandalone': isStandalone,
      'platform': platform.name,
      'browser': browser.name,
      'installMethod': installMethod.name,
      'displayMode': displayMode.name,
    };
  }
}
