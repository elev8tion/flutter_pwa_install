/// Modern PWA installation for Flutter web apps
///
/// This package provides a comprehensive solution for installing Flutter web apps
/// as Progressive Web Apps (PWAs) with support for:
/// - Chrome/Edge native install prompts
/// - iOS custom installation UI with step-by-step instructions
/// - Manifest validation and installability checks
/// - Smart prompt timing with visit tracking and cooldown periods
/// - Analytics event tracking
/// - Platform and browser detection
/// - Optional responsive design features for adaptive layouts
library flutter_pwa_install;

// Core PWA Installation
export 'src/flutter_pwa_install_base.dart';
export 'src/models/browser_capabilities.dart';
export 'src/models/install_result.dart';
export 'src/models/installability_checks.dart';
export 'src/models/pwa_config.dart';
export 'src/models/pwa_event.dart';
export 'src/models/prompt_options.dart';
export 'src/enums/platform.dart';
export 'src/enums/browser.dart';
export 'src/enums/display_mode.dart';
export 'src/enums/install_method.dart';

// Optional Responsive Design Features
export 'src/responsive/pwa_breakpoint.dart';
export 'src/responsive/pwa_responsive_breakpoints.dart';
export 'src/responsive/pwa_responsive_utils.dart';
export 'src/responsive/pwa_max_width_box.dart';
export 'src/responsive/pwa_responsive_value.dart';
