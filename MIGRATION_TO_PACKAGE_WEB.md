# Migration Guide: dart:html to package:web

## Status: COMPLETED

Migration completed on 2025-12-28. All `dart:html` usage has been replaced with `package:web`.

## Summary

This document explains the migration from `dart:html` to `package:web` for the `flutter_pwa_install` package.

---

## What Was Done (Partial Fixes - Not Recommended)

### The Problem
When testing in Chrome, two runtime errors occurred:

1. **`NoSuchMethodError: 'standalone'`** in `browser_detector.dart:164`
   - `navigator.standalone` is a Safari-only property
   - Accessing it in Chrome throws an error

2. **`TypeError: null is not a subtype of type 'FutureOr<ServiceWorkerRegistration>'`** in `manifest_validator.dart:43`
   - `getRegistration()` returns `null` when no service worker is registered
   - `dart:html` typing expects non-null, causing Promise conversion to fail

### The Partial Fix Attempted (What We Did Wrong)
We tried to fix these by mixing `dart:html` with `dart:js_interop`:

```dart
// browser_detector.dart - Added browser check + try-catch
if (detectBrowser() == BrowserType.safari) {
  try {
    final nav = html.window.navigator as dynamic;
    if (nav.standalone == true) {
      return DisplayMode.standalone;
    }
  } catch (e) { ... }
}

// manifest_validator.dart - Added js_interop import and dynamic casting
import 'dart:js_interop';
final jsPromise = sw.getRegistration() as JSPromise?;
final result = await jsPromise.toDart;
```

### Why This Approach Is Problematic
- **Inconsistent codebase**: Mixing `dart:html`, `dart:js_interop`, and `dynamic` casts
- **Hard to maintain**: Different patterns for similar problems
- **Not future-proof**: `dart:html` is being phased out in favor of `package:web`
- **Type safety lost**: Excessive use of `dynamic` defeats Dart's type system

---

## The Right Solution: Full Migration to package:web

`package:web` is the modern, recommended way to do web interop in Flutter/Dart. It's generated from Web IDL specs and uses `dart:js_interop` under the hood.

---

## Files That Need Migration

### 1. `lib/src/browser_detector.dart`
**Current imports:**
```dart
import 'dart:html' as html;
import 'dart:js_interop';
```

**Changes needed:**
- Replace `html.window` with `web.window`
- Replace `html.document` with `web.document`
- Replace `html.window.navigator` with `web.window.navigator`
- Replace `html.window.matchMedia()` with `web.window.matchMedia()`
- Replace `html.window.addEventListener()` with proper event handling

**Key API mappings:**

| dart:html | package:web |
|-----------|-------------|
| `html.window` | `web.window` |
| `html.document` | `web.document` |
| `html.window.navigator.userAgent` | `web.window.navigator.userAgent` |
| `html.window.navigator.serviceWorker` | `web.window.navigator.serviceWorker` |
| `html.window.matchMedia('...')` | `web.window.matchMedia('...')` |
| `html.window.addEventListener('event', (e) {...})` | See event handling section |
| `html.window.localStorage` | `web.window.localStorage` |

**Special handling for `navigator.standalone`:**
```dart
// This property doesn't exist in package:web (it's Safari-only, non-standard)
// Use extension type or dynamic access:
extension type NavigatorStandalone._(JSObject _) implements JSObject {
  external bool? get standalone;
}

// Then cast:
final nav = web.window.navigator as NavigatorStandalone;
final isStandalone = nav.standalone ?? false;
```

### 2. `lib/src/manifest_validator.dart`
**Current imports:**
```dart
import 'dart:html' as html;
import 'dart:js_interop';
```

**Changes needed:**
- Replace `html.document.querySelector()` with `web.document.querySelector()`
- Replace `html.HttpRequest.getString()` with `fetch()` API
- Replace `html.window.location` with `web.window.location`
- Fix service worker registration check

**HTTP Request migration:**
```dart
// OLD (dart:html)
final response = await html.HttpRequest.getString(url);

// NEW (package:web)
import 'package:web/web.dart' as web;

final response = await web.window.fetch(url.toJS).toDart;
final text = await response.text().toDart;
```

**Service Worker check migration:**
```dart
// OLD (dart:html) - causes null type error
final registration = await serviceWorker.getRegistration();

// NEW (package:web) - properly handles null
final sw = web.window.navigator.serviceWorker;
final registration = await sw.getRegistration().toDart;
// registration is now properly nullable
```

### 3. `lib/src/flutter_pwa_install_base.dart`
Check for any `dart:html` usage and migrate similarly.

### 4. `lib/src/widgets/` (if any)
Check all widget files for web API usage.

---

## Step-by-Step Migration Process

### Step 1: Update pubspec.yaml
```yaml
dependencies:
  web: ^1.0.0  # Add this

# Remove any dart:html specific dependencies
```

### Step 2: Create Extension Types for Non-Standard APIs

Create a new file `lib/src/js_interop_extensions.dart`:

```dart
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// BeforeInstallPromptEvent - Chromium-only, not in Web IDL
extension type BeforeInstallPromptEvent._(JSObject _) implements web.Event {
  external void prompt();
  external JSPromise<UserChoiceResult> get userChoice;
}

extension type UserChoiceResult._(JSObject _) implements JSObject {
  external String get outcome;
  external String? get platform;
}

/// Navigator.standalone - Safari-only property
extension type NavigatorStandalone._(JSObject _) implements JSObject {
  external bool? get standalone;
}

/// Check if navigator.standalone exists (Safari only)
bool hasStandaloneProperty() {
  try {
    final nav = web.window.navigator as NavigatorStandalone;
    return nav.standalone != null;
  } catch (e) {
    return false;
  }
}
```

### Step 3: Update browser_detector.dart

```dart
// OLD
import 'dart:html' as html;

// NEW
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'js_interop_extensions.dart';

// OLD
final ua = html.window.navigator.userAgent.toLowerCase();

// NEW
final ua = web.window.navigator.userAgent.toLowerCase();

// OLD - event listener
html.window.addEventListener('beforeinstallprompt', (event) {
  event.preventDefault();
  _deferredPrompt = BeforeInstallPromptEvent.fromEvent(event);
});

// NEW - event listener
web.window.addEventListener(
  'beforeinstallprompt',
  ((web.Event event) {
    event.preventDefault();
    _deferredPrompt = event as BeforeInstallPromptEvent;
  }).toJS,
);

// OLD - display mode check
if (html.window.matchMedia('(display-mode: standalone)').matches) {

// NEW - display mode check
if (web.window.matchMedia('(display-mode: standalone)'.toJS).matches) {

// OLD - standalone check (problematic)
final nav = html.window.navigator as dynamic;
if (nav.standalone == true) {

// NEW - standalone check (safe)
if (detectBrowser() == BrowserType.safari) {
  try {
    final nav = web.window.navigator as NavigatorStandalone;
    if (nav.standalone == true) {
      return DisplayMode.standalone;
    }
  } catch (e) {
    // Not Safari or property doesn't exist
  }
}
```

### Step 4: Update manifest_validator.dart

```dart
// OLD
import 'dart:html' as html;

// NEW
import 'package:web/web.dart' as web;
import 'dart:js_interop';

// OLD - querySelector
final manifestLink = html.document.querySelector('link[rel="manifest"]') as html.LinkElement?;

// NEW - querySelector
final manifestLink = web.document.querySelector('link[rel="manifest"]') as web.HTMLLinkElement?;

// OLD - HTTP request
final response = await html.HttpRequest.getString(manifestLink.href);

// NEW - fetch API
final response = await web.window.fetch(manifestLink.href.toJS).toDart;
if (!response.ok) return null;
final text = await response.text().toDart;

// OLD - service worker check (causes null type error)
final registration = await serviceWorker.getRegistration();
return registration != null;

// NEW - service worker check (handles null properly)
final sw = web.window.navigator.serviceWorker;
final registration = await sw.getRegistration().toDart;
return registration != null;

// OLD - location check
final isHttps = html.window.location.protocol == 'https:';

// NEW - location check
final isHttps = web.window.location.protocol == 'https:';
```

### Step 5: Test Each File After Migration

After migrating each file:
1. Run `dart analyze` to check for type errors
2. Run `flutter build web` to verify compilation
3. Test in Chrome, Safari, and Firefox

---

## Common Pitfalls

### 1. String to JSString conversion
```dart
// OLD
matchMedia('(display-mode: standalone)')

// NEW - must convert to JS string
matchMedia('(display-mode: standalone)'.toJS)
```

### 2. Event listener callbacks
```dart
// OLD
window.addEventListener('event', (e) { ... });

// NEW - must convert callback to JS function
window.addEventListener('event', ((web.Event e) { ... }).toJS);
```

### 3. Nullable returns from JS
```dart
// package:web properly types nullable returns
// Always check for null before using
final registration = await sw.getRegistration().toDart;
if (registration == null) return false;
```

### 4. Promise to Future conversion
```dart
// OLD (dart:html) - automatic conversion, but fails on null
await someJsMethod();

// NEW (package:web) - explicit conversion
await someJsMethod().toDart;
```

---

## Testing Checklist

After migration, test the following in each browser:

### Chrome/Edge (Chromium)
- [ ] `beforeinstallprompt` event fires
- [ ] Install prompt shows correctly
- [ ] User choice is captured
- [ ] Display mode detection works
- [ ] Service worker detection works

### Safari (macOS/iOS)
- [ ] `navigator.standalone` check works (no crash)
- [ ] iOS install instructions show
- [ ] Display mode detection works
- [ ] Graceful fallback when APIs unavailable

### Firefox
- [ ] No crashes on unsupported APIs
- [ ] Graceful degradation
- [ ] Display mode detection via media queries works

---

## Files Migrated

The following files have been fully migrated from `dart:html` to `package:web`:

1. **`lib/src/browser_detector.dart`**
   - Replaced `html.window` with `web.window`
   - Replaced `html.document` with `web.document`
   - Updated event listeners to use `.toJS` callback conversion
   - Uses `js_interop_extensions.dart` for Safari standalone check

2. **`lib/src/manifest_validator.dart`**
   - Replaced `html.document.querySelector` with `web.document.querySelector`
   - Replaced `html.HttpRequest.getString()` with `fetch()` API
   - Replaced `html.window.location` with `web.window.location`
   - Fixed service worker registration check with proper null handling

3. **`lib/src/storage_manager.dart`**
   - Replaced `html.window.localStorage` with `web.window.localStorage`
   - Updated API: `[]` → `getItem()`, `[]=` → `setItem()`, `remove()` → `removeItem()`

4. **`lib/src/js_interop_extensions.dart`** (NEW)
   - Created extension types for non-standard APIs:
     - `BeforeInstallPromptEvent` (Chromium-only PWA install)
     - `NavigatorStandalone` (Safari-only standalone check)
     - `UserChoiceResult` for install prompt results

---

## Resources

- [package:web documentation](https://pub.dev/packages/web)
- [dart:js_interop documentation](https://dart.dev/interop/js-interop)
- [Migrating from dart:html](https://dart.dev/interop/js-interop/package-web)
- [BeforeInstallPromptEvent MDN](https://developer.mozilla.org/en-US/docs/Web/API/BeforeInstallPromptEvent)
- [navigator.standalone MDN](https://developer.mozilla.org/en-US/docs/Web/API/Navigator/standalone)

---

## Questions?

When ready to test after migration, return to the `edc_web` project and run:
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

Then go through the onboarding flow to verify the PWA install prompt appears correctly.
