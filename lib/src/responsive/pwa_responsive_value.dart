// ignore_for_file: constant_identifier_names

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/widgets.dart';

import 'pwa_responsive_breakpoints.dart';

/// Conditional values based on the active breakpoint
///
/// Get a value that corresponds to the active breakpoint
/// determined by conditions set in [conditionalValues].
class PWAResponsiveValue<T> {
  late T value;
  final T? defaultValue;
  final List<PWACondition<T>> conditionalValues;
  final BuildContext context;

  PWAResponsiveValue(
    this.context, {
    required this.conditionalValues,
    this.defaultValue,
  }) {
    if (conditionalValues
            .firstWhereOrNull((element) => element.name != null) !=
        null) {
      try {
        PWAResponsiveBreakpoints.of(context);
      } catch (e) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'A conditional value was caught referencing a nonexistent breakpoint.'),
          ErrorDescription(
              'PWAResponsiveValue requires a parent PWAResponsiveBreakpoints '
              'to reference breakpoints.')
        ]);
      }
    }

    List<PWACondition> conditions = [];
    conditions.addAll(conditionalValues);
    value = (getValue(context, conditions) ?? defaultValue) as T;
  }

  T? getValue(BuildContext context, List<PWACondition> conditions) {
    PWACondition? activeCondition = getActiveCondition(context, conditions);
    if (activeCondition == null) return null;
    if (PWAResponsiveBreakpoints.of(context).orientation ==
            Orientation.landscape &&
        activeCondition.landscapeValue != null) {
      return activeCondition.landscapeValue;
    }
    return activeCondition.value;
  }

  PWACondition? getActiveCondition(
      BuildContext context, List<PWACondition> conditions) {
    PWAResponsiveBreakpointsData responsiveBreakpointsData =
        PWAResponsiveBreakpoints.of(context);
    double screenWidth = responsiveBreakpointsData.screenWidth;

    for (PWACondition condition in conditions.reversed) {
      if (condition.condition == PWAConditional.EQUALS) {
        if (condition.name == responsiveBreakpointsData.breakpoint.name) {
          return condition;
        }
        continue;
      }

      if (condition.condition == PWAConditional.BETWEEN) {
        if (screenWidth >= condition.breakpointStart! &&
            screenWidth <= condition.breakpointEnd!) {
          return condition;
        }
        continue;
      }

      if (condition.condition == PWAConditional.SMALLER_THAN) {
        if (condition.name != null) {
          if (responsiveBreakpointsData.smallerThan(condition.name!)) {
            return condition;
          }
        }
        if (condition.breakpointStart != null) {
          if (screenWidth < condition.breakpointStart!) {
            return condition;
          }
        }
        continue;
      }

      if (condition.condition == PWAConditional.LARGER_THAN) {
        if (condition.name != null) {
          if (responsiveBreakpointsData.largerThan(condition.name!)) {
            return condition;
          }
        }
        if (condition.breakpointStart != null) {
          if (screenWidth > condition.breakpointStart!) {
            return condition;
          }
        }
        continue;
      }
    }

    return null;
  }
}

enum PWAConditional {
  LARGER_THAN,
  EQUALS,
  SMALLER_THAN,
  BETWEEN,
}

/// A conditional value provider
class PWACondition<T> {
  final int? breakpointStart;
  final int? breakpointEnd;
  final String? name;
  final PWAConditional? condition;
  final T? value;
  final T? landscapeValue;

  PWACondition._({
    this.breakpointStart,
    this.breakpointEnd,
    this.name,
    this.condition,
    required this.value,
    T? landscapeValue,
  })  : landscapeValue = (landscapeValue ?? value),
        assert(breakpointStart != null || name != null),
        assert((condition == PWAConditional.EQUALS) ? name != null : true);

  const PWACondition.equals({
    required this.name,
    this.value,
    T? landscapeValue,
  })  : landscapeValue = (landscapeValue ?? value),
        breakpointStart = null,
        breakpointEnd = null,
        condition = PWAConditional.EQUALS;

  const PWACondition.largerThan({
    int? breakpoint,
    this.name,
    this.value,
    T? landscapeValue,
  })  : landscapeValue = (landscapeValue ?? value),
        breakpointStart = breakpoint,
        breakpointEnd = breakpoint,
        condition = PWAConditional.LARGER_THAN;

  const PWACondition.smallerThan({
    int? breakpoint,
    this.name,
    this.value,
    T? landscapeValue,
  })  : landscapeValue = (landscapeValue ?? value),
        breakpointStart = breakpoint,
        breakpointEnd = breakpoint,
        condition = PWAConditional.SMALLER_THAN;

  const PWACondition.between({
    required int? start,
    required int? end,
    this.value,
    T? landscapeValue,
  })  : landscapeValue = (landscapeValue ?? value),
        breakpointStart = start,
        breakpointEnd = end,
        name = null,
        condition = PWAConditional.BETWEEN;

  PWACondition<T> copyWith({
    int? breakpointStart,
    int? breakpointEnd,
    String? name,
    PWAConditional? condition,
    T? value,
    T? landscapeValue,
  }) =>
      PWACondition<T>._(
        breakpointStart: breakpointStart ?? this.breakpointStart,
        breakpointEnd: breakpointEnd ?? this.breakpointEnd,
        name: name ?? this.name,
        condition: condition ?? this.condition,
        value: value ?? this.value,
        landscapeValue: landscapeValue ?? this.landscapeValue,
      );

  @override
  String toString() =>
      'PWACondition(breakpointStart: $breakpointStart, breakpointEnd: $breakpointEnd, name: $name, condition: $condition, value: $value, landscapeValue: $landscapeValue)';
}

/// A convenience wrapper for responsive visibility
class PWAResponsiveVisibility extends StatelessWidget {
  final Widget child;
  final bool visible;
  final List<PWACondition<bool>> visibleConditions;
  final List<PWACondition<bool>> hiddenConditions;
  final Widget replacement;
  final bool maintainState;
  final bool maintainAnimation;
  final bool maintainSize;
  final bool maintainSemantics;
  final bool maintainInteractivity;

  const PWAResponsiveVisibility({
    super.key,
    required this.child,
    this.visible = true,
    this.visibleConditions = const [],
    this.hiddenConditions = const [],
    this.replacement = const SizedBox.shrink(),
    this.maintainState = false,
    this.maintainAnimation = false,
    this.maintainSize = false,
    this.maintainSemantics = false,
    this.maintainInteractivity = false,
  });

  @override
  Widget build(BuildContext context) {
    List<PWACondition<bool>> conditions = [];
    bool visibleValue = visible;

    conditions.addAll(visibleConditions.map((e) => e.copyWith(value: true)));
    conditions.addAll(hiddenConditions.map((e) => e.copyWith(value: false)));

    visibleValue = PWAResponsiveValue<bool>(
      context,
      defaultValue: visibleValue,
      conditionalValues: conditions,
    ).value;

    return Visibility(
      replacement: replacement,
      visible: visibleValue,
      maintainState: maintainState,
      maintainAnimation: maintainAnimation,
      maintainSize: maintainSize,
      maintainSemantics: maintainSemantics,
      maintainInteractivity: maintainInteractivity,
      child: child,
    );
  }
}

/// Responsive constraints wrapper
class PWAResponsiveConstraints extends StatelessWidget {
  final Widget child;
  final BoxConstraints? constraint;
  final List<PWACondition<BoxConstraints?>> conditionalConstraints;

  const PWAResponsiveConstraints({
    super.key,
    required this.child,
    this.constraint,
    this.conditionalConstraints = const [],
  });

  @override
  Widget build(BuildContext context) {
    BoxConstraints? constraintValue = constraint;

    constraintValue = PWAResponsiveValue<BoxConstraints?>(
      context,
      defaultValue: constraintValue,
      conditionalValues: conditionalConstraints,
    ).value;

    return Container(
      constraints: constraintValue,
      child: child,
    );
  }
}
