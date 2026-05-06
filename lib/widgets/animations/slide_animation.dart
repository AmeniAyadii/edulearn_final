// lib/widgets/animations/slide_animation.dart

import 'package:flutter/material.dart';

class SlideAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset beginOffset;
  final Offset endOffset;
  final Curve curve;
  final Duration delay;

  const SlideAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.beginOffset = const Offset(0, 0.5),
    this.endOffset = Offset.zero,
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
  });

  @override
  State<SlideAnimation> createState() => _SlideAnimationState();
}

class _SlideAnimationState extends State<SlideAnimation> {
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
      tween: Tween<Offset>(begin: widget.beginOffset, end: widget.endOffset),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, offset, child) => Transform.translate(
        offset: offset,
        child: child,
      ),
      child: widget.child,
    );
  }
}