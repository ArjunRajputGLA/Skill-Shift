import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_spacing.dart';

class DuolingoButton extends StatefulWidget {
  final String title;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color color;
  final bool disabled;

  const DuolingoButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.loading = false,
    this.icon,
    required this.color,
    this.disabled = false,
  });

  @override
  State<DuolingoButton> createState() => _DuolingoButtonState();
}

class _DuolingoButtonState extends State<DuolingoButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _pressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isDisabled => widget.disabled || widget.onPressed == null || widget.loading;

  void _onTapDown(TapDownDetails details) {
    if (_isDisabled) return;
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (_isDisabled) return;
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    if (_isDisabled) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // 3D lip color calculation (darken the main color)
    final HSLColor hslColor = HSLColor.fromColor(widget.color);
    final Color shadowColor = hslColor.withLightness((hslColor.lightness - 0.15).clamp(0.0, 1.0)).toColor();

    final Color effectiveColor = _isDisabled ? Colors.grey.shade600 : widget.color;
    final Color effectiveShadowColor = _isDisabled ? Colors.grey.shade700 : shadowColor;

    const double maxOffset = 6.0;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _pressAnimation,
        builder: (context, child) {
          final currentOffset = maxOffset * _pressAnimation.value;
          return SizedBox(
            height: 56 + maxOffset, // Base height + max depth
            width: double.infinity,
            child: Stack(
              children: [
                // Bottom Layer (Shadow / Lip)
                Positioned(
                  left: 0,
                  right: 0,
                  top: maxOffset, // Starts shifted down by max depth
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: effectiveShadowColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                // Top Layer (Main Button Face)
                Positioned(
                  left: 0,
                  right: 0,
                  top: currentOffset, // Moves down when pressed
                  bottom: maxOffset - currentOffset, // Bottom gap shrinks
                  child: Container(
                    decoration: BoxDecoration(
                      color: effectiveColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (!_isDisabled && _pressAnimation.value < 0.9)
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.3 * (1 - _pressAnimation.value)),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Center(
                      child: widget.loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.icon != null) ...[
                                  Icon(widget.icon, color: Colors.white, size: 20),
                                  const SizedBox(width: AppSpacing.sm),
                                ],
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
