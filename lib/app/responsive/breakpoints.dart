/// Breakpoint constants for responsive layout decisions.
///
/// Defines minimum width thresholds for each form factor.
abstract final class Breakpoints {
  /// Compact mobile devices (phones in portrait).
  static const double mobileSmall = 0;

  /// Standard mobile devices (phones in landscape / large phones).
  static const double mobile = 360;

  /// Tablet devices and small laptops.
  static const double tablet = 600;

  /// Desktop / laptop screens.
  static const double desktop = 1024;

  /// Large TV displays.
  static const double tv = 1440;

  /// Determine the current [FormFactor] from a [width].
  static FormFactor fromWidth(double width) {
    if (width >= tv) return FormFactor.tv;
    if (width >= desktop) return FormFactor.desktop;
    if (width >= tablet) return FormFactor.tablet;
    return FormFactor.mobile;
  }
}

/// Represents the broad form-factor category.
enum FormFactor {
  mobile,
  tablet,
  desktop,
  tv,
}
