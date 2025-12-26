/// Comprehensive PWA installability validation results
class InstallabilityChecks {
  const InstallabilityChecks({
    required this.hasManifest,
    required this.hasServiceWorker,
    required this.isHttps,
    required this.hasValidIcons,
    required this.hasName,
    required this.hasStartUrl,
    required this.hasDisplay,
    required this.errors,
    required this.warnings,
  });

  /// Whether a manifest.json file exists and is valid
  final bool hasManifest;

  /// Whether a Service Worker is registered
  final bool hasServiceWorker;

  /// Whether the site is served over HTTPS (or localhost)
  final bool isHttps;

  /// Whether manifest has icons >= 192x192px
  final bool hasValidIcons;

  /// Whether manifest has name or short_name
  final bool hasName;

  /// Whether manifest has start_url
  final bool hasStartUrl;

  /// Whether manifest has display property
  final bool hasDisplay;

  /// List of errors preventing installation
  final List<String> errors;

  /// List of warnings (non-blocking issues)
  final List<String> warnings;

  /// Check if all minimum requirements are met
  bool get meetsMinimumRequirements {
    return hasManifest &&
        hasServiceWorker &&
        isHttps &&
        hasValidIcons &&
        hasName;
  }

  /// Check if there are any errors
  bool get hasErrors => errors.isNotEmpty;

  /// Check if there are any warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Get a human-readable summary
  String get summary {
    if (meetsMinimumRequirements) {
      return '✅ Your PWA meets minimum installability requirements!';
    } else {
      return '❌ Your PWA does NOT meet installability requirements';
    }
  }

  /// Get detailed report as string
  String getReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== PWA Installability Report ===\n');
    buffer.writeln(summary);
    buffer.writeln('\nChecks:');
    buffer.writeln('  ${isHttps ? '✅' : '❌'} HTTPS (or localhost)');
    buffer.writeln('  ${hasManifest ? '✅' : '❌'} Web App Manifest');
    buffer.writeln('  ${hasServiceWorker ? '✅' : '❌'} Service Worker');
    buffer.writeln('  ${hasValidIcons ? '✅' : '❌'} Valid Icons (>= 192x192)');
    buffer.writeln('  ${hasName ? '✅' : '❌'} App Name');
    buffer.writeln('  ${hasStartUrl ? '✅' : '⚠️ '} Start URL');
    buffer.writeln('  ${hasDisplay ? '✅' : '⚠️ '} Display Mode');

    if (errors.isNotEmpty) {
      buffer.writeln('\nErrors:');
      for (final error in errors) {
        buffer.writeln('  ❌ $error');
      }
    }

    if (warnings.isNotEmpty) {
      buffer.writeln('\nWarnings:');
      for (final warning in warnings) {
        buffer.writeln('  ⚠️  $warning');
      }
    }

    return buffer.toString();
  }

  @override
  String toString() => getReport();

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'hasManifest': hasManifest,
      'hasServiceWorker': hasServiceWorker,
      'isHttps': isHttps,
      'hasValidIcons': hasValidIcons,
      'hasName': hasName,
      'hasStartUrl': hasStartUrl,
      'hasDisplay': hasDisplay,
      'meetsMinimumRequirements': meetsMinimumRequirements,
      'errors': errors,
      'warnings': warnings,
    };
  }
}
