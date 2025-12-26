/// Browser types
enum BrowserType {
  /// Google Chrome
  chrome('Chrome'),

  /// Apple Safari
  safari('Safari'),

  /// Mozilla Firefox
  firefox('Firefox'),

  /// Microsoft Edge
  edge('Edge'),

  /// Samsung Internet
  samsung('Samsung Internet'),

  /// Opera browser
  opera('Opera'),

  /// Unknown or unsupported browser
  unknown('Unknown');

  const BrowserType(this.displayName);

  /// Human-readable browser name
  final String displayName;
}
