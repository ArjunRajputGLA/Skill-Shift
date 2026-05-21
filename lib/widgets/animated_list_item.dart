import 'package:flutter/material.dart';

/// Slide direction for [AnimatedListItem] entrance.
enum SlideDirection { up, left, right }

/// A wrapper widget that applies a staggered fade-in + slide entrance
/// animation to its [child].
///
/// The animation triggers once on first build. Subsequent rebuilds do **not**
/// replay the animation, keeping the UX polished and jank-free.
class AnimatedListItem extends StatefulWidget {
  /// Index used to calculate the stagger delay.
  final int index;

  /// The widget to animate in.
  final Widget child;

  /// Total animation duration (fade + slide).
  final Duration duration;

  /// Explicit delay override. When `null` the delay is calculated as
  /// `index * 80 ms`.
  final Duration? delay;

  /// Direction from which the widget slides into view.
  final SlideDirection direction;

  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay,
    this.direction = SlideDirection.up,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: _initialOffset,
      end: Offset.zero,
    ).animate(curved);

    // Start after the stagger delay.
    final delay =
        widget.delay ?? Duration(milliseconds: widget.index * 80);
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  Offset get _initialOffset {
    const double distance = 30.0;
    switch (widget.direction) {
      case SlideDirection.up:
        return const Offset(0, distance);
      case SlideDirection.left:
        return const Offset(distance, 0);
      case SlideDirection.right:
        return const Offset(-distance, 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _fadeAnimation.value,
        child: Transform.translate(
          offset: _slideAnimation.value,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
