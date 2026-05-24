import 'package:flutter/material.dart';

extension FarreyThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Background & Surfaces
  Color get farreyBackground => isDark ? const Color(0xFF18181B) : const Color(0xFFFAFAFA);
  Color get farreySurface => isDark ? const Color(0xFF27272A) : const Color(0xFFFFFFFF);
  Color get farreySurfaceElevated => isDark ? const Color(0xFF3F3F46) : const Color(0xFFF4F4F5);

  // Accents (Orangish Yellow Theme)
  Color get farreyPrimary => isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
  Color get farreySecondary => isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);

  // Typography
  Color get farreyTextPrimary => isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B);
  Color get farreyTextSecondary => isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

  // States
  Color get farreyError => isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
  Color get farreySuccess => isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  Color get farreyWarning => isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);

  // Borders & Dividers
  Color get farreyBorder => isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7);
  Color get farreyDivider => isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5);
}

// Keep a static fallback class just in case some models/widgets can't access context easily.
// (We should strive to use the extension above wherever possible)
class FarreyColors {
  FarreyColors._();
  
  // Hardcoded to dark or light for places without context (rare)
  static const Color primary = Color(0xFF6366F1);
  static const Color error = Color(0xFFEF4444);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
}
