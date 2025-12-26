import 'package:flutter/material.dart';

import 'pwa_responsive_scaffold.dart';

/// Configuration for side panel behavior
class PWASidePanelConfig {
  /// Width ratio of the side panel relative to total width (0.0 - 1.0)
  final double widthRatio;

  /// Minimum width of the side panel in pixels
  final double minWidth;

  /// Maximum width of the side panel in pixels
  final double maxWidth;

  /// Whether the side panel is on the left or right
  final bool isLeftSide;

  /// Divider width between panels
  final double dividerWidth;

  /// Divider color
  final Color? dividerColor;

  /// Panel background color
  final Color? backgroundColor;

  /// Enable resizable panel (future feature)
  final bool resizable;

  const PWASidePanelConfig({
    this.widthRatio = 0.3,
    this.minWidth = 200,
    this.maxWidth = 400,
    this.isLeftSide = true,
    this.dividerWidth = 1,
    this.dividerColor,
    this.backgroundColor,
    this.resizable = false,
  });

  /// Preset for narrow side panels (good for navigation lists)
  static const narrow = PWASidePanelConfig(
    widthRatio: 0.25,
    minWidth: 180,
    maxWidth: 280,
  );

  /// Preset for medium side panels (good for chat history)
  static const medium = PWASidePanelConfig(
    widthRatio: 0.30,
    minWidth: 240,
    maxWidth: 360,
  );

  /// Preset for wide side panels (good for detail views)
  static const wide = PWASidePanelConfig(
    widthRatio: 0.35,
    minWidth: 300,
    maxWidth: 450,
  );

  PWASidePanelConfig copyWith({
    double? widthRatio,
    double? minWidth,
    double? maxWidth,
    bool? isLeftSide,
    double? dividerWidth,
    Color? dividerColor,
    Color? backgroundColor,
    bool? resizable,
  }) {
    return PWASidePanelConfig(
      widthRatio: widthRatio ?? this.widthRatio,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      isLeftSide: isLeftSide ?? this.isLeftSide,
      dividerWidth: dividerWidth ?? this.dividerWidth,
      dividerColor: dividerColor ?? this.dividerColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      resizable: resizable ?? this.resizable,
    );
  }
}

/// A responsive side panel layout that shows mobile on small screens
/// and a side panel layout on tablet/desktop
///
/// On mobile: Shows only the [mobileChild]
/// On tablet/desktop: Shows [sidePanel] alongside [mainContent]
///
/// Example:
/// ```dart
/// PWAResponsiveSidePanel(
///   mobileChild: ChatScreen(), // Full screen on mobile
///   sidePanel: ChatHistoryList(),
///   mainContent: ChatView(),
///   tabletConfig: PWASidePanelConfig.medium,
///   desktopConfig: PWASidePanelConfig.narrow,
/// )
/// ```
class PWAResponsiveSidePanel extends StatelessWidget {
  /// The widget to show on mobile (typically the same as mainContent)
  final Widget mobileChild;

  /// The side panel content (shown on tablet/desktop)
  final Widget sidePanel;

  /// The main content area (shown on tablet/desktop)
  final Widget mainContent;

  /// Configuration for tablet layout
  final PWASidePanelConfig tabletConfig;

  /// Configuration for desktop layout (falls back to tabletConfig if null)
  final PWASidePanelConfig? desktopConfig;

  /// Custom breakpoint for mobile -> tablet transition
  final double mobileBreakpoint;

  /// Custom breakpoint for tablet -> desktop transition
  final double tabletBreakpoint;

  /// Whether to show side panel on tablet (default: true)
  final bool showOnTablet;

  /// Whether to show side panel on desktop (default: true)
  final bool showOnDesktop;

  /// Optional callback when panel visibility changes
  final ValueChanged<bool>? onPanelVisibilityChanged;

  /// Enable debug logging
  final bool debug;

  const PWAResponsiveSidePanel({
    super.key,
    required this.mobileChild,
    required this.sidePanel,
    required this.mainContent,
    this.tabletConfig = const PWASidePanelConfig(),
    this.desktopConfig,
    this.mobileBreakpoint = 600,
    this.tabletBreakpoint = 900,
    this.showOnTablet = true,
    this.showOnDesktop = true,
    this.onPanelVisibilityChanged,
    this.debug = false,
  });

  /// Calculate the side panel width based on config and available width
  double _calculateSidePanelWidth(
      double availableWidth, PWASidePanelConfig config) {
    final calculatedWidth = availableWidth * config.widthRatio;
    return calculatedWidth.clamp(config.minWidth, config.maxWidth);
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
        );

        if (debug) {
          debugPrint(
              '[PWAResponsiveSidePanel] Width: $screenWidth, Device: $deviceType');
        }

        // Mobile layout - show mobile child only
        if (deviceType == PWADeviceType.mobile) {
          onPanelVisibilityChanged?.call(false);
          return mobileChild;
        }

        // Check if we should show side panel
        final shouldShowPanel =
            (deviceType == PWADeviceType.tablet && showOnTablet) ||
                (deviceType != PWADeviceType.tablet && showOnDesktop);

        if (!shouldShowPanel) {
          onPanelVisibilityChanged?.call(false);
          return mobileChild;
        }

        onPanelVisibilityChanged?.call(true);

        // Get appropriate config
        final config = deviceType == PWADeviceType.tablet
            ? tabletConfig
            : (desktopConfig ?? tabletConfig);

        final sidePanelWidth = _calculateSidePanelWidth(screenWidth, config);
        final mainContentWidth =
            screenWidth - sidePanelWidth - config.dividerWidth;

        // Build side panel layout
        final sidePanelWidget = Container(
          width: sidePanelWidth,
          color: config.backgroundColor,
          child: sidePanel,
        );

        final mainContentWidget = SizedBox(
          width: mainContentWidth,
          child: mainContent,
        );

        final divider = Container(
          width: config.dividerWidth,
          color: config.dividerColor ??
              Theme.of(context).dividerColor.withValues(alpha: 0.1),
        );

        // Arrange based on side configuration
        if (config.isLeftSide) {
          return Row(
            children: [
              sidePanelWidget,
              divider,
              Expanded(child: mainContentWidget),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(child: mainContentWidget),
              divider,
              sidePanelWidget,
            ],
          );
        }
      },
    );
  }
}

/// A stateful version of PWAResponsiveSidePanel that supports
/// collapsible side panels with animation
class PWACollapsibleSidePanel extends StatefulWidget {
  /// The widget to show on mobile
  final Widget mobileChild;

  /// The side panel content
  final Widget sidePanel;

  /// The main content area
  final Widget mainContent;

  /// Configuration for the side panel
  final PWASidePanelConfig config;

  /// Initial collapsed state (only affects tablet/desktop)
  final bool initiallyCollapsed;

  /// Animation duration for collapse/expand
  final Duration animationDuration;

  /// Animation curve
  final Curve animationCurve;

  /// Custom breakpoint for mobile -> tablet transition
  final double mobileBreakpoint;

  /// Builder for collapse toggle button
  final Widget Function(BuildContext context, bool isCollapsed, VoidCallback toggle)?
      collapseButtonBuilder;

  const PWACollapsibleSidePanel({
    super.key,
    required this.mobileChild,
    required this.sidePanel,
    required this.mainContent,
    this.config = const PWASidePanelConfig(),
    this.initiallyCollapsed = false,
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve = Curves.easeInOut,
    this.mobileBreakpoint = 600,
    this.collapseButtonBuilder,
  });

  @override
  State<PWACollapsibleSidePanel> createState() =>
      _PWACollapsibleSidePanelState();
}

class _PWACollapsibleSidePanelState extends State<PWACollapsibleSidePanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late bool _isCollapsed;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.initiallyCollapsed;
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      value: _isCollapsed ? 0.0 : 1.0,
    );
    _widthAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
      if (_isCollapsed) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // Mobile layout - show mobile child only
        if (screenWidth < widget.mobileBreakpoint) {
          return widget.mobileChild;
        }

        final maxSidePanelWidth = (screenWidth * widget.config.widthRatio)
            .clamp(widget.config.minWidth, widget.config.maxWidth);

        return AnimatedBuilder(
          animation: _widthAnimation,
          builder: (context, child) {
            final sidePanelWidth = maxSidePanelWidth * _widthAnimation.value;

            return Row(
              children: [
                // Side panel (collapsible)
                if (widget.config.isLeftSide) ...[
                  SizedBox(
                    width: sidePanelWidth,
                    child: ClipRect(
                      child: OverflowBox(
                        maxWidth: maxSidePanelWidth,
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: maxSidePanelWidth,
                          child: widget.sidePanel,
                        ),
                      ),
                    ),
                  ),
                  // Collapse button
                  if (widget.collapseButtonBuilder != null)
                    widget.collapseButtonBuilder!(
                        context, _isCollapsed, _toggleCollapse)
                  else
                    _defaultCollapseButton(),
                  // Divider
                  Container(
                    width: widget.config.dividerWidth,
                    color: widget.config.dividerColor ??
                        Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                ],
                // Main content
                Expanded(child: widget.mainContent),
                // Right side panel
                if (!widget.config.isLeftSide) ...[
                  Container(
                    width: widget.config.dividerWidth,
                    color: widget.config.dividerColor ??
                        Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                  if (widget.collapseButtonBuilder != null)
                    widget.collapseButtonBuilder!(
                        context, _isCollapsed, _toggleCollapse)
                  else
                    _defaultCollapseButton(),
                  SizedBox(
                    width: sidePanelWidth,
                    child: ClipRect(
                      child: OverflowBox(
                        maxWidth: maxSidePanelWidth,
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: maxSidePanelWidth,
                          child: widget.sidePanel,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _defaultCollapseButton() {
    final isLeft = widget.config.isLeftSide;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleCollapse,
        child: Container(
          width: 24,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.horizontal(
              left: isLeft ? Radius.zero : const Radius.circular(4),
              right: isLeft ? const Radius.circular(4) : Radius.zero,
            ),
          ),
          child: Icon(
            _isCollapsed
                ? (isLeft ? Icons.chevron_right : Icons.chevron_left)
                : (isLeft ? Icons.chevron_left : Icons.chevron_right),
            size: 16,
          ),
        ),
      ),
    );
  }
}
