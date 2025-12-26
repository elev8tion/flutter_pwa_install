import 'pwa_event.dart';

/// Configuration for PWA installation behavior
class PWAConfig {
  const PWAConfig({
    this.delayPrompt = Duration.zero,
    this.maxDismissals = 3,
    this.dismissCooldown = const Duration(days: 7),
    this.showIOSInstructions = true,
    this.iosInstructionText,
    this.enableAnalytics = false,
    this.analyticsCallback,
    this.storagePrefix = 'flutter_pwa_install_',
    this.debug = false,
  });

  /// Delay before showing the install prompt
  ///
  /// Use this to wait for user engagement before prompting.
  /// Default: Duration.zero (no delay)
  final Duration delayPrompt;

  /// Maximum number of times user can dismiss before hiding forever
  ///
  /// After this many dismissals, the prompt will not be shown again.
  /// Default: 3
  final int maxDismissals;

  /// Cooldown period after user dismisses the prompt
  ///
  /// The prompt will not be shown again until this duration has passed.
  /// Default: Duration(days: 7)
  final Duration dismissCooldown;

  /// Whether to show custom iOS installation instructions
  ///
  /// When true, displays a dialog on iOS Safari with Add to Home Screen steps.
  /// Default: true
  final bool showIOSInstructions;

  /// Custom text for iOS installation instructions
  ///
  /// If null, uses default text.
  final String? iosInstructionText;

  /// Whether to enable analytics event tracking
  ///
  /// When true, analytics events will be sent to analyticsCallback.
  /// Default: false
  final bool enableAnalytics;

  /// Callback for analytics events
  ///
  /// Called when analytics events occur (if enableAnalytics is true).
  /// Use this to send events to your analytics service.
  final void Function(PWAEvent event)? analyticsCallback;

  /// Prefix for localStorage keys
  ///
  /// Used to namespace stored data to avoid conflicts.
  /// Default: 'flutter_pwa_install_'
  final String storagePrefix;

  /// Whether to enable debug logging
  ///
  /// When true, prints debug information to console.
  /// Default: false
  final bool debug;

  /// Create a copy with modified properties
  PWAConfig copyWith({
    Duration? delayPrompt,
    int? maxDismissals,
    Duration? dismissCooldown,
    bool? showIOSInstructions,
    String? iosInstructionText,
    bool? enableAnalytics,
    void Function(PWAEvent event)? analyticsCallback,
    String? storagePrefix,
    bool? debug,
  }) {
    return PWAConfig(
      delayPrompt: delayPrompt ?? this.delayPrompt,
      maxDismissals: maxDismissals ?? this.maxDismissals,
      dismissCooldown: dismissCooldown ?? this.dismissCooldown,
      showIOSInstructions: showIOSInstructions ?? this.showIOSInstructions,
      iosInstructionText: iosInstructionText ?? this.iosInstructionText,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      analyticsCallback: analyticsCallback ?? this.analyticsCallback,
      storagePrefix: storagePrefix ?? this.storagePrefix,
      debug: debug ?? this.debug,
    );
  }
}
