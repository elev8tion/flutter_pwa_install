/// Options for customizing the install prompt behavior
class PromptOptions {
  const PromptOptions({
    this.onBeforeShow,
    this.onAccepted,
    this.onDismissed,
    this.onError,
  });

  /// Callback before showing the prompt
  ///
  /// Return false to cancel showing the prompt.
  /// Can be async to perform checks before showing.
  final Future<bool> Function()? onBeforeShow;

  /// Callback when user accepts the install prompt
  final void Function()? onAccepted;

  /// Callback when user dismisses the install prompt
  final void Function()? onDismissed;

  /// Callback when an error occurs during installation
  final void Function(String error)? onError;
}
