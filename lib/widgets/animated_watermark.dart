import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;

class AnimatedWatermark extends StatefulWidget {
  final double opacityLight;
  final double opacityDark;

  const AnimatedWatermark({
    super.key, 
    // Brighter opacities
    this.opacityLight = 0.12, 
    this.opacityDark = 0.08,
  });

  @override
  State<AnimatedWatermark> createState() => _AnimatedWatermarkState();
}

class _AnimatedWatermarkState extends State<AnimatedWatermark> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  
  double x = 50;
  double y = 50;
  double vx = 60; // horizontal speed (pixels per second)
  double vy = 60; // vertical speed (pixels per second)
  
  double _rotationAngle = 0;
  double _scaleTime = 0;
  Size _viewportSize = Size.zero;

  @override
  void initState() {
    super.initState();
    // Randomize initial direction slightly
    final random = math.Random();
    vx = random.nextBool() ? 60 : -60;
    vy = random.nextBool() ? 60 : -60;
    
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (dt <= 0 || _viewportSize == Size.zero) return;
    
    // The size of our watermark image (40% of screen width)
    final imgWidth = _viewportSize.width * 0.40; 
    final imgHeight = imgWidth; // Assuming mostly square image
    
    x += vx * dt;
    y += vy * dt;
    
    _rotationAngle += (math.pi * 2 / 30) * dt; // full rotation every 30 seconds
    _scaleTime += (math.pi * 2 / 20) * dt;     // breathing cycle every 20 seconds
    
    // Bounce horizontally
    if (x <= 0) {
      x = 0;
      vx = vx.abs();
    } else if (x + imgWidth >= _viewportSize.width) {
      x = _viewportSize.width - imgWidth;
      vx = -vx.abs();
    }

    // Bounce vertically
    if (y <= 0) {
      y = 0;
      vy = vy.abs();
    } else if (y + imgHeight >= _viewportSize.height) {
      y = _viewportSize.height - imgHeight;
      vy = -vy.abs();
    }
    
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
          
          final imgWidth = _viewportSize.width * 0.40;
          
          // Safeguard bounds if screen size suddenly changes (e.g. rotation)
          if (x > _viewportSize.width - imgWidth) {
             x = math.max(0.0, _viewportSize.width - imgWidth);
          }
          if (y > _viewportSize.height - imgWidth) {
             y = math.max(0.0, _viewportSize.height - imgWidth);
          }
          
          return Stack(
            children: [
              Positioned(
                left: x,
                top: y,
                child: Opacity(
                  opacity: isDark ? widget.opacityDark : widget.opacityLight,
                  child: Transform.rotate(
                    angle: _rotationAngle,
                    child: Transform.scale(
                      scale: 1.0 + 0.15 * math.sin(_scaleTime),
                      child: Image.asset(
                        'assets/message_icon.png',
                        width: imgWidth,
                        height: imgWidth,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
