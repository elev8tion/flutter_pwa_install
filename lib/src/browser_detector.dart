import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'enums/browser.dart';
import 'enums/display_mode.dart';
import 'enums/install_method.dart';
import 'enums/platform.dart';
import 'js_interop_extensions.dart';
import 'models/browser_capabilities.dart';
import 'models/install_result.dart';

// =============================================================================
// Browser Detection and PWA Installation Handler
// =============================================================================
//
// Uses package:web for standard Web APIs and dart:js_interop for non-standard
// browser APIs (BeforeInstallPromptEvent, navigator.standalone).
//
// See: MIGRATION_TO_PACKAGE_WEB.md for migration details
// =============================================================================

/// Detects browser, platform, and handles install prompts
class BrowserDetector {
  BrowserDetector({this.debug = false}) {
    _setupEventListeners();
  }

  final bool debug;
  BeforeInstallPromptEvent? _deferredPrompt;

  void _setupEventListeners() {
    // Listen for beforeinstallprompt event (Chromium-only)
    debugPrint('[BrowserDetector] Setting up beforeinstallprompt listener...');
    web.window.addEventListener(
      'beforeinstallprompt',
      ((web.Event event) {
        debugPrint('[BrowserDetector] *** beforeinstallprompt EVENT FIRED! ***');
        event.preventDefault();
        _deferredPrompt = BeforeInstallPromptEvent.fromEvent(event);
        debugPrint('[BrowserDetector] Deferred prompt captured successfully');
      }).toJS,
    );

    // Listen for appinstalled event
    web.window.addEventListener(
      'appinstalled',
      ((web.Event event) {
        if (debug) {
          debugPrint('[BrowserDetector] App installed');
        }
      }).toJS,
    );
  }

  /// Detect the current platform
  DevicePlatform detectPlatform() {
    final ua = web.window.navigator.userAgent.toLowerCase();

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
    final ua = web.window.navigator.userAgent.toLowerCase();

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
    // Safari-only: Check navigator.standalone (iOS/macOS Safari specific property)
    // This property ONLY exists in Safari - accessing it in other browsers throws an error
    if (detectBrowser() == BrowserType.safari) {
      final standaloneValue = getStandaloneValue();
      if (standaloneValue == true) {
        return DisplayMode.standalone;
      }
    }

    // All browsers: Check display-mode media queries (standard, works everywhere)
    if (web.window.matchMedia('(display-mode: standalone)').matches) {
      return DisplayMode.standalone;
    }
    if (web.window.matchMedia('(display-mode: fullscreen)').matches) {
      return DisplayMode.fullscreen;
    }
    if (web.window.matchMedia('(display-mode: minimal-ui)').matches) {
      return DisplayMode.minimalUi;
    }

    // Check for TWA (Trusted Web Activity) on Android
    if (web.document.referrer.startsWith('android-app://')) {
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
    // In package:web, serviceWorker is always available on modern browsers
    // The property exists if the browser supports Service Workers
    try {
      // Access the serviceWorker to confirm it's available
      web.window.navigator.serviceWorker;
      return true;
    } catch (e) {
      return false;
    }
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
    return web.window.isSecureContext;
  }

  /// Show native browser install prompt (Chrome/Edge/Samsung)
  Future<InstallResult> showNativePrompt() async {
    debugPrint('[BrowserDetector] showNativePrompt called, _deferredPrompt is ${_deferredPrompt == null ? "NULL" : "available"}');
    if (_deferredPrompt == null) {
      debugPrint('[BrowserDetector] ERROR: beforeinstallprompt event was never captured by Chrome!');
      debugPrint('[BrowserDetector] This usually means Chrome does not consider the app installable yet.');
      return InstallResult(
        outcome: InstallOutcome.unsupported,
        timestamp: DateTime.now(),
        error: 'No deferred prompt available - Chrome did not fire beforeinstallprompt',
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
