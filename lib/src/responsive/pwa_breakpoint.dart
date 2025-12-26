import 'package:flutter/material.dart';

/// Responsive breakpoint definition for PWA layouts
///
/// Defines a range of screen widths where specific layout behaviors apply.
/// Use with [PWAResponsiveBreakpoints] to enable responsive design.
@immutable
class PWABreakpoint {
  /// The starting width (inclusive) in logical pixels
  final double start;

  /// The ending width (inclusive) in logical pixels
  final double end;

  /// Optional name for this breakpoint (e.g., 'mobile', 'tablet', 'desktop')
  final String? name;

  /// Optional custom data associated with this breakpoint
  final dynamic data;

  const PWABreakpoint({
    required this.start,
    required this.end,
    this.name,
    this.data,
  });

  PWABreakpoint copyWith({
    double? start,
    double? end,
    String? name,
    dynamic data,
  }) =>
      PWABreakpoint(
        start: start ?? this.start,
        end: end ?? this.end,
        name: name ?? this.name,
        data: data ?? this.data,
      );

  @override
  String toString() => 'PWABreakpoint(start: $start, end: $end, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PWABreakpoint &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          name == other.name;

  @override
  int get hashCode => start.hashCode * end.hashCode * name.hashCode;
}
