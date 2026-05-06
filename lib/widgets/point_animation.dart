// games/guess_game/widgets/point_animation.dart

import 'package:flutter/material.dart';

class PointAnimation extends StatelessWidget {
  final Animation<double> animation;
  
  const PointAnimation({
    Key? key,
    required this.animation,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Positioned(
          top: 100 - (animation.value * 100),
          left: MediaQuery.of(context).size.width / 2 - 50,
          child: Opacity(
            opacity: 1 - animation.value,
            child: Transform.scale(
              scale: 1 + animation.value,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}