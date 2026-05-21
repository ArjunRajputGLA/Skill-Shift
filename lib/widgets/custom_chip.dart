import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Visual variant for [CustomChip].
enum ChipVariant { filled, outlined, accent }

/// A premium reusable chip for skills, tags, and filters.
///
/// Supports three visual variants, optional leading icon, optional delete
/// action, and an animated scale-on-tap micro-interaction.
class CustomChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final ChipVariant variant;
  final IconData? icon;
  final VoidCallback? onDelete;

  const CustomChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.variant = ChipVariant.filled,
    this.icon,
    this.onDelete,
  });

  @override
  State<CustomChip> createState() => _CustomChipState();
}

class _CustomChipState extends State<CustomChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Tap handlers
  // ---------------------------------------------------------------------------

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) _scaleController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap != null) _scaleController.reverse();
  }

  void _onTapCancel() {
    if (widget.onTap != null) _scaleController.reverse();
  }

  // ---------------------------------------------------------------------------
  // Style helpers
  // ---------------------------------------------------------------------------

  Color _backgroundColor(bool isDark) {
    switch (widget.variant) {
      case ChipVariant.filled:
        if (widget.isSelected) return AppColors.primary;
        return isDark ? AppColors.chipBgDark : AppColors.chipBg;
      case ChipVariant.outlined:
        return Colors.transparent;
      case ChipVariant.accent:
        if (widget.isSelected) {
          return AppColors.accent.withValues(alpha: isDark ? 0.25 : 0.15);
        }
        return AppColors.accent.withValues(alpha: isDark ? 0.10 : 0.06);
    }
  }

  Border? _border(bool isDark) {
    switch (widget.variant) {
      case ChipVariant.outlined:
        return Border.all(
          color: widget.isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 1.5,
        );
      case ChipVariant.accent:
        return Border.all(
          color: AppColors.accent.withValues(alpha: widget.isSelected ? 0.5 : 0.2),
          width: 1.0,
        );
      case ChipVariant.filled:
        return null;
    }
  }

  Color _foregroundColor(bool isDark) {
    if (widget.variant == ChipVariant.filled && widget.isSelected) {
      return Colors.white;
    }
    if (widget.variant == ChipVariant.accent) {
      return isDark ? AppColors.accent : const Color(0xFF0D9488); // teal-600
    }
    return widget.isSelected
        ? AppColors.primary
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = _foregroundColor(isDark);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _backgroundColor(isDark),
            borderRadius: BorderRadius.circular(100), // pill shape
            border: _border(isDark),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: fg,
                  height: 1.2,
                ),
              ),
              if (widget.onDelete != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: fg.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
