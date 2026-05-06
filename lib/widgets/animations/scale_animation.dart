// lib/widgets/animations/scale_animation.dart

import 'package:flutter/material.dart';

class ScaleAnimation extends StatefulWidget {
  final Widget child;
  final double beginScale;
  final double endScale;
  final Duration duration;
  final Curve curve;
  final Duration delay;

  const ScaleAnimation({
    super.key,
    required this.child,
    this.beginScale = 0.8,
    this.endScale = 1.0,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutBack,
    this.delay = Duration.zero,
  });

  @override
  State<ScaleAnimation> createState() => _ScaleAnimationState();
}

class _ScaleAnimationState extends State<ScaleAnimation> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _show = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) {
      return Opacity(opacity: 0, child: widget.child);
    }
    
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: widget.beginScale, end: widget.endScale),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: widget.child,
    );
  }
}