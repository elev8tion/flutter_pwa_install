import 'package:flutter/material.dart';

/// Beautiful iOS-style installation instructions dialog
///
/// Shows step-by-step instructions for adding the app to home screen on iOS Safari.
class IOSInstallDialog extends StatelessWidget {
  const IOSInstallDialog({
    super.key,
    this.customText,
  });

  final String? customText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Install App',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Custom text or default message
            Text(
              customText ??
              'Install this app on your iPhone: tap Share and then Add to Home Screen',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),

            // Step-by-step instructions
            _buildStep(
              context,
              number: 1,
              text: 'Tap the Share button',
              icon: Icons.ios_share,
              iconColor: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),

            _buildStep(
              context,
              number: 2,
              text: 'Select "Add to Home Screen"',
              iconColor: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),

            _buildStep(
              context,
              number: 3,
              text: 'Tap "Add" to confirm',
              iconColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required int number,
    required String text,
    IconData? icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Step content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: theme.textTheme.bodyMedium,
              ),
              if (icon != null) ...[
                const SizedBox(height: 8),
                Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Show the dialog
  static Future<void> show(
    BuildContext context, {
    String? customText,
  }) {
    return showDialog(
      context: context,
      builder: (context) => IOSInstallDialog(customText: customText),
    );
  }
}
