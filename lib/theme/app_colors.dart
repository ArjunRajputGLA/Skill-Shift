import 'package:flutter/material.dart';

/// Semantic colors refined for an ultra-premium, dark-rich experience.
class AppColors {
  AppColors._();

  // === BRAND COLORS ===
  static const Color primary = Color(0xFF4F46E5); // Elegant Indigo
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFF818CF8);
  
  static const Color accent = Color(0xFF06B6D4); // Subtle Cyan accent
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // === LIGHT THEME ===
  static const Color lightBackground = Color(0xFFF8FAFC); // Cool, extremely subtle gray/blue tint
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A); // Very dark slate
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDivider = Color(0xFFF1F5F9);

  // === DARK THEME (Ultra Premium) ===
  static const Color darkBackground = Color(0xFF0F1115); // Rich deep dark
  static const Color darkSurface = Color(0xFF151821); // Elevated dark surface
  static const Color darkSurfaceElevated = Color(0xFF1B1F2A); // Highly elevated surface
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF1E293B);
  static const Color darkDivider = Color(0xFF0F1115);
  
  // === GLASSMORPHISM CONSTANTS ===
  static const double glassOpacityLight = 0.75;
  static const double glassOpacityDark = 0.55;
}
