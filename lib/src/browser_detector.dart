import 'dart:html' as html;
import 'dart:js_interop';
import 'package:flutter/material.dart';

import 'enums/browser.dart';
import 'enums/display_mode.dart';
import 'enums/install_method.dart';
import 'enums/platform.dart';
import 'models/browser_capabilities.dart';
import 'models/install_result.dart';

// =============================================================================
// BeforeInstallPromptEvent JS Interop (Non-Standard Chrome API)
// =============================================================================
//
// WHY dart:html + dart:js_interop (not package:web):
//
// 1. BeforeInstallPromptEvent is a NON-STANDARD API only in Chromium browsers
//    - Not part of official Web IDL specs
//    - package:web is generated from Web IDL, so it doesn't include this
//
// 2. dart:html provides stable DOM access (window, navigator, document)
//    - Well-tested in Flutter web projects
//    - Simpler API for common operations (addEventListener, localStorage)
//
// 3. dart:js_interop handles the custom PWA prompt event
//    - Extension types for type-safe JS interop
//    - Future-compatible (replaces deprecated dart:js_util)
//
// MIGRATION NOTE: When package:web adds BeforeInstallPromptEvent support,
// this file can be migrated. Track: https://github.com/nickmeinhold/pwa_install
// =============================================================================

/// Extension type for the userChoice result
extension type _UserChoiceResult._(JSObject _) implements JSObject {
  external String get outcome;
  external String? get platform;
}

/// Extension type for BeforeInstallPromptEvent (Chromium-only)
extension type _BeforeInstallPromptEventJS._(JSObject _) implements JSObject {
  external void prompt();
  external JSPromise<_UserChoiceResult> get userChoice;
}

/// Dart wrapper for BeforeInstallPromptEvent with proper Future handling
class BeforeInstallPromptEvent {
  BeforeInstallPromptEvent._(this._jsEvent);

  final _BeforeInstallPromptEventJS _jsEvent;

  /// Create from a raw html.Event (cast to JS interop type)
  factory BeforeInstallPromptEvent.fromEvent(html.Event event) {
    // Cast the dart:html Event to our JS interop extension type
    final jsObject = (event as dynamic) as JSObject;
    return BeforeInstallPromptEvent._(_BeforeInstallPromptEventJS._(jsObject));
  }

  /// Shows the install prompt to the user
  void prompt() => _jsEvent.prompt();

  /// Returns a Future that resolves with the user's choice
  Future<InstallPromptResult> getUserChoice() async {
    final result = await _jsEvent.userChoice.toDart;
    return InstallPromptResult(
      outcome: result.outcome,
      platform: result.platform,
    );
  }
}

/// Result from the user's install prompt interaction
class InstallPromptResult {
  const InstallPromptResult({required this.outcome, this.platform});

  /// 'accepted' if user installed, 'dismissed' if user cancelled
  final String outcome;

  /// The platform chosen (e.g., 'web' for browser install)
  final String? platform;
}

/// Detects browser, platform, and handles install prompts
class BrowserDetector {
  BrowserDetector({this.debug = false}) {
    _setupEventListeners();
  }

  final bool debug;
  BeforeInstallPromptEvent? _deferredPrompt;

  void _setupEventListeners() {
    // Listen for beforeinstallprompt event
    html.window.addEventListener('beforeinstallprompt', (event) {
      event.preventDefault();
      _deferredPrompt = BeforeInstallPromptEvent.fromEvent(event);
      if (debug) {
        debugPrint('[BrowserDetector] beforeinstallprompt event captured');
      }
    });

    // Listen for appinstalled event
    html.window.addEventListener('appinstalled', (event) {
      if (debug) {
        debugPrint('[BrowserDetector] App installed');
      }
    });
  }

  /// Detect the current platform
  DevicePlatform detectPlatform() {
    final ua = html.window.navigator.userAgent.toLowerCase();

    if (RegExp(r'iphone|ipad|ipod').hasMatch(ua)) {
      return DevicePlatform.ios;
    }
    if (ua.contains('android')) {
      return DevicePlatform.android;
    }
    if (ua.contains('mac os x')) {
      return DevicePlatform.macos;
    }
    if (ua.contains('windows')) {
      return DevicePlatform.windows;
    }
    if (ua.contains('linux')) {
      return DevicePlatform.linux;
    }

    return DevicePlatform.unknown;
  }

  /// Detect the current browser
  BrowserType detectBrowser() {
    final ua = html.window.navigator.userAgent.toLowerCase();

    // Order matters - check Edge before Chrome
    if (RegExp(r'edg').hasMatch(ua)) {
      return BrowserType.edge;
    }
    if (ua.contains('samsungbrowser')) {
      return BrowserType.samsung;
    }
    if (RegExp(r'opr|opera').hasMatch(ua)) {
      return BrowserType.opera;
    }
    if (RegExp(r'chrome|crios|crmo').hasMatch(ua)) {
      return BrowserType.chrome;
    }
    if (ua.contains('safari') && !ua.contains('chrome')) {
      return BrowserType.safari;
    }
    if (RegExp(r'firefox|fxios').hasMatch(ua)) {
      return BrowserType.firefox;
    }

    return BrowserType.unknown;
  }

  /// Detect current display mode
  DisplayMode detectDisplayMode() {
    // Check for iOS standalone mode
    final nav = html.window.navigator as dynamic;
    if (nav.standalone == true) {
      return DisplayMode.standalone;
    }

    // Check display-mode media queries
    if (html.window.matchMedia('(display-mode: standalone)').matches) {
      return DisplayMode.standalone;
    }
    if (html.window.matchMedia('(display-mode: fullscreen)').matches) {
      return DisplayMode.fullscreen;
    }
    if (html.window.matchMedia('(display-mode: minimal-ui)').matches) {
      return DisplayMode.minimalUi;
    }

    // Check for TWA (Trusted Web Activity) on Android
    if (html.document.referrer.startsWith('android-app://')) {
      return DisplayMode.standalone;
    }

    return DisplayMode.browser;
  }

  /// Check if beforeinstallprompt is supported
  bool supportsBeforeInstallPrompt() {
    final browser = detectBrowser();
    return [
      BrowserType.chrome,
      BrowserType.edge,
      BrowserType.samsung,
      BrowserType.opera,
    ].contains(browser);
  }

  /// Check if Service Workers are supported
  bool supportsServiceWorker() {
    return html.window.navigator.serviceWorker != null;
  }

  /// Check if Web App Manifest is supported
  bool supportsWebManifest() {
    final browser = detectBrowser();
    // Most browsers support manifest except older Firefox
    return browser != BrowserType.firefox;
  }

  /// Check if app is running in standalone mode
  bool isStandalone() {
    return detectDisplayMode() != DisplayMode.browser;
  }

  /// Determine the best installation method
  InstallMethod detectInstallMethod() {
    final platform = detectPlatform();
    final browser = detectBrowser();

    // iOS Safari requires manual A2HS
    if (platform == DevicePlatform.ios && browser == BrowserType.safari) {
      return InstallMethod.manual;
    }

    // Chrome, Edge, Samsung, Opera support native prompt
    if (supportsBeforeInstallPrompt()) {
      return InstallMethod.native;
    }

    // Desktop Safari supports native install
    if (platform == DevicePlatform.macos && browser == BrowserType.safari) {
      return InstallMethod.native;
    }

    return InstallMethod.unsupported;
  }

  /// Get comprehensive browser capabilities
  BrowserCapabilities getCapabilities() {
    return BrowserCapabilities(
      supportsBeforeInstallPrompt: supportsBeforeInstallPrompt(),
      supportsServiceWorker: supportsServiceWorker(),
      supportsWebManifest: supportsWebManifest(),
      isStandalone: isStandalone(),
      platform: detectPlatform(),
      browser: detectBrowser(),
      installMethod: detectInstallMethod(),
      displayMode: detectDisplayMode(),
    );
  }

  /// Check if in secure context (HTTPS or localhost)
  bool isSecureContext() {
    return html.window.isSecureContext ?? false;
  }

  /// Show native browser install prompt (Chrome/Edge/Samsung)
  Future<InstallResult> showNativePrompt() async {
    if (_deferredPrompt == null) {
      return InstallResult(
        outcome: InstallOutcome.unsupported,
        timestamp: DateTime.now(),
        error: 'No deferred prompt available',
      );
    }

    try {
      // Show the prompt
      _deferredPrompt!.prompt();

      // Wait for user choice
      final choiceResult = await _deferredPrompt!.getUserChoice();

      // Clear the deferred prompt
      _deferredPrompt = null;

      if (choiceResult.outcome == 'accepted') {
        return InstallResult(
          outcome: InstallOutcome.accepted,
          platform: choiceResult.platform,
          timestamp: DateTime.now(),
        );
      } else {
        return InstallResult(
          outcome: InstallOutcome.dismissed,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      if (debug) {
        debugPrint('[BrowserDetector] Error showing native prompt: $e');
      }
      return InstallResult(
        outcome: InstallOutcome.error,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Show iOS installation instructions dialog
  ///
  /// Note: This method returns a placeholder result. The actual iOS install
  /// instructions dialog should be shown by the Flutter app using the
  /// IOSInstallDialog widget.
  Future<InstallResult> showIOSInstructions({String? customText}) async {
    // iOS requires manual "Add to Home Screen" from the share menu
    // The Flutter app should show IOSInstallDialog to guide users
    return InstallResult(
      outcome: InstallOutcome.dismissed,
      timestamp: DateTime.now(),
    );
  }
}
