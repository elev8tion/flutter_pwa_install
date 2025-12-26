import 'package:flutter/material.dart';

import 'pwa_responsive_scaffold.dart';

/// Configuration for responsive section layouts
class PWASectionConfig {
  /// Number of columns to display sections in
  final int columns;

  /// Horizontal spacing between columns
  final double columnSpacing;

  /// Vertical spacing between rows
  final double rowSpacing;

  /// Alignment of sections within columns
  final CrossAxisAlignment crossAxisAlignment;

  const PWASectionConfig({
    this.columns = 1,
    this.columnSpacing = 24,
    this.rowSpacing = 16,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  /// Single column layout (mobile)
  static const mobile = PWASectionConfig(
    columns: 1,
    columnSpacing: 16,
    rowSpacing: 16,
  );

  /// Two column layout (tablet/desktop)
  static const twoColumn = PWASectionConfig(
    columns: 2,
    columnSpacing: 24,
    rowSpacing: 20,
  );

  /// Three column layout (large desktop)
  static const threeColumn = PWASectionConfig(
    columns: 3,
    columnSpacing: 32,
    rowSpacing: 24,
  );
}

/// A responsive section layout for forms and settings
///
/// On mobile: Displays sections vertically in a single column
/// On tablet/desktop: Arranges sections in multiple columns
///
/// This is ideal for settings screens where you want to show
/// multiple settings sections side-by-side on larger screens.
///
/// Example:
/// ```dart
/// PWAResponsiveSection(
///   sections: [
///     SettingsSection(title: 'Profile', children: [...]),
///     SettingsSection(title: 'Preferences', children: [...]),
///     SettingsSection(title: 'Account', children: [...]),
///   ],
/// )
/// ```
class PWAResponsiveSection extends StatelessWidget {
  /// The sections to display
  final List<Widget> sections;

  /// Configuration for mobile layout
  final PWASectionConfig mobileConfig;

  /// Configuration for tablet layout
  final PWASectionConfig? tabletConfig;

  /// Configuration for desktop layout
  final PWASectionConfig? desktopConfig;

  /// Configuration for large desktop layout
  final PWASectionConfig? largeDesktopConfig;

  /// Custom breakpoint for mobile -> tablet transition
  final double mobileBreakpoint;

  /// Custom breakpoint for tablet -> desktop transition
  final double tabletBreakpoint;

  /// Custom breakpoint for desktop -> large desktop transition
  final double desktopBreakpoint;

  /// Padding around the section container
  final EdgeInsets? padding;

  /// Enable debug logging
  final bool debug;

  const PWAResponsiveSection({
    super.key,
    required this.sections,
    this.mobileConfig = const PWASectionConfig(columns: 1),
    this.tabletConfig,
    this.desktopConfig,
    this.largeDesktopConfig,
    this.mobileBreakpoint = 600,
    this.tabletBreakpoint = 900,
    this.desktopBreakpoint = 1200,
    this.padding,
    this.debug = false,
  });

  /// Factory constructor for quick two-column desktop setup
  factory PWAResponsiveSection.twoColumn({
    Key? key,
    required List<Widget> sections,
    double mobileBreakpoint = 600,
    EdgeInsets? padding,
  }) {
    return PWAResponsiveSection(
      key: key,
      sections: sections,
      mobileConfig: PWASectionConfig.mobile,
      tabletConfig: PWASectionConfig.twoColumn,
      desktopConfig: PWASectionConfig.twoColumn,
      mobileBreakpoint: mobileBreakpoint,
      padding: padding,
    );
  }

  PWASectionConfig _getConfigForDevice(PWADeviceType deviceType) {
    switch (deviceType) {
      case PWADeviceType.mobile:
        return mobileConfig;
      case PWADeviceType.tablet:
        return tabletConfig ?? mobileConfig;
      case PWADeviceType.desktop:
        return desktopConfig ?? tabletConfig ?? mobileConfig;
      case PWADeviceType.largeDesktop:
        return largeDesktopConfig ??
            desktopConfig ??
            tabletConfig ??
            mobileConfig;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final deviceType = PWAResponsiveScaffold.deviceTypeOf(
          context,
          mobileBreakpoint: mobileBreakpoint,
          tabletBreakpoint: tabletBreakpoint,
          desktopBreakpoint: desktopBreakpoint,
        );

        final config = _getConfigForDevice(deviceType);

        if (debug) {
          debugPrint(
              '[PWAResponsiveSection] Width: $screenWidth, Device: $deviceType, Columns: ${config.columns}');
        }

        Widget content;

        // Single column - simple vertical list
        if (config.columns == 1) {
          content = Column(
            crossAxisAlignment: config.crossAxisAlignment,
            children: _buildSingleColumnChildren(config),
          );
        } else {
          content = _buildMultiColumnLayout(config);
        }

        if (padding != null) {
          content = Padding(padding: padding!, child: content);
        }

        return content;
      },
    );
  }

  List<Widget> _buildSingleColumnChildren(PWASectionConfig config) {
    final List<Widget> children = [];
    for (int i = 0; i < sections.length; i++) {
      children.add(sections[i]);
      if (i < sections.length - 1) {
        children.add(SizedBox(height: config.rowSpacing));
      }
    }
    return children;
  }

  Widget _buildMultiColumnLayout(PWASectionConfig config) {
    // Distribute sections across columns
    final List<List<Widget>> columns = List.generate(
      config.columns,
      (_) => <Widget>[],
    );

    // Round-robin distribution
    for (int i = 0; i < sections.length; i++) {
      columns[i % config.columns].add(sections[i]);
    }

    return Row(
      crossAxisAlignment: config.crossAxisAlignment,
      children: [
        for (int i = 0; i < columns.length; i++) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: config.crossAxisAlignment,
              children: _buildColumnChildren(columns[i], config),
            ),
          ),
          if (i < columns.length - 1)
            SizedBox(width: config.columnSpacing),
        ],
      ],
    );
  }

  List<Widget> _buildColumnChildren(
      List<Widget> items, PWASectionConfig config) {
    final List<Widget> children = [];
    for (int i = 0; i < items.length; i++) {
      children.add(items[i]);
      if (i < items.length - 1) {
        children.add(SizedBox(height: config.rowSpacing));
      }
    }
    return children;
  }
}

/// A responsive row that flows to column on mobile
///
/// On mobile: Children stack vertically
/// On tablet/desktop: Children are arranged horizontally
///
/// Example:
/// ```dart
/// PWAResponsiveRow(
///   children: [
///     Expanded(child: TextField()),
///     SizedBox(width: 16),
///     Expanded(child: TextField()),
///   ],
/// )
/// ```
class PWAResponsiveRow extends StatelessWidget {
  /// Children to display
  final List<Widget> children;

  /// Spacing between children when vertical (mobile)
  final double verticalSpacing;

  /// Alignment when horizontal
  final MainAxisAlignment mainAxisAlignment;

  /// Alignment when horizontal
  final CrossAxisAlignment crossAxisAlignment;

  /// Alignment when vertical
  final CrossAxisAlignment verticalCrossAxisAlignment;

  /// Custom breakpoint for mobile -> tablet transition
  final double mobileBreakpoint;

  const PWAResponsiveRow({
    super.key,
    required this.children,
    this.verticalSpacing = 16,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.verticalCrossAxisAlignment = CrossAxisAlignment.stretch,
    this.mobileBreakpoint = 600,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileBreakpoint) {
          // Mobile - vertical layout
          return Column(
            crossAxisAlignment: verticalCrossAxisAlignment,
            children: _buildVerticalChildren(),
          );
        }

        // Tablet/Desktop - horizontal layout
        return Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          children: children,
        );
      },
    );
  }

  List<Widget> _buildVerticalChildren() {
    final List<Widget> result = [];
    for (int i = 0; i < children.length; i++) {
      // Skip SizedBox spacers that were meant for horizontal layout
      if (children[i] is SizedBox) {
        continue;
      }

      // Unwrap Expanded widgets for vertical layout
      if (children[i] is Expanded) {
        result.add((children[i] as Expanded).child);
      } else if (children[i] is Flexible) {
        result.add((children[i] as Flexible).child);
      } else {
        result.add(children[i]);
      }

      if (i < children.length - 1) {
        result.add(SizedBox(height: verticalSpacing));
      }
    }
    return result;
  }
}

/// A card that can span multiple columns on larger screens
class PWAResponsiveCard extends StatelessWidget {
  /// The card content
  final Widget child;

  /// Number of columns this card should span on mobile (usually 1)
  final int mobileSpan;

  /// Number of columns this card should span on tablet
  final int? tabletSpan;

  /// Number of columns this card should span on desktop
  final int? desktopSpan;

  /// Card elevation
  final double elevation;

  /// Card border radius
  final double borderRadius;

  /// Card margin
  final EdgeInsets? margin;

  /// Card padding
  final EdgeInsets? padding;

  /// Card background color
  final Color? backgroundColor;

  const PWAResponsiveCard({
    super.key,
    required this.child,
    this.mobileSpan = 1,
    this.tabletSpan,
    this.desktopSpan,
    this.elevation = 1,
    this.borderRadius = 12,
    this.margin,
    this.padding,
    this.backgroundColor,
  });

  /// Get the span value for the current device
  int getSpanForDevice(PWADeviceType deviceType) {
    switch (deviceType) {
      case PWADeviceType.mobile:
        return mobileSpan;
      case PWADeviceType.tablet:
        return tabletSpan ?? mobileSpan;
      case PWADeviceType.desktop:
      case PWADeviceType.largeDesktop:
        return desktopSpan ?? tabletSpan ?? mobileSpan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      margin: margin ?? EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      color: backgroundColor,
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );
  }
}

/// A helper widget to create responsive spacing
class PWAResponsiveSpacing extends StatelessWidget {
  /// Spacing for mobile
  final double mobile;

  /// Spacing for tablet (defaults to mobile)
  final double? tablet;

  /// Spacing for desktop (defaults to tablet or mobile)
  final double? desktop;

  /// Whether this is horizontal spacing (true) or vertical spacing (false)
  final bool horizontal;

  /// Custom breakpoints
  final double mobileBreakpoint;
  final double tabletBreakpoint;

  const PWAResponsiveSpacing({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.horizontal = false,
    this.mobileBreakpoint = 600,
    this.tabletBreakpoint = 900,
  });

  /// Vertical spacing
  const PWAResponsiveSpacing.vertical({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.mobileBreakpoint = 600,
    this.tabletBreakpoint = 900,
  }) : horizontal = false;

  /// Horizontal spacing
  const PWAResponsiveSpacing.horizontal({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.mobileBreakpoint = 600,
    this.tabletBreakpoint = 900,
  }) : horizontal = true;

  @override
  Widget build(BuildContext context) {
    final deviceType = PWAResponsiveScaffold.deviceTypeOf(
      context,
      mobileBreakpoint: mobileBreakpoint,
      tabletBreakpoint: tabletBreakpoint,
    );

    double spacing;
    switch (deviceType) {
      case PWADeviceType.mobile:
        spacing = mobile;
        break;
      case PWADeviceType.tablet:
        spacing = tablet ?? mobile;
        break;
      case PWADeviceType.desktop:
      case PWADeviceType.largeDesktop:
        spacing = desktop ?? tablet ?? mobile;
        break;
    }

    return SizedBox(
      width: horizontal ? spacing : null,
      height: horizontal ? null : spacing,
    );
  }
}
