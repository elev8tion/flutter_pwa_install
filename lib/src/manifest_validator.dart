import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

import 'models/installability_checks.dart';

/// Validates PWA manifest and installability requirements
class ManifestValidator {
  ManifestValidator({this.debug = false});

  final bool debug;

  /// Fetch and parse the web app manifest
  Future<Map<String, dynamic>?> fetchManifest() async {
    try {
      final manifestLink = html.document.querySelector('link[rel="manifest"]') as html.LinkElement?;

      if (manifestLink == null || manifestLink.href.isEmpty) {
        if (debug) {
          debugPrint('[ManifestValidator] No manifest link found');
        }
        return null;
      }

      final response = await html.HttpRequest.getString(manifestLink.href);
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      if (debug) {
        debugPrint('[ManifestValidator] Failed to fetch manifest: $e');
      }
      return null;
    }
  }

  /// Check if Service Worker is registered
  Future<bool> hasServiceWorker() async {
    final serviceWorker = html.window.navigator.serviceWorker;
    if (serviceWorker == null) {
      return false;
    }

    try {
      final registration = await serviceWorker.getRegistration();
      return registration != null;
    } catch (e) {
      if (debug) {
        debugPrint('[ManifestValidator] Failed to check service worker: $e');
      }
      return false;
    }
  }

  /// Validate icons meet minimum requirements
  bool validateIcons(Map<String, dynamic> manifest) {
    final icons = manifest['icons'] as List?;
    if (icons == null || icons.isEmpty) {
      return false;
    }

    // Check for at least one icon >= 192x192
    return icons.any((icon) {
      final sizes = (icon['sizes'] as String?)?.split('x') ?? [];
      if (sizes.length != 2) return false;

      final width = int.tryParse(sizes[0]) ?? 0;
      final height = int.tryParse(sizes[1]) ?? 0;
      return width >= 192 && height >= 192;
    });
  }

  /// Perform comprehensive installability checks
  Future<InstallabilityChecks> checkInstallability() async {
    final errors = <String>[];
    final warnings = <String>[];

    // Check HTTPS
    final isHttps = html.window.location.protocol == 'https:' ||
        html.window.location.hostname == 'localhost' ||
        html.window.location.hostname == '127.0.0.1';

    if (!isHttps) {
      errors.add('PWA requires HTTPS (or localhost for development)');
    }

    // Fetch manifest
    final manifest = await fetchManifest();
    final hasManifest = manifest != null;

    if (!hasManifest) {
      errors.add(
        'No web app manifest found. Add <link rel="manifest" href="manifest.json"> to your index.html',
      );
    }

    // Check Service Worker
    final hasServiceWorker = await this.hasServiceWorker();
    if (!hasServiceWorker) {
      errors.add(
        'No Service Worker registered. PWAs require a Service Worker for offline support',
      );
    }

    // Manifest validation
    bool hasValidIcons = false;
    bool hasName = false;
    bool hasStartUrl = false;
    bool hasDisplay = false;

    if (manifest != null) {
      hasValidIcons = validateIcons(manifest);
      hasName = manifest.containsKey('name') || manifest.containsKey('short_name');
      hasStartUrl = manifest.containsKey('start_url');
      hasDisplay = manifest.containsKey('display');

      if (!hasValidIcons) {
        errors.add('Manifest must include at least one icon with size >= 192x192');
      }

      if (!hasName) {
        errors.add('Manifest must include "name" or "short_name"');
      }

      if (!hasStartUrl) {
        warnings.add('Manifest should include "start_url"');
      }

      if (!hasDisplay) {
        warnings.add('Manifest should include "display" property (e.g., "standalone")');
      }

      // Additional best practices
      if (!manifest.containsKey('theme_color')) {
        warnings.add('Consider adding "theme_color" to manifest for better UX');
      }

      if (!manifest.containsKey('description')) {
        warnings.add('Consider adding "description" to manifest');
      }

      final screenshots = manifest['screenshots'] as List?;
      if (screenshots == null || screenshots.isEmpty) {
        warnings.add(
          'Consider adding "screenshots" to manifest for richer install prompt',
        );
      }
    }

    return InstallabilityChecks(
      hasManifest: hasManifest,
      hasServiceWorker: hasServiceWorker,
      isHttps: isHttps,
      hasValidIcons: hasValidIcons,
      hasName: hasName,
      hasStartUrl: hasStartUrl,
      hasDisplay: hasDisplay,
      errors: errors,
      warnings: warnings,
    );
  }
}
