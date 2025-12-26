/// Analytics event for PWA installation funnel tracking
class PWAEvent {
  const PWAEvent({
    required this.type,
    required this.timestamp,
    this.metadata = const {},
  });

  /// Type of PWA event
  final PWAEventType type;

  /// When the event occurred
  final DateTime timestamp;

  /// Additional event metadata
  final Map<String, dynamic> metadata;

  @override
  String toString() {
    return 'PWAEvent('
        'type: ${type.name}, '
        'timestamp: $timestamp'
        '${metadata.isNotEmpty ? ', metadata: $metadata' : ''}'
        ')';
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}

/// Types of PWA events for analytics tracking
enum PWAEventType {
  /// Install prompt was shown to user
  promptShown,

  /// User accepted the install prompt
  installAccepted,

  /// User dismissed the install prompt
  installDismissed,

  /// App was successfully installed
  appInstalled,

  /// App was launched in standalone mode
  appLaunched,
}

extension PWAEventTypeExtension on PWAEventType {
  /// Get human-readable event name
  String get displayName {
    switch (this) {
      case PWAEventType.promptShown:
        return 'Prompt Shown';
      case PWAEventType.installAccepted:
        return 'Install Accepted';
      case PWAEventType.installDismissed:
        return 'Install Dismissed';
      case PWAEventType.appInstalled:
        return 'App Installed';
      case PWAEventType.appLaunched:
        return 'App Launched';
    }
  }
}
