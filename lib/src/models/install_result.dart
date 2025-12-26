/// Result of an install prompt attempt
class InstallResult {
  const InstallResult({
    required this.outcome,
    this.platform,
    this.error,
    required this.timestamp,
  });

  /// Outcome of the install prompt
  final InstallOutcome outcome;

  /// Platform string (if accepted)
  final String? platform;

  /// Error message (if error occurred)
  final String? error;

  /// Timestamp when the result was generated
  final DateTime timestamp;

  /// Check if user accepted the install prompt
  bool get wasAccepted => outcome == InstallOutcome.accepted;

  /// Check if user dismissed the install prompt
  bool get wasDismissed => outcome == InstallOutcome.dismissed;

  /// Check if an error occurred
  bool get hadError => outcome == InstallOutcome.error;

  /// Check if platform is unsupported
  bool get wasUnsupported => outcome == InstallOutcome.unsupported;

  @override
  String toString() {
    return 'InstallResult('
        'outcome: ${outcome.name}, '
        '${platform != null ? 'platform: $platform, ' : ''}'
        '${error != null ? 'error: $error, ' : ''}'
        'timestamp: $timestamp'
        ')';
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'outcome': outcome.name,
      if (platform != null) 'platform': platform,
      if (error != null) 'error': error,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Possible outcomes of an install prompt
enum InstallOutcome {
  /// User accepted and installed the app
  accepted,

  /// User dismissed the install prompt
  dismissed,

  /// Platform/browser does not support PWA installation
  unsupported,

  /// An error occurred during the install process
  error,
}
