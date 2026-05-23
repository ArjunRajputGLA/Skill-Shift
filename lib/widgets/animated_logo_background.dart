import 'package:flutter/material.dart';
import 'gradient_background.dart';
import 'dart:math' as math;

class AnimatedLogoBackground extends StatefulWidget {
  final Widget child;
  final Color accentColor1;
  final Color accentColor2;

  const AnimatedLogoBackground({
    super.key,
    required this.child,
    required this.accentColor1,
    required this.accentColor2,
  });

  @override
  State<AnimatedLogoBackground> createState() => _AnimatedLogoBackgroundState();
}

class _AnimatedLogoBackgroundState extends State<AnimatedLogoBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    
    // Sync the animation phase to the exact wall-clock time
    // so it continues seamlessly when navigating between screens.
    const durationMs = 40000;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final initialValue = (nowMs % durationMs) / durationMs;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: durationMs),
      value: initialValue,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      accentColor1: widget.accentColor1,
      accentColor2: widget.accentColor2,
      child: Stack(
        children: [
          // Animated Watermark Layer
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Subtle pulse and float
                final scale = 1.0 + 0.15 * math.sin(_controller.value * 2 * math.pi * 2);
                final dy = 30 * math.sin(_controller.value * 2 * math.pi * 3);
                final dx = 20 * math.cos(_controller.value * 2 * math.pi * 2);

                return Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.scale(
                    scale: scale * 1.6, // Reduced enlargement as requested
                    child: Transform.rotate(
                      angle: _controller.value * 2 * math.pi, // Full rotation
                      child: child,
                    ),
                  ),
                );
              },
              child: Opacity(
                opacity: 0.12, // Reduced dimming (increased opacity) as requested
                child: Center(
                  child: Image.asset(
                    'assets/login_screen_logo-removebg.png',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // Main Content Layer
          widget.child,
        ],
      ),
    );
  }
}
