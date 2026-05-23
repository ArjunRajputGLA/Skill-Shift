import 'package:flutter/material.dart';

/// Semantic colors refined for an ultra-premium, flagship experience.
class AppColors {
  AppColors._();

  // === BRAND COLORS ===
  static const Color primary = Color(0xFF6366F1); // Modern, vibrant Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  
  static const Color accent = Color(0xFF14B8A6); // Premium Teal accent
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // === SEMANTIC GREEN ACCENTS ===
  static const Color successGreen = Color(0xFF1ED760); // Spotify energy
  static const Color onlineGreen = Color(0xFF22C55E); // Muted
  static const Color verifiedGreen = Color(0xFF4ADE80); // Soft
  static const Color progressGreen = Color(0xFF1ED760); // Energy
  static const Color accentGreen = Color(0xFF4ADE80); // Soft accent

  // === LIGHT THEME ===
  static const Color lightBackground = Color(0xFFF8FAFC); // Cool, ultra-clean slate
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A); // Almost black, premium
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDivider = Color(0xFFF1F5F9);

  // === DARK THEME (Ultra Premium) ===
  static const Color darkBackground = Color(0xFF09090B); // Pure deep OLED-friendly black
  static const Color darkSurface = Color(0xFF18181B); // Subtle elevated zinc
  static const Color darkSurfaceElevated = Color(0xFF27272A); // Highly elevated surface
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkBorder = Color(0xFF27272A);
  static const Color darkDivider = Color(0xFF18181B);
  
  // === COMPONENT COLORS ===
  static const Color avatarBg = Color(0xFFEDE9FE);
  static const Color avatarFg = Color(0xFF6366F1);
  static const Color chipBg = Color(0xFFF0F0FF);
  static const Color chipBgDark = Color(0xFF1E1B4B);

  // === GLASSMORPHISM CONSTANTS ===
  static const double glassOpacityLight = 0.85;
  static const double glassOpacityDark = 0.65;

  // === SCREEN ACCENT COLORS ===
  static const Color homeAccent1     = Color(0xFF8B5CF6); // purple
  static const Color homeAccent2     = Color(0xFF3B82F6); // blue
  static const Color exploreAccent1  = Color(0xFF06B6D4); // cyan
  static const Color exploreAccent2  = Color(0xFF14B8A6); // teal
  static const Color postsAccent1    = Color(0xFF3B82F6); // blue
  static const Color postsAccent2    = Color(0xFF10B981); // emerald
  static const Color messagesAccent1 = Color(0xFF6366F1); // indigo
  static const Color messagesAccent2 = Color(0xFF8B5CF6); // violet
  static const Color profileAccent1  = Color(0xFFF97316); // orange
  static const Color profileAccent2  = Color(0xFFEC4899); // pink

  // === CHAT BUBBLE COLORS ===
  static const Color bubbleSent         = Color(0xFF6366F1); // primary indigo
  static const Color bubbleReceived     = Color(0xFFE2E8F0); // light
  static const Color bubbleReceivedDark = Color(0xFF27272A); // dark
}
