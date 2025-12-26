import 'package:flutter/material.dart';

/// Device type for responsive layouts
enum PWADeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// A responsive scaffold that adapts layout based on screen size
///
/// This scaffold provides device-aware layouts, allowing you to specify
/// different widgets for mobile, tablet, and desktop while keeping
/// mobile layout unchanged.
///
/// Example:
/// ```dart
/// PWAResponsiveScaffold(
///   mobile: MobileLayout(),
///   tablet: TabletLayout(),
///   desktop: DesktopLayout(),
/// )
/// ```
class PWAResponsiveScaffold extends StatelessWidget {
  /// The widget to display on mobile devices (< 600px)
  final Widget mobile;

  /// The widget to display on tablet devices (600-900px)
  /// Falls back to [mobile] if not provided
  final Widget? tablet;

  /// The widget to display on desktop devices (900-1200px)
  /// Falls back to [tablet] or [mobile] if not provided
  final Widget? desktop;

  /// The widget to display on large desktop devices (> 1200px)
  /// Falls back to [desktop], [tablet], or [mobile] if not provided
  final Widget? largeDesktop;

  /// Custom breakpoint for mobile -> tablet transition (default: 600)
  final double mobileBreakpoint;

  /// Custom breakpoint for tablet -> desktop transition (default: 900)
  final double tabletBreakpoint;

  /// Custom breakpoint for desktop -> large desktop transition (default: 1200)
  final double desktopBreakpoint;

  /// Optional background color
  final Color? backgroundColor;

  /// Optional maximum width constraint
  final double? maxWidth;

  /// Enable debug logging
  final bool debug;

  const PWAResponsiveScaffold({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
    this.mobileBreakpoint = 600,
    this.tabletBreakpoint = 900,
    this.desktopBreakpoint = 1200,
    this.backgroundColor,
    this.maxWidth,
    this.debug = false,
  });

  /// Get the current device type based on screen width
  PWADeviceType getDeviceType(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return PWADeviceType.mobile;
    } else if (screenWidth < tabletBreakpoint) {
      return PWADeviceType.tablet;
    } else if (screenWidth < desktopBreakpoint) {
      return PWADeviceType.desktop;
    } else {
      return PWADeviceType.largeDesktop;
    }
  }

  /// Get the appropriate widget for the current device type
  Widget getWidgetForDevice(PWADeviceType deviceType) {
    switch (deviceType) {
      case PWADeviceType.mobile:
        return mobile;
      case PWADeviceType.tablet:
        return tablet ?? mobile;
      case PWADeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case PWADeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final deviceType = getDeviceType(screenWidth);

        if (debug) {
          debugPrint(
              '[PWAResponsiveScaffold] Width: $screenWidth, Device: $deviceType');
        }

        Widget content = getWidgetForDevice(deviceType);

        // Apply max width constraint if specified
        if (maxWidth != null && screenWidth > maxWidth!) {
          content = Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth!),
              child: content,
            ),
          );
        }

        // Apply background color if specified
        if (backgroundColor != null) {
          content = ColoredBox(
            color: backgroundColor!,
            child: content,
          );
        }

        return content;
      },
    );
  }

  /// Static helper to check device type from context
  static PWADeviceType deviceTypeOf(
    BuildContext context, {
    double mobileBreakpoint = 600,
    double tabletBreakpoint = 900,
    double desktopBreakpoint = 1200,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return PWADeviceType.mobile;
    if (width < tabletBreakpoint) return PWADeviceType.tablet;
    if (width < desktopBreakpoint) return PWADeviceType.desktop;
    return PWADeviceType.largeDesktop;
  }

  /// Static helper to check if device is mobile
  static bool isMobile(BuildContext context, {double breakpoint = 600}) {
    return MediaQuery.of(context).size.width < breakpoint;
  }

  /// Static helper to check if device is tablet
  static bool isTablet(
    BuildContext context, {
    double mobileBreakpoint = 600,
    double tabletBreakpoint = 900,
  }) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Static helper to check if device is desktop
  static bool isDesktop(BuildContext context, {double breakpoint = 900}) {
    return MediaQuery.of(context).size.width >= breakpoint;
  }

  /// Static helper to get value based on device type
  static T valueByDevice<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
    double mobileBreakpoint = 600,
    double tabletBreakpoint = 900,
    double desktopBreakpoint = 1200,
  }) {
    final deviceType = deviceTypeOf(
      context,
      mobileBreakpoint: mobileBreakpoint,
      tabletBreakpoint: tabletBreakpoint,
      desktopBreakpoint: desktopBreakpoint,
    );

    switch (deviceType) {
      case PWADeviceType.mobile:
        return mobile;
      case PWADeviceType.tablet:
        return tablet ?? mobile;
      case PWADeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case PWADeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
}

/// Extension methods for BuildContext to easily access responsive helpers
extension PWAResponsiveContext on BuildContext {
  /// Get the current device type
  PWADeviceType get pwaDeviceType => PWAResponsiveScaffold.deviceTypeOf(this);

  /// Check if current device is mobile
  bool get pwaIsMobile => PWAResponsiveScaffold.isMobile(this);

  /// Check if current device is tablet
  bool get pwaIsTablet => PWAResponsiveScaffold.isTablet(this);

  /// Check if current device is desktop or larger
  bool get pwaIsDesktop => PWAResponsiveScaffold.isDesktop(this);

  /// Get current screen width
  double get pwaScreenWidth => MediaQuery.of(this).size.width;

  /// Get current screen height
  double get pwaScreenHeight => MediaQuery.of(this).size.height;
}
