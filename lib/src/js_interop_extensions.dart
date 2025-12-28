import 'dart:js_interop';
import 'package:web/web.dart' as web;

// =============================================================================
// JS Interop Extension Types for Non-Standard Web APIs
// =============================================================================
//
// These extension types provide type-safe access to browser-specific APIs
// that are not part of the official Web IDL specs and therefore not included
// in package:web.
//
// 1. BeforeInstallPromptEvent - Chromium-only PWA install prompt API
// 2. NavigatorStandalone - Safari-only property for checking standalone mode
// =============================================================================

/// Result from the user's install prompt interaction (Chromium-only)
extension type UserChoiceResult._(JSObject _) implements JSObject {
  /// 'accepted' if user installed, 'dismissed' if user cancelled
  external String get outcome;

  /// The platform chosen (e.g., 'web' for browser install)
  external String? get platform;
}

/// BeforeInstallPromptEvent - Chromium-only PWA install event
///
/// This event fires when the browser determines the app meets PWA
/// installability criteria and is ready to show an install prompt.
/// Only supported in Chrome, Edge, Samsung Internet, and Opera.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/BeforeInstallPromptEvent
extension type BeforeInstallPromptEventJS._(JSObject _) implements web.Event {
  /// Shows the install prompt to the user
  external void prompt();

  /// Returns a Promise that resolves with the user's choice
  external JSPromise<UserChoiceResult> get userChoice;
}

/// Navigator extension for Safari's standalone property
///
/// This non-standard property only exists in Safari (iOS/macOS).
/// Accessing it in other browsers throws an error.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/Navigator/standalone
extension type NavigatorStandalone._(JSObject _) implements JSObject {
  /// True if running in standalone mode (iOS Safari only)
  external bool? get standalone;
}

/// Wrapper class for BeforeInstallPromptEvent with proper Dart Future handling
class BeforeInstallPromptEvent {
  BeforeInstallPromptEvent._(this._jsEvent);

  final BeforeInstallPromptEventJS _jsEvent;

  /// Create from a raw web.Event (cast to JS interop type)
  factory BeforeInstallPromptEvent.fromEvent(web.Event event) {
    final jsObject = event as JSObject;
    return BeforeInstallPromptEvent._(BeforeInstallPromptEventJS._(jsObject));
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

/// Check if navigator.standalone property exists (Safari only)
bool hasStandaloneProperty() {
  try {
    final nav = web.window.navigator as NavigatorStandalone;
    return nav.standalone != null;
  } catch (e) {
    return false;
  }
}

/// Get the standalone value safely (returns null if not Safari)
bool? getStandaloneValue() {
  try {
    final nav = web.window.navigator as NavigatorStandalone;
    return nav.standalone;
  } catch (e) {
    return null;
  }
}
