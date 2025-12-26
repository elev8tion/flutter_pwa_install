# Responsive Design Feature

The Flutter PWA Install package includes **optional responsive design features** that help you build adaptive layouts for mobile, tablet, and desktop screens.

## Features

✅ **Breakpoint System** - Define custom screen size breakpoints
✅ **Conditional Values** - Use different values based on active breakpoint
✅ **Max Width Container** - Limit content width on large screens
✅ **Responsive Visibility** - Show/hide widgets based on screen size
✅ **Landscape Support** - Different breakpoints for landscape orientation
✅ **Platform Aware** - Built-in platform detection (iOS, Android, Web, etc.)

## Quick Start

### 1. Wrap your app with PWAResponsiveBreakpoints

```dart
import 'package:flutter/material.dart';
import 'package:flutter_pwa_install/flutter_pwa_install.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => PWAResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const PWABreakpoint(start: 0, end: 450, name: PWA_MOBILE),
          const PWABreakpoint(start: 451, end: 800, name: PWA_TABLET),
          const PWABreakpoint(start: 801, end: 1920, name: PWA_DESKTOP),
          const PWABreakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
      home: const HomePage(),
    );
  }
}
```

### 2. Use responsive conditionals

```dart
import 'package:flutter/material.dart';
import 'package:flutter_pwa_install/flutter_pwa_install.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = PWAResponsiveBreakpoints.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My PWA'),
        actions: [
          // Show full menu on desktop, icon only on mobile
          if (responsive.largerThan(PWA_MOBILE))
            const TextButton(child: Text('Features'), onPressed: null)
          else
            const IconButton(icon: Icon(Icons.menu), onPressed: null),
        ],
      ),
      body: PWAMaxWidthBox(
        maxWidth: 1200,
        child: Column(
          children: [
            // Different layout based on screen size
            if (responsive.isDesktop)
              const DesktopLayout()
            else if (responsive.isTablet)
              const TabletLayout()
            else
              const MobileLayout(),
          ],
        ),
      ),
    );
  }
}
```

## API Reference

### PWAResponsiveBreakpoints

Main widget that provides responsive capabilities to child widgets.

```dart
PWAResponsiveBreakpoints.builder({
  required Widget child,
  required List<PWABreakpoint> breakpoints,
  List<PWABreakpoint>? breakpointsLandscape,  // Different breakpoints for landscape
  List<PWATargetPlatform>? landscapePlatforms,
  bool useShortestSide = false,
  bool debugLog = false,                       // Print breakpoints to console
})
```

### PWABreakpoint

Defines a screen size range.

```dart
const PWABreakpoint({
  required double start,     // Start width in pixels (inclusive)
  required double end,       // End width in pixels (inclusive)
  String? name,              // Optional name for this breakpoint
  dynamic data,              // Custom data
})
```

### PWAResponsiveBreakpointsData

Access responsive data using `PWAResponsiveBreakpoints.of(context)`.

```dart
final responsive = PWAResponsiveBreakpoints.of(context);

// Screen dimensions
responsive.screenWidth;
responsive.screenHeight;
responsive.orientation;  // Orientation.landscape or Orientation.portrait

// Breakpoint checks
responsive.isMobile;     // Is current breakpoint named PWA_MOBILE?
responsive.isTablet;     // Is current breakpoint named PWA_TABLET?
responsive.isDesktop;    // Is current breakpoint named PWA_DESKTOP?
responsive.isPhone;      // Is current breakpoint named PWA_PHONE?

// Comparison methods
responsive.equals('CUSTOM_BREAKPOINT');
responsive.largerThan(PWA_MOBILE);
responsive.largerOrEqualTo(PWA_TABLET);
responsive.smallerThan(PWA_DESKTOP);
responsive.smallerOrEqualTo(PWA_TABLET);
responsive.between(PWA_MOBILE, PWA_TABLET);
```

### PWAMaxWidthBox

Limits the maximum width of content, useful for centering layouts on large screens.

```dart
PWAMaxWidthBox(
  maxWidth: 1200,
  backgroundColor: Colors.grey[100],
  padding: const EdgeInsets.all(16),
  alignment: Alignment.topCenter,  // Default
  child: YourContent(),
)
```

### PWAResponsiveValue

Get different values based on active breakpoint.

```dart
final padding = PWAResponsiveValue<double>(
  context,
  conditionalValues: [
    const PWACondition.equals(name: PWA_MOBILE, value: 8.0),
    const PWACondition.equals(name: PWA_TABLET, value: 16.0),
    const PWACondition.equals(name: PWA_DESKTOP, value: 24.0),
  ],
  defaultValue: 16.0,
).value;
```

### PWACondition

Define conditional values for different breakpoints.

```dart
// Equal to named breakpoint
PWACondition.equals(name: PWA_MOBILE, value: 8.0)

// Larger than breakpoint
PWACondition.largerThan(breakpoint: 800, value: 24.0)
PWACondition.largerThan(name: PWA_TABLET, value: 24.0)

// Smaller than breakpoint
PWACondition.smallerThan(breakpoint: 600, value: 8.0)
PWACondition.smallerThan(name: PWA_TABLET, value: 8.0)

// Between two breakpoints
PWACondition.between(start: 600, end: 1200, value: 16.0)

// Landscape override
PWACondition.equals(
  name: PWA_MOBILE,
  value: 8.0,
  landscapeValue: 12.0,  // Use this value in landscape mode
)
```

### PWAResponsiveVisibility

Show or hide widgets based on screen size.

```dart
PWAResponsiveVisibility(
  visible: true,  // Default visibility
  visibleConditions: [
    const PWACondition.equals(name: PWA_DESKTOP, value: true),
  ],
  hiddenConditions: [
    const PWACondition.equals(name: PWA_MOBILE, value: true),
  ],
  child: const DesktopOnlyWidget(),
)
```

### PWAResponsiveConstraints

Apply different constraints based on screen size.

```dart
PWAResponsiveConstraints(
  constraint: const BoxConstraints(maxWidth: 600),
  conditionalConstraints: [
    const PWACondition.equals(
      name: PWA_MOBILE,
      value: BoxConstraints(maxWidth: 400),
    ),
    const PWACondition.equals(
      name: PWA_DESKTOP,
      value: BoxConstraints(maxWidth: 1200),
    ),
  ],
  child: YourWidget(),
)
```

## Predefined Breakpoint Names

```dart
const String PWA_MOBILE = 'MOBILE';
const String PWA_TABLET = 'TABLET';
const String PWA_PHONE = 'PHONE';
const String PWA_DESKTOP = 'DESKTOP';
```

You can use these or create your own custom breakpoint names.

## Common Patterns

### Responsive Padding

```dart
Container(
  padding: EdgeInsets.all(
    PWAResponsiveValue<double>(
      context,
      conditionalValues: [
        const PWACondition.smallerThan(name: PWA_TABLET, value: 8.0),
        const PWACondition.between(start: 800, end: 1200, value: 16.0),
        const PWACondition.largerThan(name: PWA_DESKTOP, value: 24.0),
      ],
      defaultValue: 12.0,
    ).value,
  ),
  child: YourContent(),
)
```

### Responsive Grid Columns

```dart
GridView.count(
  crossAxisCount: PWAResponsiveValue<int>(
    context,
    conditionalValues: [
      const PWACondition.equals(name: PWA_MOBILE, value: 1),
      const PWACondition.equals(name: PWA_TABLET, value: 2),
      const PWACondition.equals(name: PWA_DESKTOP, value: 3),
    ],
    defaultValue: 2,
  ).value,
  children: items,
)
```

### Responsive Font Size

```dart
Text(
  'Hello PWA',
  style: TextStyle(
    fontSize: PWAResponsiveValue<double>(
      context,
      conditionalValues: [
        const PWACondition.smallerThan(breakpoint: 600, value: 14.0),
        const PWACondition.between(start: 600, end: 1200, value: 16.0),
        const PWACondition.largerThan(breakpoint: 1200, value: 18.0),
      ],
      defaultValue: 16.0,
    ).value,
  ),
)
```

### Conditional Widget Tree

```dart
final responsive = PWAResponsiveBreakpoints.of(context);

Widget buildLayout() {
  if (responsive.isDesktop) {
    return Row(
      children: [
        const Sidebar(),
        const Expanded(child: MainContent()),
      ],
    );
  } else {
    return Column(
      children: [
        const MobileHeader(),
        const Expanded(child: MainContent()),
      ],
    );
  }
}
```

### Landscape-Specific Breakpoints

```dart
MaterialApp(
  builder: (context, child) => PWAResponsiveBreakpoints.builder(
    child: child!,
    // Portrait breakpoints
    breakpoints: [
      const PWABreakpoint(start: 0, end: 600, name: PWA_MOBILE),
      const PWABreakpoint(start: 601, end: 1200, name: PWA_DESKTOP),
    ],
    // Landscape breakpoints (optional)
    breakpointsLandscape: [
      const PWABreakpoint(start: 0, end: 800, name: PWA_MOBILE),
      const PWABreakpoint(start: 801, end: 1600, name: PWA_DESKTOP),
    ],
  ),
)
```

## Debugging

Enable debug logging to see breakpoint visualization in console:

```dart
PWAResponsiveBreakpoints.builder(
  child: child!,
  debugLog: true,  // Prints breakpoint ranges to console
  breakpoints: [...],
)
```

Output example:
```
| 0 ----- (MOBILE) ----- 450 ----- 451 ----- (TABLET) ----- 800 ----- 801 ----- (DESKTOP) ----- 1920 ----- 1921 ----- (4K) ----- ∞ |
```

## Integration with PWA Install

Combine responsive design with PWA installation features:

```dart
class InstallButton extends StatelessWidget {
  const InstallButton({super.key});

  @override
  Widget build(BuildContext context) {
    final pwa = FlutterPWAInstall.instance;
    final responsive = PWAResponsiveBreakpoints.of(context);

    return FutureBuilder<bool>(
      future: pwa.canInstall(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return const SizedBox.shrink();
        }

        // Full button on desktop, icon only on mobile
        if (responsive.largerThan(PWA_MOBILE)) {
          return ElevatedButton.icon(
            onPressed: () => pwa.promptInstall(),
            icon: const Icon(Icons.download),
            label: const Text('Install App'),
          );
        } else {
          return IconButton(
            onPressed: () => pwa.promptInstall(),
            icon: const Icon(Icons.download),
            tooltip: 'Install App',
          );
        }
      },
    );
  }
}
```

## Best Practices

1. **Define breakpoints at app level** - Wrap MaterialApp/CupertinoApp with PWAResponsiveBreakpoints.builder()

2. **Use named breakpoints** - Creates more readable code than numeric values

3. **Limit max width on large screens** - Use PWAMaxWidthBox to prevent content from stretching too wide

4. **Test all breakpoints** - Resize your browser window to test different screen sizes

5. **Consider landscape** - Use breakpointsLandscape for devices that rotate

6. **Cache responsive values** - Store PWAResponsiveBreakpoints.of(context) in a variable if used multiple times

7. **Avoid excessive nesting** - Use helper methods to build different layouts

## Platform Support

- ✅ Web (all desktop and mobile browsers)
- ✅ Android
- ✅ iOS
- ✅ macOS
- ✅ Windows
- ✅ Linux

## License

This responsive feature is part of the Flutter PWA Install package and uses the same MIT license.

---

**Note**: This responsive framework has been fully sanitized and rebranded as an optional feature of the Flutter PWA Install package. All original author information, links, and branding have been removed and replaced with PWA-specific naming conventions.
