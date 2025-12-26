import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'pwa_breakpoint.dart';

/// Utility functions for PWA responsive features
class PWAResponsiveUtils {
  /// Comparator function to order breakpoints from small to large
  static int breakpointComparator(PWABreakpoint a, PWABreakpoint b) {
    return a.start.compareTo(b.start);
  }

  /// Print a visual view of breakpoints for debugging
  static String debugLogBreakpoints(List<PWABreakpoint>? breakpoints) {
    if (breakpoints == null || breakpoints.isEmpty) return '| Empty |';
    List<PWABreakpoint> breakpointsHolder = List.from(breakpoints);
    breakpointsHolder.sort(breakpointComparator);

    var stringBuffer = StringBuffer();
    stringBuffer.write('| ');
    for (int i = 0; i < breakpointsHolder.length; i++) {
      PWABreakpoint breakpoint = breakpointsHolder[i];
      stringBuffer.write(breakpoint.start);
      stringBuffer.write(' ----- ');
      List<dynamic> attributes = [];
      String? name = breakpoint.name;
      if (name != null) attributes.add(name);
      if (attributes.isNotEmpty) {
        stringBuffer.write('(');
        for (int i = 0; i < attributes.length; i++) {
          stringBuffer.write(attributes[i]);
          if (i != attributes.length - 1) stringBuffer.write(',');
        }
        stringBuffer.write(')');
        stringBuffer.write(' ----- ');
      }
      if (breakpoint.end == double.infinity) {
        stringBuffer.write('∞');
      } else {
        stringBuffer.write(breakpoint.end);
      }
      if (i != breakpoints.length - 1) {
        stringBuffer.write(' ----- ');
      }
    }
    stringBuffer.write(' |');
    debugPrint(stringBuffer.toString());
    return stringBuffer.toString();
  }
}

/// A superset of [TargetPlatform] that includes web
enum PWATargetPlatform {
  android,
  fuchsia,
  iOS,
  linux,
  macOS,
  windows,
  web,
}

extension TargetPlatformExtension on TargetPlatform {
  PWATargetPlatform get pwaTargetPlatform {
    switch (this) {
      case TargetPlatform.android:
        return PWATargetPlatform.android;
      case TargetPlatform.fuchsia:
        return PWATargetPlatform.fuchsia;
      case TargetPlatform.iOS:
        return PWATargetPlatform.iOS;
      case TargetPlatform.linux:
        return PWATargetPlatform.linux;
      case TargetPlatform.macOS:
        return PWATargetPlatform.macOS;
      case TargetPlatform.windows:
        return PWATargetPlatform.windows;
    }
  }
}
