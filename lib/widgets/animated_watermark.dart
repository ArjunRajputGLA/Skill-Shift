import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedWatermark extends StatefulWidget {
  final double opacityLight;
  final double opacityDark;

  const AnimatedWatermark({
    super.key, 
    this.opacityLight = 0.06, 
    this.opacityDark = 0.04,
  });

  @override
  State<AnimatedWatermark> createState() => _AnimatedWatermarkState();
}

class _AnimatedWatermarkState extends State<AnimatedWatermark> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned.fill(
      child: Center(
        child: Opacity(
          opacity: isDark ? widget.opacityDark : widget.opacityLight,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: Transform.scale(
                  scale: 1.0 + 0.15 * math.sin(_controller.value * 2 * math.pi),
                  child: child,
                ),
              );
            },
            child: Image.asset(
              'assets/message_icon.png',
              width: MediaQuery.of(context).size.width * 0.75,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
