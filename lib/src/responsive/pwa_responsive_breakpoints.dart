// ignore_for_file: constant_identifier_names

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'pwa_breakpoint.dart';
import 'pwa_responsive_utils.dart';

/// Makes child widgets responsive based on screen breakpoints
///
/// Wrap your MaterialApp or widget tree with PWAResponsiveBreakpoints
/// to enable responsive design capabilities throughout your PWA.
class PWAResponsiveBreakpoints extends StatefulWidget {
  final Widget child;
  final List<PWABreakpoint> breakpoints;
  final List<PWABreakpoint>? breakpointsLandscape;
  final List<PWATargetPlatform>? landscapePlatforms;
  final bool useShortestSide;
  final bool debugLog;

  const PWAResponsiveBreakpoints({
    super.key,
    required this.child,
    required this.breakpoints,
    this.breakpointsLandscape,
    this.landscapePlatforms,
    this.useShortestSide = false,
    this.debugLog = false,
  });

  @override
  PWAResponsiveBreakpointsState createState() =>
      PWAResponsiveBreakpointsState();

  static Widget builder({
    required Widget child,
    required List<PWABreakpoint> breakpoints,
    List<PWABreakpoint>? breakpointsLandscape,
    List<PWATargetPlatform>? landscapePlatforms,
    bool useShortestSide = false,
    bool debugLog = false,
  }) {
    return PWAResponsiveBreakpoints(
      breakpoints: breakpoints,
      breakpointsLandscape: breakpointsLandscape,
      landscapePlatforms: landscapePlatforms,
      useShortestSide: useShortestSide,
      debugLog: debugLog,
      child: child,
    );
  }

  static PWAResponsiveBreakpointsData of(BuildContext context) {
    final InheritedPWAResponsiveBreakpoints? data = context
        .dependOnInheritedWidgetOfExactType<InheritedPWAResponsiveBreakpoints>();
    if (data != null) return data.data;
    throw FlutterError.fromParts(
      <DiagnosticsNode>[
        ErrorSummary(
            'PWAResponsiveBreakpoints.of() called with a context that does not contain PWAResponsiveBreakpoints.'),
        ErrorDescription(
            'No responsive ancestor could be found starting from the context that was passed '
            'to PWAResponsiveBreakpoints.of(). Place a PWAResponsiveBreakpoints at the root of the app '
            'or supply a PWAResponsiveBreakpoints.builder.'),
        context.describeElement('The context used was')
      ],
    );
  }
}

class PWAResponsiveBreakpointsState extends State<PWAResponsiveBreakpoints>
    with WidgetsBindingObserver {
  double windowWidth = 0;
  double getWindowWidth() => MediaQuery.of(context).size.width;

  double windowHeight = 0;
  double getWindowHeight() => MediaQuery.of(context).size.height;

  PWABreakpoint breakpoint = const PWABreakpoint(start: 0, end: 0);
  List<PWABreakpoint> breakpoints = [];

  double screenWidth = 0;
  double getScreenWidth() {
    double widthCalc = useShortestSide
        ? (windowWidth < windowHeight ? windowWidth : windowHeight)
        : windowWidth;
    return widthCalc;
  }

  double screenHeight = 0;
  double getScreenHeight() {
    double heightCalc = useShortestSide
        ? (windowWidth < windowHeight ? windowHeight : windowWidth)
        : windowHeight;
    return heightCalc;
  }

  Orientation get orientation => (windowWidth > windowHeight)
      ? Orientation.landscape
      : Orientation.portrait;

  static const List<PWATargetPlatform> _landscapePlatforms = [
    PWATargetPlatform.iOS,
    PWATargetPlatform.android,
    PWATargetPlatform.fuchsia,
  ];

  PWATargetPlatform? platform;

  void setPlatform() {
    platform = kIsWeb
        ? PWATargetPlatform.web
        : Theme.of(context).platform.pwaTargetPlatform;
  }

  bool get isLandscapePlatform =>
      (widget.landscapePlatforms ?? _landscapePlatforms).contains(platform);

  bool get isLandscape =>
      orientation == Orientation.landscape && isLandscapePlatform;

  bool get useShortestSide => widget.useShortestSide;

  void setDimensions() {
    windowWidth = getWindowWidth();
    windowHeight = getWindowHeight();
    screenWidth = getScreenWidth();
    screenHeight = getScreenHeight();
    breakpoint = breakpoints.firstWhereOrNull((element) =>
            screenWidth >= element.start && screenWidth <= element.end) ??
        const PWABreakpoint(start: 0, end: 0);
  }

  List<PWABreakpoint> getActiveBreakpoints() {
    if (isLandscape) {
      return widget.breakpointsLandscape ?? widget.breakpoints;
    }
    return widget.breakpoints;
  }

  void setBreakpoints() {
    if ((windowWidth != getWindowWidth()) ||
        (windowHeight != getWindowHeight()) ||
        (windowWidth == 0)) {
      windowWidth = getWindowWidth();
      windowHeight = getWindowHeight();
      breakpoints.clear();
      breakpoints.addAll(getActiveBreakpoints());
      breakpoints.sort(PWAResponsiveUtils.breakpointComparator);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.debugLog) {
      if (widget.breakpointsLandscape != null) {
        debugPrint('**PORTRAIT**');
      }
      PWAResponsiveUtils.debugLogBreakpoints(widget.breakpoints);
      if (widget.breakpointsLandscape != null) {
        debugPrint('**LANDSCAPE**');
        PWAResponsiveUtils.debugLogBreakpoints(widget.breakpointsLandscape);
      }
    }

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setBreakpoints();
      setDimensions();
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setBreakpoints();
        setDimensions();
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(PWAResponsiveBreakpoints oldWidget) {
    super.didUpdateWidget(oldWidget);
    setBreakpoints();
    setDimensions();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    setPlatform();

    return InheritedPWAResponsiveBreakpoints(
      data: PWAResponsiveBreakpointsData.fromWidgetState(this),
      child: widget.child,
    );
  }
}

// Device Type Constants
const String PWA_MOBILE = 'MOBILE';
const String PWA_TABLET = 'TABLET';
const String PWA_PHONE = 'PHONE';
const String PWA_DESKTOP = 'DESKTOP';

/// Responsive data about the current screen
@immutable
class PWAResponsiveBreakpointsData {
  final double screenWidth;
  final double screenHeight;
  final PWABreakpoint breakpoint;
  final List<PWABreakpoint> breakpoints;
  final bool isMobile;
  final bool isPhone;
  final bool isTablet;
  final bool isDesktop;
  final Orientation orientation;

  const PWAResponsiveBreakpointsData({
    this.screenWidth = 0,
    this.screenHeight = 0,
    this.breakpoint = const PWABreakpoint(start: 0, end: 0),
    this.breakpoints = const [],
    this.isMobile = false,
    this.isPhone = false,
    this.isTablet = false,
    this.isDesktop = false,
    this.orientation = Orientation.portrait,
  });

  static PWAResponsiveBreakpointsData fromWidgetState(
      PWAResponsiveBreakpointsState state) {
    return PWAResponsiveBreakpointsData(
      screenWidth: state.screenWidth,
      screenHeight: state.screenHeight,
      breakpoint: state.breakpoint,
      breakpoints: state.breakpoints,
      isMobile: state.breakpoint.name == PWA_MOBILE,
      isPhone: state.breakpoint.name == PWA_PHONE,
      isTablet: state.breakpoint.name == PWA_TABLET,
      isDesktop: state.breakpoint.name == PWA_DESKTOP,
      orientation: state.orientation,
    );
  }

  @override
  String toString() =>
      'PWAResponsiveBreakpoints(breakpoint: $breakpoint, isMobile: $isMobile, isPhone: $isPhone, isTablet: $isTablet, isDesktop: $isDesktop)';

  /// Returns if the active breakpoint is [name]
  bool equals(String name) => breakpoint.name == name;

  /// Is the [screenWidth] larger than [name]?
  bool largerThan(String name) =>
      screenWidth >
      (breakpoints.firstWhereOrNull((element) => element.name == name)?.end ??
          double.infinity);

  /// Is the [screenWidth] larger than or equal to [name]?
  bool largerOrEqualTo(String name) =>
      screenWidth >=
      (breakpoints.firstWhereOrNull((element) => element.name == name)?.start ??
          double.infinity);

  /// Is the [screenWidth] smaller than the [name]?
  bool smallerThan(String name) =>
      screenWidth <
      (breakpoints.firstWhereOrNull((element) => element.name == name)?.start ??
          0);

  /// Is the [screenWidth] smaller than or equal to the [name]?
  bool smallerOrEqualTo(String name) =>
      screenWidth <=
      (breakpoints.firstWhereOrNull((element) => element.name == name)?.end ??
          0);

  /// Is the [screenWidth] between [name] and [name1]?
  bool between(String name, String name1) {
    return (screenWidth >=
            (breakpoints
                    .firstWhereOrNull((element) => element.name == name)
                    ?.start ??
                0) &&
        screenWidth <=
            (breakpoints
                    .firstWhereOrNull((element) => element.name == name1)
                    ?.end ??
                0));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PWAResponsiveBreakpointsData &&
          runtimeType == other.runtimeType &&
          screenWidth == other.screenWidth &&
          screenHeight == other.screenHeight &&
          breakpoint == other.breakpoint;

  @override
  int get hashCode =>
      screenWidth.hashCode * screenHeight.hashCode * breakpoint.hashCode;
}

@immutable
class InheritedPWAResponsiveBreakpoints extends InheritedWidget {
  final PWAResponsiveBreakpointsData data;

  const InheritedPWAResponsiveBreakpoints({
    super.key,
    required this.data,
    required super.child,
  });

  @override
  bool updateShouldNotify(InheritedPWAResponsiveBreakpoints oldWidget) =>
      data != oldWidget.data;
}
