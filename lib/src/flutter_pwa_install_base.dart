import 'dart:async';
import 'package:flutter/foundation.dart';

import 'browser_detector.dart';
import 'manifest_validator.dart';
import 'storage_manager.dart';
import 'models/browser_capabilities.dart';
import 'models/install_result.dart';
import 'models/installability_checks.dart';
import 'models/pwa_config.dart';
import 'models/pwa_event.dart';
import 'models/prompt_options.dart';

/// Main class for PWA installation in Flutter web apps
///
/// This is a singleton class that manages PWA installation across all browsers.
/// It provides:
/// - Native install prompts for Chrome/Edge/Samsung
/// - Custom iOS installation instructions
/// - Manifest validation
/// - Smart prompt timing with visit tracking
/// - Analytics event tracking
///
/// Example:
/// ```dart
/// final pwa = FlutterPWAInstall.instance;
///
/// // Initialize with config
/// pwa.setup(
///   config: PWAConfig(
///     delayPrompt: Duration(seconds: 3),
///     maxDismissals: 3,
///     enableAnalytics: true,
///   ),
/// );
///
/// // Show install prompt
/// final result = await pwa.promptInstall();
/// if (result.wasAccepted) {
///   print('User installed the app!');
/// }
/// ```
class FlutterPWAInstall {
  FlutterPWAInstall._();

  static final FlutterPWAInstall _instance = FlutterPWAInstall._();

  /// Get the singleton instance
  static FlutterPWAInstall get instance => _instance;

  late BrowserDetector _detector;
  late ManifestValidator _validator;
  late StorageManager _storage;

  PWAConfig _config = const PWAConfig();
  BrowserCapabilities? _capabilities;
  bool _isInitialized = false;

  /// Initialize the PWA install system
  ///
  /// Call this once in your app, typically in main() before runApp().
  ///
  /// Example:
  /// ```dart
  /// void main() {
  ///   FlutterPWAInstall.instance.setup(
  ///     config: PWAConfig(
  ///       debug: true,
  ///       enableAnalytics: true,
  ///     ),
  ///   );
  ///   runApp(MyApp());
  /// }
  /// ```
  void setup({PWAConfig config = const PWAConfig()}) {
    if (!kIsWeb) {
      if (config.debug) {
        debugPrint('[FlutterPWAInstall] Not running on web, skipping setup');
      }
      return;
    }

    _config = config;
    _detector = BrowserDetector(debug: config.debug);
    _validator = ManifestValidator(debug: config.debug);
    _storage = StorageManager(
      prefix: config.storagePrefix,
      debug: config.debug,
    );

    _isInitialized = true;
    _storage.recordVisit();

    if (config.debug) {
      debugPrint('[FlutterPWAInstall] Initialized successfully');
    }
  }

  /// Check if setup() has been called
  bool get isInitialized => _isInitialized;

  /// Get current configuration
  PWAConfig get config => _config;

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'FlutterPWAInstall not initialized. Call setup() first.',
      );
    }
  }

  void _log(String message) {
    if (_config.debug) {
      debugPrint('[FlutterPWAInstall] $message');
    }
  }

  void _trackEvent(PWAEvent event) {
    if (_config.enableAnalytics && _config.analyticsCallback != null) {
      _config.analyticsCallback!(event);
    }
    _log('Event: ${event.type.name}');
  }

  /// Get browser and platform capabilities
  ///
  /// Returns information about the current browser, platform, and PWA support.
  BrowserCapabilities getCapabilities() {
    _ensureInitialized();
    _capabilities ??= _detector.getCapabilities();
    return _capabilities!;
  }

  /// Check if the app can be installed
  ///
  /// Returns true if:
  /// - App is not already installed
  /// - Platform/browser supports installation
  /// - User hasn't exceeded max dismissals
  /// - Not in cooldown period
  /// - Meets PWA installability requirements
  Future<bool> canInstall() async {
    _ensureInitialized();

    final capabilities = getCapabilities();

    // Already installed
    if (capabilities.isStandalone) {
      _log('App already installed');
      return false;
    }

    // Check storage
    if (_storage.hasBeenInstalled()) {
      _log('App previously installed (from storage)');
      return false;
    }

    if (_storage.hasExceededDismissals(_config.maxDismissals)) {
      _log('Exceeded max dismissals');
      return false;
    }

    if (_storage.isInCooldown(_config.dismissCooldown)) {
      _log('In dismissal cooldown period');
      return false;
    }

    // Check platform support
    if (!capabilities.installMethod.isSupported) {
      _log('Platform does not support installation');
      return false;
    }

    // Validate PWA requirements
    final checks = await checkInstallability();
    if (!checks.meetsMinimumRequirements) {
      _log('Does not meet minimum installability requirements');
      return false;
    }

    return true;
  }

  /// Show the install prompt
  ///
  /// Displays the appropriate install UI based on the browser/platform:
  /// - Chrome/Edge: Native browser prompt
  /// - iOS Safari: Custom dialog with instructions
  /// - Other: Graceful degradation
  ///
  /// Returns an [InstallResult] indicating the outcome.
  ///
  /// Example:
  /// ```dart
  /// final result = await pwa.promptInstall(
  ///   options: PromptOptions(
  ///     onAccepted: () => print('Installed!'),
  ///     onDismissed: () => print('Dismissed'),
  ///   ),
  /// );
  /// ```
  Future<InstallResult> promptInstall({
    PromptOptions options = const PromptOptions(),
  }) async {
    _ensureInitialized();

    try {
      // Check if can install
      final canInstallNow = await canInstall();
      if (!canInstallNow) {
        return InstallResult(
          outcome: InstallOutcome.unsupported,
          timestamp: DateTime.now(),
        );
      }

      // Call onBeforeShow callback
      if (options.onBeforeShow != null) {
        final shouldShow = await options.onBeforeShow!();
        if (!shouldShow) {
          return InstallResult(
            outcome: InstallOutcome.dismissed,
            timestamp: DateTime.now(),
          );
        }
      }

      // Apply delay
      if (_config.delayPrompt > Duration.zero) {
        await Future.delayed(_config.delayPrompt);
      }

      final capabilities = getCapabilities();

      // Track prompt shown
      _trackEvent(PWAEvent(
        type: PWAEventType.promptShown,
        timestamp: DateTime.now(),
        metadata: {
          'platform': capabilities.platform.name,
          'browser': capabilities.browser.name,
        },
      ));

      _storage.recordPromptShown();

      // Show appropriate prompt based on platform
      final result = await _showPlatformSpecificPrompt(
        capabilities,
        options,
      );

      // Handle result
      if (result.wasAccepted) {
        options.onAccepted?.call();
        _trackEvent(PWAEvent(
          type: PWAEventType.installAccepted,
          timestamp: DateTime.now(),
        ));
      } else if (result.wasDismissed) {
        _storage.recordDismissal();
        options.onDismissed?.call();
        _trackEvent(PWAEvent(
          type: PWAEventType.installDismissed,
          timestamp: DateTime.now(),
        ));
      }

      return result;
    } catch (e) {
      _log('Error showing prompt: $e');
      options.onError?.call(e.toString());

      return InstallResult(
        outcome: InstallOutcome.error,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  Future<InstallResult> _showPlatformSpecificPrompt(
    BrowserCapabilities capabilities,
    PromptOptions options,
  ) async {
    // iOS Safari - show custom instructions
    if (capabilities.shouldShowIOSInstructions && _config.showIOSInstructions) {
      return _detector.showIOSInstructions(
        customText: _config.iosInstructionText,
      );
    }

    // Native prompt (Chrome/Edge/Samsung)
    if (capabilities.canShowNativePrompt) {
      return _detector.showNativePrompt();
    }

    // Unsupported
    return InstallResult(
      outcome: InstallOutcome.unsupported,
      timestamp: DateTime.now(),
    );
  }

  /// Validate PWA installability requirements
  ///
  /// Checks if your Flutter web app meets all PWA installation requirements:
  /// - HTTPS (or localhost)
  /// - Valid manifest.json
  /// - Registered Service Worker
  /// - Proper icons
  /// - Required manifest fields
  ///
  /// Example:
  /// ```dart
  /// final checks = await pwa.checkInstallability();
  /// if (!checks.meetsMinimumRequirements) {
  ///   print('Errors: ${checks.errors}');
  /// }
  /// ```
  Future<InstallabilityChecks> checkInstallability() async {
    _ensureInitialized();
    return _validator.checkInstallability();
  }

  /// Get a human-readable installability report
  ///
  /// Returns a formatted string with all installability checks and errors.
  Future<String> getInstallabilityReport() async {
    final checks = await checkInstallability();
    return checks.getReport();
  }

  /// Check if app is currently running in standalone mode (installed)
  bool get isStandalone {
    _ensureInitialized();
    return getCapabilities().isStandalone;
  }

  /// Get current display mode
  String get displayMode {
    _ensureInitialized();
    return getCapabilities().displayMode.displayName;
  }

  /// Get number of times the app has been visited
  int get visitCount {
    _ensureInitialized();
    return _storage.getVisitCount();
  }

  /// Clear all stored data (visits, dismissals, etc.)
  ///
  /// Useful for testing or resetting the install prompt state.
  void clearData() {
    _ensureInitialized();
    _storage.clear();
    _log('Storage cleared');
  }

  /// Reset the instance (useful for testing)
  @visibleForTesting
  void reset() {
    _isInitialized = false;
    _capabilities = null;
    _config = const PWAConfig();
  }
}
