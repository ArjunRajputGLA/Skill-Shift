import 'package:flutter/animation.dart';

/// Consolidated design-system constants for spacing, radii,
/// animation timing, and elevation.
///
/// ```dart
/// padding: EdgeInsets.all(AppSpacing.md),
/// duration: AppSpacing.durationFast,
/// ```
class AppSpacing {
  AppSpacing._();

  // ──────────────────────────────────────────────
  // SPACING
  // ──────────────────────────────────────────────

  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xxl  = 24.0;
  static const double xxxl = 32.0;
  static const double huge    = 48.0;
  static const double massive = 64.0;

  // ──────────────────────────────────────────────
  // SCREEN PADDING
  // ──────────────────────────────────────────────

  /// Top clearance for screens that sit below a fixed header / app bar.
  static const double headerClearance = 100.0;

  /// Bottom clearance for screens above a bottom nav bar.
  static const double navClearance = 120.0;

  /// Default horizontal padding for screen content.
  static const double screenHorizontal = 20.0;

  // ──────────────────────────────────────────────
  // BORDER RADII
  // ──────────────────────────────────────────────

  static const double radiusSm   = 8.0;
  static const double radiusMd   = 12.0;
  static const double radiusLg   = 16.0;
  static const double radiusXl   = 24.0;
  static const double radiusPill = 100.0;

  // ──────────────────────────────────────────────
  // ANIMATION DURATIONS
  // ──────────────────────────────────────────────

  static const Duration durationMicro    = Duration(milliseconds: 100);
  static const Duration durationFast     = Duration(milliseconds: 200);
  static const Duration durationNormal   = Duration(milliseconds: 300);
  static const Duration durationSlow     = Duration(milliseconds: 500);
  static const Duration durationEntrance = Duration(milliseconds: 600);

  // ──────────────────────────────────────────────
  // ANIMATION CURVES
  // ──────────────────────────────────────────────

  static const Curve defaultCurve  = Curves.easeOutCubic;
  static const Curve bounceCurve   = Curves.easeOutBack;
  static const Curve entranceCurve = Curves.easeOutQuart;

  // ──────────────────────────────────────────────
  // ELEVATION
  // ──────────────────────────────────────────────

  static const double elevationNone     = 0.0;
  static const double elevationLow      = 2.0;
  static const double elevationMedium   = 4.0;
  static const double elevationHigh     = 8.0;
  static const double elevationFloating = 16.0;
}
