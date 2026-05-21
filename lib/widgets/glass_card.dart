import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final bool animate;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppSpacing.radiusMd,
    this.color,
    this.onTap,
    this.gradient,
    this.animate = false,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppSpacing.durationEntrance,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: AppSpacing.entranceCurve,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: AppSpacing.entranceCurve,
    ));

    if (widget.animate) {
      _animController.forward();
    } else {
      _animController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double blurSigma = isDark ? 20.0 : 16.0;

    final baseColor = widget.color ??
        (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface);

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: widget.padding ?? const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: isDark ? 0.7 : 0.8),
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              // Subtle inner glow for dark mode depth
              if (isDark)
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.03),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );

    Widget result;
    if (widget.onTap != null) {
      result = Padding(
        padding: widget.margin ?? EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            onTap: widget.onTap,
            child: content,
          ),
        ),
      );
    } else {
      result = Padding(
        padding: widget.margin ?? EdgeInsets.zero,
        child: content,
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: result,
      ),
    );
  }
}
