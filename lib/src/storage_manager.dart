import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Storage data model
class PWAStorage {
  const PWAStorage({
    required this.dismissCount,
    required this.lastDismissed,
    required this.lastPromptShown,
    required this.hasInstalled,
    required this.visits,
  });

  factory PWAStorage.fromJson(Map<String, dynamic> json) {
    return PWAStorage(
      dismissCount: json['dismissCount'] as int? ?? 0,
      lastDismissed: json['lastDismissed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastDismissed'] as int)
          : null,
      lastPromptShown: json['lastPromptShown'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastPromptShown'] as int)
          : null,
      hasInstalled: json['hasInstalled'] as bool? ?? false,
      visits: json['visits'] as int? ?? 0,
    );
  }

  final int dismissCount;
  final DateTime? lastDismissed;
  final DateTime? lastPromptShown;
  final bool hasInstalled;
  final int visits;

  Map<String, dynamic> toJson() {
    return {
      'dismissCount': dismissCount,
      'lastDismissed': lastDismissed?.millisecondsSinceEpoch,
      'lastPromptShown': lastPromptShown?.millisecondsSinceEpoch,
      'hasInstalled': hasInstalled,
      'visits': visits,
    };
  }

  PWAStorage copyWith({
    int? dismissCount,
    DateTime? lastDismissed,
    DateTime? lastPromptShown,
    bool? hasInstalled,
    int? visits,
  }) {
    return PWAStorage(
      dismissCount: dismissCount ?? this.dismissCount,
      lastDismissed: lastDismissed ?? this.lastDismissed,
      lastPromptShown: lastPromptShown ?? this.lastPromptShown,
      hasInstalled: hasInstalled ?? this.hasInstalled,
      visits: visits ?? this.visits,
    );
  }
}

/// Manages localStorage for tracking install prompts and user behavior
class StorageManager {
  StorageManager({
    required this.prefix,
    this.debug = false,
  });

  final String prefix;
  final bool debug;

  String get _storageKey => '${prefix}data';

  /// Get stored data
  PWAStorage getData() {
    try {
      final stored = html.window.localStorage[_storageKey];
      if (stored != null) {
        final json = jsonDecode(stored) as Map<String, dynamic>;
        return PWAStorage.fromJson(json);
      }
    } catch (e) {
      if (debug) {
        debugPrint('[StorageManager] Failed to read data: $e');
      }
    }

    // Return defaults
    return const PWAStorage(
      dismissCount: 0,
      lastDismissed: null,
      lastPromptShown: null,
      hasInstalled: false,
      visits: 0,
    );
  }

  /// Save data to localStorage
  void _saveData(PWAStorage data) {
    try {
      final json = jsonEncode(data.toJson());
      html.window.localStorage[_storageKey] = json;
    } catch (e) {
      if (debug) {
        debugPrint('[StorageManager] Failed to save data: $e');
      }
    }
  }

  /// Increment dismiss count
  void recordDismissal() {
    final data = getData();
    _saveData(data.copyWith(
      dismissCount: data.dismissCount + 1,
      lastDismissed: DateTime.now(),
    ));
  }

  /// Record that prompt was shown
  void recordPromptShown() {
    final data = getData();
    _saveData(data.copyWith(
      lastPromptShown: DateTime.now(),
    ));
  }

  /// Record that app was installed
  void recordInstallation() {
    final data = getData();
    _saveData(data.copyWith(
      hasInstalled: true,
    ));
  }

  /// Increment visit count
  void recordVisit() {
    final data = getData();
    _saveData(data.copyWith(
      visits: data.visits + 1,
    ));
  }

  /// Check if user has dismissed too many times
  bool hasExceededDismissals(int maxDismissals) {
    final data = getData();
    return data.dismissCount >= maxDismissals;
  }

  /// Check if we're in cooldown period after dismissal
  bool isInCooldown(Duration cooldown) {
    final data = getData();
    if (data.lastDismissed == null) {
      return false;
    }

    final timeSinceDismissal = DateTime.now().difference(data.lastDismissed!);
    return timeSinceDismissal < cooldown;
  }

  /// Check if app has been installed
  bool hasBeenInstalled() {
    return getData().hasInstalled;
  }

  /// Get number of visits
  int getVisitCount() {
    return getData().visits;
  }

  /// Clear all stored data
  void clear() {
    try {
      html.window.localStorage.remove(_storageKey);
    } catch (e) {
      if (debug) {
        debugPrint('[StorageManager] Failed to clear data: $e');
      }
    }
  }
}
