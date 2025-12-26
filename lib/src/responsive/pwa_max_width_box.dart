import 'package:flutter/material.dart';

/// A widget that limits the maximum width of its child
///
/// Useful for creating centered content with gutters on large screens
/// while maintaining full width on mobile devices.
class PWAMaxWidthBox extends StatelessWidget {
  final double? maxWidth;
  final Widget child;

  /// Control child alignment (defaults to top center)
  final AlignmentGeometry alignment;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const PWAMaxWidthBox({
    super.key,
    required this.maxWidth,
    required this.child,
    this.alignment = Alignment.topCenter,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQuery = MediaQuery.of(context);

    if (maxWidth != null) {
      if (mediaQuery.size.width > maxWidth!) {
        mediaQuery = mediaQuery.copyWith(
          size: Size(
            maxWidth! - (padding?.horizontal ?? 0),
            mediaQuery.size.height - (padding?.vertical ?? 0),
          ),
        );
      }
    }

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: Container(
          color: backgroundColor,
          padding: padding,
          child: MediaQuery(
            data: mediaQuery,
            child: child,
          ),
        ),
      ),
    );
  }
}
