import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isPrimary;
  final Gradient? gradient;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isPrimary = true,
    this.gradient,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppSpacing.durationMicro,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) _controller.reverse();
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasGradient = widget.gradient != null && widget.isPrimary;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            gradient: hasGradient ? widget.gradient : null,
            color: hasGradient
                ? null
                : widget.isPrimary
                    ? (widget.onPressed == null
                        ? theme.disabledColor
                        : theme.colorScheme.primary)
                    : Colors.transparent,
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: widget.onPressed == null
                        ? theme.disabledColor
                        : theme.colorScheme.primary,
                    width: 1.5,
                  ),
            boxShadow: widget.isPrimary && widget.onPressed != null
                ? [
                    BoxShadow(
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.isPrimary
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 20,
                          color: widget.isPrimary
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(
                        widget.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: widget.isPrimary
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
