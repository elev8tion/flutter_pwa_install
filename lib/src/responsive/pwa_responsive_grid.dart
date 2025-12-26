import 'package:flutter/material.dart';

import 'pwa_responsive_scaffold.dart';

/// Configuration for responsive grid behavior
class PWAGridConfig {
  /// Number of columns for this breakpoint
  final int columns;

  /// Horizontal spacing between items
  final double crossAxisSpacing;

  /// Vertical spacing between items
  final double mainAxisSpacing;

  /// Child aspect ratio (width / height)
  final double? childAspectRatio;

  /// Padding around the grid
  final EdgeInsets? padding;

  const PWAGridConfig({
    required this.columns,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.childAspectRatio,
    this.padding,
  });

  /// Single column layout (mobile)
  static const mobile = PWAGridConfig(
    columns: 1,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  );

  /// Two column layout (tablet)
  static const tablet = PWAGridConfig(
    columns: 2,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
  );

  /// Three column layout (desktop)
  static const desktop = PWAGridConfig(
    columns: 3,
    crossAxisSpacing: 20,
    mainAxisSpacing: 20,
  );

  /// Four column layout (large desktop)
  static const largeDesktop = PWAGridConfig(
    columns: 4,
    crossAxisSpacing: 24,
    mainAxisSpacing: 24,
  );

  PWAGridConfig copyWith({
    int? columns,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
    double? childAspectRatio,
    EdgeInsets? padding,
  }) {
    return PWAGridConfig(
      columns: columns ?? this.columns,
      crossAxisSpacing: crossAxisSpacing ?? this.crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing ?? this.mainAxisSpacing,
      childAspectRatio: childAspectRatio ?? this.childAspectRatio,
      padding: padding ?? this.padding,
    );
  }
}

/// A responsive grid that adapts column count based on screen size
///
/// On mobile: Shows items in a single column (list)
/// On tablet: Shows items in 2 columns
/// On desktop: Shows items in 3+ columns
///
/// Example:
/// ```dart
/// PWAResponsiveGrid(
///   mobileConfig: PWAGridConfig.mobile,
///   tabletConfig: PWAGridConfig.tablet,
///   desktopConfig: PWAGridConfig.desktop,
///   children: [Card1(), Card2(), Card3(), Card4()],
/// )
/// ```
class PWAResponsiveGrid extends StatelessWidget {
  /// The items to display in the grid
  final List<Widget> children;

  /// Configuration for mobile layout
  final PWAGridConfig mobileConfig;

  /// Configuration for tablet layout
  final PWAGridConfig? tabletConfig;

  /// Configuration for desktop layout
  final PWAGridConfig? desktopConfig;

  /// Configuration for large desktop layout
  final PWAGridConfig? largeDesktopConfig;

  /// Custom breakpoint for mobile -> tablet transition
  final double mobileBreakpoint;

  /// Custom breakpoint for tablet -> desktop transition
  final double tabletBreakpoint;

  /// Custom breakpoint for desktop -> large desktop transition
  final double desktopBreakpoint;

  /// Whether to shrink-wrap the grid
  final bool shrinkWrap;

  /// Scroll physics
  final ScrollPhysics? physics;

  /// Scroll controller
  final ScrollController? controller;

  /// Whether to make the grid scrollable (default: true)
  final bool scrollable;

  /// Enable debug logging
  final bool debug;

  const PWAResponsiveGrid({
    super.key,
    required this.children,
    this.mobileConfig = const PWAGridConfig(columns: 1),
    this.tabletConfig,
    this.desktopConfig,
    this.largeDesktopConfig,
    this.mobileBreakpoint = 600,
    this.tabletBreakpoint = 900,
    this.desktopBreakpoint = 1200,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
    this.scrollable = true,
    this.debug = false,
  });

  /// Factory constructor for quick setup with column counts only
  factory PWAResponsiveGrid.simple({
    Key? key,
    required List<Widget> children,
    int mobileColumns = 1,
    int tabletColumns = 2,
    int desktopColumns = 3,
    int? largeDesktopColumns,
    double spacing = 16,
    double? childAspectRatio,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return PWAResponsiveGrid(
      key: key,
      children: children,
      mobileConfig: PWAGridConfig(
        columns: mobileColumns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      tabletConfig: PWAGridConfig(
        columns: tabletColumns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      desktopConfig: PWAGridConfig(
        columns: desktopColumns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      largeDesktopConfig: largeDesktopColumns != null
          ? PWAGridConfig(
              columns: largeDesktopColumns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            )
          : null,
      shrinkWrap: shrinkWrap,
      physics: physics,
    );
  }

  PWAGridConfig _getConfigForDevice(PWADeviceType deviceType) {
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
              '[PWAResponsiveGrid] Width: $screenWidth, Device: $deviceType, Columns: ${config.columns}');
        }

        // For single column, use a more efficient ListView
        if (config.columns == 1 && config.childAspectRatio == null) {
          return _buildListView(config);
        }

        return _buildGridView(config);
      },
    );
  }

  Widget _buildListView(PWAGridConfig config) {
    final content = ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: scrollable ? physics : const NeverScrollableScrollPhysics(),
      controller: controller,
      padding: config.padding,
      itemCount: children.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: config.mainAxisSpacing),
      itemBuilder: (context, index) => children[index],
    );

    return content;
  }

  Widget _buildGridView(PWAGridConfig config) {
    final gridDelegate = config.childAspectRatio != null
        ? SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: config.columns,
            crossAxisSpacing: config.crossAxisSpacing,
            mainAxisSpacing: config.mainAxisSpacing,
            childAspectRatio: config.childAspectRatio!,
          )
        : SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: config.columns,
            crossAxisSpacing: config.crossAxisSpacing,
            mainAxisSpacing: config.mainAxisSpacing,
          );

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: scrollable ? physics : const NeverScrollableScrollPhysics(),
      controller: controller,
      padding: config.padding,
      gridDelegate: gridDelegate,
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// A responsive grid that builds items on demand (more efficient for large lists)
class PWAResponsiveGridBuilder extends StatelessWidget {
  /// Number of items to display
  final int itemCount;

  /// Builder function for each item
  final IndexedWidgetBuilder itemBuilder;

  /// Configuration for mobile layout
  final PWAGridConfig mobileConfig;

  /// Configuration for tablet layout
  final PWAGridConfig? tabletConfig;

  /// Configuration for desktop layout
  final PWAGridConfig? desktopConfig;

  /// Configuration for large desktop layout
  final PWAGridConfig? largeDesktopConfig;

  /// Custom breakpoint for mobile -> tablet transition
  final double mobileBreakpoint;

  /// Custom breakpoint for tablet -> desktop transition
  final double tabletBreakpoint;

  /// Custom breakpoint for desktop -> large desktop transition
  final double desktopBreakpoint;

  /// Whether to shrink-wrap the grid
  final bool shrinkWrap;

  /// Scroll physics
  final ScrollPhysics? physics;

  /// Scroll controller
  final ScrollController? controller;

  /// Enable debug logging
  final bool debug;

  const PWAResponsiveGridBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.mobileConfig = const PWAGridConfig(columns: 1),
    this.tabletConfig,
    this.desktopConfig,
    this.largeDesktopConfig,
    this.mobileBreakpoint = 600,
    this.tabletBreakpoint = 900,
    this.desktopBreakpoint = 1200,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
    this.debug = false,
  });

  PWAGridConfig _getConfigForDevice(PWADeviceType deviceType) {
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
              '[PWAResponsiveGridBuilder] Width: $screenWidth, Device: $deviceType, Columns: ${config.columns}');
        }

        // For single column, use ListView.builder
        if (config.columns == 1 && config.childAspectRatio == null) {
          return ListView.separated(
            shrinkWrap: shrinkWrap,
            physics: physics,
            controller: controller,
            padding: config.padding,
            itemCount: itemCount,
            separatorBuilder: (context, index) =>
                SizedBox(height: config.mainAxisSpacing),
            itemBuilder: itemBuilder,
          );
        }

        final gridDelegate = config.childAspectRatio != null
            ? SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: config.columns,
                crossAxisSpacing: config.crossAxisSpacing,
                mainAxisSpacing: config.mainAxisSpacing,
                childAspectRatio: config.childAspectRatio!,
              )
            : SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: config.columns,
                crossAxisSpacing: config.crossAxisSpacing,
                mainAxisSpacing: config.mainAxisSpacing,
              );

        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          controller: controller,
          padding: config.padding,
          gridDelegate: gridDelegate,
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}

/// A Sliver version of responsive grid for use in CustomScrollView
class PWAResponsiveSliverGrid extends StatelessWidget {
  /// The items to display
  final List<Widget> children;

  /// Configuration for mobile layout
  final PWAGridConfig mobileConfig;

  /// Configuration for tablet layout
  final PWAGridConfig? tabletConfig;

  /// Configuration for desktop layout
  final PWAGridConfig? desktopConfig;

  /// Configuration for large desktop layout
  final PWAGridConfig? largeDesktopConfig;

  /// Custom breakpoints
  final double mobileBreakpoint;
  final double tabletBreakpoint;
  final double desktopBreakpoint;

  const PWAResponsiveSliverGrid({
    super.key,
    required this.children,
    this.mobileConfig = const PWAGridConfig(columns: 1),
    this.tabletConfig,
    this.desktopConfig,
    this.largeDesktopConfig,
    this.mobileBreakpoint = 600,
    this.tabletBreakpoint = 900,
    this.desktopBreakpoint = 1200,
  });

  PWAGridConfig _getConfigForDevice(PWADeviceType deviceType) {
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
    final deviceType = PWAResponsiveScaffold.deviceTypeOf(
      context,
      mobileBreakpoint: mobileBreakpoint,
      tabletBreakpoint: tabletBreakpoint,
      desktopBreakpoint: desktopBreakpoint,
    );

    final config = _getConfigForDevice(deviceType);

    // For single column, use SliverList
    if (config.columns == 1 && config.childAspectRatio == null) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index.isEven) {
              return children[index ~/ 2];
            }
            return SizedBox(height: config.mainAxisSpacing);
          },
          childCount: children.length * 2 - 1,
        ),
      );
    }

    final gridDelegate = config.childAspectRatio != null
        ? SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: config.columns,
            crossAxisSpacing: config.crossAxisSpacing,
            mainAxisSpacing: config.mainAxisSpacing,
            childAspectRatio: config.childAspectRatio!,
          )
        : SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: config.columns,
            crossAxisSpacing: config.crossAxisSpacing,
            mainAxisSpacing: config.mainAxisSpacing,
          );

    return SliverGrid(
      gridDelegate: gridDelegate,
      delegate: SliverChildListDelegate(children),
    );
  }
}
