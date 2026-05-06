// lib/widgets/animations/animated_list.dart

import 'package:edulearn_final/widgets/animations/fade_animation.dart';
import 'package:edulearn_final/widgets/animations/slide_animation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/animation_provider.dart';

class AnimatedListBuilder extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Duration itemAnimationDelay;
  final Duration baseDuration;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  const AnimatedListBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemAnimationDelay = const Duration(milliseconds: 50),
    this.baseDuration = const Duration(milliseconds: 400),
    this.physics,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final animationProvider = Provider.of<AnimationProvider>(context);
    
    return ListView.builder(
      physics: physics ?? const BouncingScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final delay = index * itemAnimationDelay.inMilliseconds;
        
        return FutureBuilder(
          future: Future.delayed(Duration(milliseconds: delay)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return FadeAnimation(
                duration: animationProvider.getDuration(baseDuration),
                child: SlideAnimation(
                  duration: animationProvider.getDuration(baseDuration),
                  child: itemBuilder(context, index),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}