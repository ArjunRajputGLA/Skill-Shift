import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A reusable premium screen background with a subtle gradient wash and
/// two ambient glow circles.
///
/// The gradient blends [AppColors.primary] (indigo) → [AppColors.accent] (teal)
/// at very low opacity, while the glow circles use the provided [accentColor1]
/// and [accentColor2] (falling back to the brand primaries).
class GradientBackground extends StatelessWidget {
  /// The content rendered above the gradient.
  final Widget child;

  /// Color of the top-right glow circle. Defaults to [AppColors.primary].
  final Color? accentColor1;

  /// Color of the bottom-left glow circle. Defaults to [AppColors.accent].
  final Color? accentColor2;

  const GradientBackground({
    super.key,
    required this.child,
    this.accentColor1,
    this.accentColor2,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color glow1 = accentColor1 ?? AppColors.primary;
    final Color glow2 = accentColor2 ?? AppColors.accent;

    // Opacity tuning
    final double gradientOpacity = isDark ? 0.10 : 0.04;
    final double glowOpacity = isDark ? 0.12 : 0.08;

    final Color baseBg =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Container(
      color: baseBg,
      child: Stack(
        children: [
          // ── 1. Base gradient wash ──────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: gradientOpacity),
                    AppColors.accent.withValues(alpha: gradientOpacity * 0.7),
                  ],
                ),
              ),
            ),
          ),

          // ── 2a. Top-right glow circle ─────────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: _GlowCircle(
              color: glow1,
              opacity: glowOpacity,
              size: 280,
            ),
          ),

          // ── 2b. Bottom-left glow circle ───────────────────────────────
          Positioned(
            bottom: -100,
            left: -70,
            child: _GlowCircle(
              color: glow2,
              opacity: glowOpacity,
              size: 260,
            ),
          ),

          // ── 3. Child content ──────────────────────────────────────────
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// A single blurred radial-gradient circle used as an ambient glow.
class _GlowCircle extends StatelessWidget {
  final Color color;
  final double opacity;
  final double size;

  const _GlowCircle({
    required this.color,
    required this.opacity,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
