// lib/widgets/animations/hero_animation.dart

import 'package:flutter/material.dart';

class HeroAnimation extends StatelessWidget {
  final String tag;
  final Widget child;
  final HeroFlightDirection flightDirection;

  const HeroAnimation({
    super.key,
    required this.tag,
    required this.child,
    this.flightDirection = HeroFlightDirection.push,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (flightContext, animation, direction, fromContext, toContext) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: child,
    );
  }
}