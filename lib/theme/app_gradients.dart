import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Centralized gradient system for the Skill Shift app.
///
/// Every gradient exposes light & dark variants via [isDark].
/// Use [backgroundGradient] for full-screen backgrounds and
/// the per-screen accent gradients for cards, headers & highlights.
class AppGradients {
  AppGradients._();

  // ──────────────────────────────────────────────
  // UNIFIED BACKGROUND GRADIENT
  // ──────────────────────────────────────────────

  /// Primary background gradient (indigo → teal) used on every screen.
  ///
  /// Light: very subtle washes over [AppColors.lightBackground].
  /// Dark:  deeper washes over [AppColors.darkBackground].
  static LinearGradient backgroundGradient({required bool isDark}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              AppColors.darkBackground,
              const Color(0xFF6366F1).withValues(alpha: 0.06),
              const Color(0xFF14B8A6).withValues(alpha: 0.04),
              AppColors.darkBackground,
            ]
          : [
              AppColors.lightBackground,
              const Color(0xFF6366F1).withValues(alpha: 0.03),
              const Color(0xFF14B8A6).withValues(alpha: 0.02),
              AppColors.lightBackground,
            ],
      stops: const [0.0, 0.35, 0.65, 1.0],
    );
  }

  // ──────────────────────────────────────────────
  // PER-SCREEN ACCENT GRADIENTS
  // ──────────────────────────────────────────────

  /// Home: purple → blue
  static LinearGradient homeAccent({required bool isDark}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              AppColors.homeAccent1.withValues(alpha: 0.25),
              AppColors.homeAccent2.withValues(alpha: 0.18),
            ]
          : [
              AppColors.homeAccent1.withValues(alpha: 0.12),
              AppColors.homeAccent2.withValues(alpha: 0.08),
            ],
    );
  }

  /// Explore: cyan → teal
  static LinearGradient exploreAccent({required bool isDark}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              AppColors.exploreAccent1.withValues(alpha: 0.25),
              AppColors.exploreAccent2.withValues(alpha: 0.18),
            ]
          : [
              AppColors.exploreAccent1.withValues(alpha: 0.12),
              AppColors.exploreAccent2.withValues(alpha: 0.08),
            ],
    );
  }

  /// Posts: blue → emerald
  static LinearGradient postsAccent({required bool isDark}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              AppColors.postsAccent1.withValues(alpha: 0.25),
              AppColors.postsAccent2.withValues(alpha: 0.18),
            ]
          : [
              AppColors.postsAccent1.withValues(alpha: 0.12),
              AppColors.postsAccent2.withValues(alpha: 0.08),
            ],
    );
  }

  /// Messages: indigo → violet
  static LinearGradient messagesAccent({required bool isDark}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              AppColors.messagesAccent1.withValues(alpha: 0.25),
              AppColors.messagesAccent2.withValues(alpha: 0.18),
            ]
          : [
              AppColors.messagesAccent1.withValues(alpha: 0.12),
              AppColors.messagesAccent2.withValues(alpha: 0.08),
            ],
    );
  }

  /// Profile: orange → pink
  static LinearGradient profileAccent({required bool isDark}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              AppColors.profileAccent1.withValues(alpha: 0.25),
              AppColors.profileAccent2.withValues(alpha: 0.18),
            ]
          : [
              AppColors.profileAccent1.withValues(alpha: 0.12),
              AppColors.profileAccent2.withValues(alpha: 0.08),
            ],
    );
  }

  // ──────────────────────────────────────────────
  // UTILITY GRADIENTS
  // ──────────────────────────────────────────────

  /// Solid indigo gradient for primary action buttons.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primary,       // #6366F1
      AppColors.primaryDark,   // #4F46E5
    ],
  );

  /// Shimmer gradient for loading skeleton animations.
  static LinearGradient shimmerGradient({required bool isDark}) {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: isDark
          ? [
              const Color(0xFF18181B),
              const Color(0xFF27272A),
              const Color(0xFF18181B),
            ]
          : [
              const Color(0xFFF1F5F9),
              const Color(0xFFE2E8F0),
              const Color(0xFFF1F5F9),
            ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  /// Radial gradient for decorative ambient glow circles.
  static RadialGradient glowGradient({
    required Color color,
    required bool isDark,
  }) {
    return RadialGradient(
      colors: [
        color.withValues(alpha: isDark ? 0.15 : 0.08),
        color.withValues(alpha: 0.0),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // AMBIENT GLOW COLORS (2 per screen)
  // ──────────────────────────────────────────────

  /// Home screen glow pair (purple, blue).
  static List<Color> homeGlowColors({required bool isDark}) => [
        AppColors.homeAccent1.withValues(alpha: isDark ? 0.18 : 0.10),
        AppColors.homeAccent2.withValues(alpha: isDark ? 0.14 : 0.07),
      ];

  /// Explore screen glow pair (cyan, teal).
  static List<Color> exploreGlowColors({required bool isDark}) => [
        AppColors.exploreAccent1.withValues(alpha: isDark ? 0.18 : 0.10),
        AppColors.exploreAccent2.withValues(alpha: isDark ? 0.14 : 0.07),
      ];

  /// Posts screen glow pair (blue, emerald).
  static List<Color> postsGlowColors({required bool isDark}) => [
        AppColors.postsAccent1.withValues(alpha: isDark ? 0.18 : 0.10),
        AppColors.postsAccent2.withValues(alpha: isDark ? 0.14 : 0.07),
      ];

  /// Messages screen glow pair (indigo, violet).
  static List<Color> messagesGlowColors({required bool isDark}) => [
        AppColors.messagesAccent1.withValues(alpha: isDark ? 0.18 : 0.10),
        AppColors.messagesAccent2.withValues(alpha: isDark ? 0.14 : 0.07),
      ];

  /// Profile screen glow pair (orange, pink).
  static List<Color> profileGlowColors({required bool isDark}) => [
        AppColors.profileAccent1.withValues(alpha: isDark ? 0.18 : 0.10),
        AppColors.profileAccent2.withValues(alpha: isDark ? 0.14 : 0.07),
      ];
}
