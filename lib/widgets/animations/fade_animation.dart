// lib/widgets/animations/fade_animation.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/animation_provider.dart';

class FadeAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double beginOpacity;
  final double endOpacity;
  final VoidCallback? onComplete;

  const FadeAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.beginOpacity = 0.0,
    this.endOpacity = 1.0,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final animationProvider = Provider.of<AnimationProvider>(context);
    
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: beginOpacity, end: endOpacity),
      duration: animationProvider.getDuration(duration),
      onEnd: onComplete,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: child,
      ),
      child: child,
    );
  }
}