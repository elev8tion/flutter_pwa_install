# Flutter PWA Install

Modern PWA installation package for Flutter web apps with iOS support, manifest validation, and smart install prompts.

[![pub package](https://img.shields.io/pub/v/flutter_pwa_install.svg)](https://pub.dev/packages/flutter_pwa_install)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Features

✅ **Universal Browser Support** - Chrome, Edge, Safari (iOS & macOS), Samsung Internet, Opera
✅ **iOS Support** - Beautiful Material dialog with Add to Home Screen instructions
✅ **Manifest Validation** - Built-in checks for PWA installability requirements
✅ **Smart Timing** - Respects user dismissals with configurable cooldown periods
✅ **Visit Tracking** - Track user visits to show prompt at the right time
✅ **Analytics Ready** - Event callbacks for install funnel tracking
✅ **Type Safe** - Full Dart type safety with null safety support
✅ **Zero Dependencies** - Pure Dart/Flutter implementation

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_pwa_install: ^1.0.0
```

Run:
```bash
flutter pub get
```

## Quick Start

### 1. Setup

Initialize the package in your `main()` function:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_pwa_install/flutter_pwa_install.dart';

void main() {
  // Initialize PWA Install
  FlutterPWAInstall.instance.setup(
    config: PWAConfig(
      debug: true,
      enableAnalytics: true,
      analyticsCallback: (event) {
        print('PWA Event: ${event.type.displayName}');
      },
    ),
  );

  runApp(const MyApp());
}
```

### 2. Show Install Button

Create a widget that shows the install button only when available:

```dart
class InstallButton extends StatefulWidget {
  const InstallButton({super.key});

  @override
  State<InstallButton> createState() => _InstallButtonState();
}

class _InstallButtonState extends State<InstallButton> {
  final pwa = FlutterPWAInstall.instance;
  bool _canInstall = false;

  @override
  void initState() {
    super.initState();
    _checkCanInstall();
  }

  Future<void> _checkCanInstall() async {
    final canInstall = await pwa.canInstall();
    setState(() => _canInstall = canInstall);
  }

  Future<void> _install() async {
    final result = await pwa.promptInstall(
      options: PromptOptions(
        onAccepted: () => print('User installed the app!'),
        onDismissed: () => print('User dismissed the prompt'),
      ),
    );

    if (result.wasAccepted) {
      setState(() => _canInstall = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canInstall) return const SizedBox.shrink();

    return ElevatedButton.icon(
      onPressed: _install,
      icon: const Icon(Icons.download),
      label: const Text('Install App'),
    );
  }
}
```

### 3. Use in Your App

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('My PWA App')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Welcome to my PWA!'),
              const SizedBox(height: 20),
              const InstallButton(),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Configuration

### PWAConfig Options

```dart
FlutterPWAInstall.instance.setup(
  config: PWAConfig(
    // Delay before showing prompt
    delayPrompt: Duration(seconds: 3),

    // Max dismissals before hiding forever
    maxDismissals: 3,

    // Cooldown period after dismissal
    dismissCooldown: Duration(days: 7),

    // Show iOS instructions
    showIOSInstructions: true,

    // Custom iOS text
    iosInstructionText: 'Install for the best experience!',

    // Enable analytics
    enableAnalytics: true,
    analyticsCallback: (event) {
      // Send to your analytics service
      analytics.logEvent(
        name: event.type.name,
        parameters: event.metadata,
      );
    },

    // localStorage prefix
    storagePrefix: 'my_app_pwa_',

    // Debug mode
    debug: true,
  ),
);
```

## API Reference

### FlutterPWAInstall

Main singleton class for PWA installation.

```dart
// Get instance
final pwa = FlutterPWAInstall.instance;

// Initialize
pwa.setup(config: PWAConfig());

// Show install prompt
final result = await pwa.promptInstall();

// Check if can install
final canInstall = await pwa.canInstall();

// Get browser capabilities
final caps = pwa.getCapabilities();

// Validate PWA requirements
final checks = await pwa.checkInstallability();

// Get installability report
final report = await pwa.getInstallabilityReport();

// Check if installed
final installed = pwa.isStandalone;

// Get display mode
final mode = pwa.displayMode;

// Get visit count
final visits = pwa.visitCount;

// Clear stored data
pwa.clearData();
```

### PromptOptions

Customize prompt behavior:

```dart
await pwa.promptInstall(
  options: PromptOptions(
    onBeforeShow: () async {
      // Return false to cancel
      return true;
    },
    onAccepted: () {
      print('User installed!');
    },
    onDismissed: () {
      print('User dismissed');
    },
    onError: (error) {
      print('Error: $error');
    },
  ),
);
```

### InstallResult

Result of installation attempt:

```dart
final result = await pwa.promptInstall();

// Check outcome
if (result.wasAccepted) {
  print('Installed on ${result.platform}');
} else if (result.wasDismissed) {
  print('User dismissed');
} else if (result.wasUnsupported) {
  print('Browser does not support installation');
} else if (result.hadError) {
  print('Error: ${result.error}');
}
```

### BrowserCapabilities

Information about browser and platform:

```dart
final caps = pwa.getCapabilities();

print('Platform: ${caps.platform.displayName}');
print('Browser: ${caps.browser.displayName}');
print('Display Mode: ${caps.displayMode.displayName}');
print('Install Method: ${caps.installMethod.displayName}');
print('Standalone: ${caps.isStandalone}');

// Helper methods
if (caps.isIOSSafari) {
  print('Running on iOS Safari');
}

if (caps.canShowNativePrompt) {
  print('Can show native prompt');
}
```

### InstallabilityChecks

Validation results:

```dart
final checks = await pwa.checkInstallability();

print('Has Manifest: ${checks.hasManifest}');
print('Has Service Worker: ${checks.hasServiceWorker}');
print('HTTPS: ${checks.isHttps}');
print('Valid Icons: ${checks.hasValidIcons}');
print('Has Name: ${checks.hasName}');

if (!checks.meetsMinimumRequirements) {
  print('Errors: ${checks.errors}');
  print('Warnings: ${checks.warnings}');
}

// Get formatted report
print(checks.getReport());
```

## PWA Requirements

Your Flutter web app must meet these requirements:

### Required ✅
- Served over HTTPS (or localhost)
- Valid `manifest.json` file
- Registered Service Worker
- At least one icon >= 192x192px
- App name in manifest

### Recommended ⚡
- `start_url` in manifest
- `display: "standalone"` in manifest
- `theme_color` in manifest
- Screenshots in manifest

### Example manifest.json

Place in `web/manifest.json`:

```json
{
  "name": "My Flutter PWA",
  "short_name": "MyPWA",
  "description": "An amazing Flutter progressive web app",
  "start_url": "/",
  "display": "standalone",
  "theme_color": "#2196F3",
  "background_color": "#FFFFFF",
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ]
}
```

Link it in `web/index.html`:

```html
<link rel="manifest" href="manifest.json">
```

## Service Worker

Register a service worker in `web/index.html`:

```html
<script>
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('flutter_service_worker.js');
    });
  }
</script>
```

Flutter automatically generates `flutter_service_worker.js` when you build for web.

## Browser Support

| Browser | Install Method | Support |
|---------|---------------|---------|
| Chrome (Android) | Native prompt | ✅ Full |
| Chrome (Desktop) | Native prompt | ✅ Full |
| Edge | Native prompt | ✅ Full |
| Safari (iOS) | Custom dialog | ✅ Full |
| Safari (macOS) | Native button | ✅ Full |
| Samsung Internet | Native prompt | ✅ Full |
| Opera | Native prompt | ✅ Full |
| Firefox | - | ⚠️ Limited |

## Analytics Events

Track installation funnel:

```dart
FlutterPWAInstall.instance.setup(
  config: PWAConfig(
    enableAnalytics: true,
    analyticsCallback: (event) {
      switch (event.type) {
        case PWAEventType.promptShown:
          // User saw the install prompt
          break;
        case PWAEventType.installAccepted:
          // User accepted installation
          break;
        case PWAEventType.installDismissed:
          // User dismissed prompt
          break;
        case PWAEventType.appInstalled:
          // App was installed
          break;
        case PWAEventType.appLaunched:
          // App launched in standalone mode
          break;
      }
    },
  ),
);
```

## Testing

### Development

```bash
flutter run -d chrome --web-port=8080
```

### Validation

```dart
// Check installability in your app
final report = await FlutterPWAInstall.instance.getInstallabilityReport();
debugPrint(report);
```

Expected output:
```
=== PWA Installability Report ===

✅ Your PWA meets minimum installability requirements!

Checks:
  ✅ HTTPS (or localhost)
  ✅ Web App Manifest
  ✅ Service Worker
  ✅ Valid Icons (>= 192x192)
  ✅ App Name
  ✅ Start URL
  ✅ Display Mode
```

## Common Issues

### Install button doesn't appear
1. Check HTTPS (or localhost)
2. Verify manifest is linked in index.html
3. Ensure service worker is registered
4. Run validation: `await pwa.getInstallabilityReport()`

### iOS doesn't show dialog
- Ensure `showIOSInstructions: true` in config
- Check platform detection: `pwa.getCapabilities().isIOSSafari`
- iOS requires manual Add to Home Screen

### Prompt only shows once
- This is normal browser behavior
- Use `pwa.clearData()` to reset for testing
- In production, respect user dismissals

## Example App

See the [example](example/) directory for a complete working app.

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

## License

MIT License - see [LICENSE](LICENSE) file.

## Support

- 📖 [Documentation](https://pub.dev/documentation/flutter_pwa_install/latest/)
- 🐛 [Issue Tracker](https://github.com/yourusername/flutter_pwa_install/issues)
- 💬 [Discussions](https://github.com/yourusername/flutter_pwa_install/discussions)

---

Made with ❤️ for the Flutter community
