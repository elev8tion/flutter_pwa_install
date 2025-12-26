# ADR-001: Web Interop Strategy (dart:html + dart:js_interop)

**Status:** Accepted
**Date:** 2025-12-26

## Context

This Flutter PWA package needs to access browser APIs for:
- PWA install prompts (`BeforeInstallPromptEvent`)
- localStorage for state persistence
- Navigator/Window for platform detection
- Document for manifest validation

We evaluated two approaches:
1. **package:web only** - Modern, generated from Web IDL
2. **dart:html + dart:js_interop** - Stable DOM access + custom interop

## Decision

**Use `dart:html` for DOM access + `dart:js_interop` for PWA-specific APIs**

## Rationale

### Why NOT package:web alone:

1. **BeforeInstallPromptEvent is non-standard**
   - Chromium-only API, not in official Web IDL specs
   - package:web is auto-generated from Web IDL → doesn't include it
   - Would require defining custom extension types anyway

2. **HttpRequest.getString() has no equivalent**
   - package:web requires manual fetch() + promise handling
   - dart:html provides convenient async wrappers

3. **The package was mixing both incorrectly**
   - Original code: `event as web.BeforeInstallPromptEvent` → runtime error
   - web.BeforeInstallPromptEvent doesn't exist in package:web

### Why dart:html + dart:js_interop:

1. **dart:html** - Stable, well-tested DOM access
   - `html.window.localStorage`
   - `html.window.navigator.userAgent`
   - `html.window.matchMedia()`
   - `html.document.querySelector()`
   - `html.HttpRequest.getString()`

2. **dart:js_interop** - Type-safe custom JS interop
   - Extension types for `BeforeInstallPromptEvent`
   - Future-compatible (replaces deprecated dart:js_util)
   - Required for non-standard browser APIs

## Implementation Pattern

```dart
// Extension types for non-standard JS APIs
extension type _BeforeInstallPromptEventJS._(JSObject _) implements JSObject {
  external void prompt();
  external JSPromise<_UserChoiceResult> get userChoice;
}

// Dart wrapper with proper Future handling
class BeforeInstallPromptEvent {
  factory BeforeInstallPromptEvent.fromEvent(html.Event event) {
    final jsObject = (event as dynamic) as JSObject;
    return BeforeInstallPromptEvent._(_BeforeInstallPromptEventJS._(jsObject));
  }

  Future<InstallPromptResult> getUserChoice() async {
    final result = await _jsEvent.userChoice.toDart;
    return InstallPromptResult(outcome: result.outcome, platform: result.platform);
  }
}
```

## SDK Requirements

- **Dart SDK:** `>=3.3.0` (extension types require 3.3+)
- **Flutter:** `>=3.19.0`

## Files Affected

| File | dart:html | dart:js_interop |
|------|-----------|-----------------|
| `browser_detector.dart` | ✓ | ✓ |
| `storage_manager.dart` | ✓ | - |
| `manifest_validator.dart` | ✓ | - |

## Deprecation Warnings

`dart:html` deprecation warnings are **intentional and expected**. Suppress in analysis_options.yaml if desired:

```yaml
analyzer:
  errors:
    deprecated_member_use: ignore
```

## Future Migration

When `package:web` adds `BeforeInstallPromptEvent` support (or a community package provides it), this package can migrate fully. Track:
- https://github.com/nickmeinhold/pwa_install
- https://github.com/nickmeinhold/pwa_utils

## Consequences

**Positive:**
- Working PWA install prompts on Chromium browsers
- Type-safe JS interop with proper Future handling
- No runtime cast errors

**Negative:**
- dart:html deprecation warnings in analyzer output
- Slight increase in complexity with dual-library approach
