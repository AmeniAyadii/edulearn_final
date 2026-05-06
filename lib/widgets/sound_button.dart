import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_service.dart';

class SoundButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final SoundType soundType;
  final bool hapticFeedback;
  
  const SoundButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.soundType = SoundType.click,
    this.hapticFeedback = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Jouer le son
        await _playSound();
        
        // Vibration
        if (hapticFeedback) {
          _vibrate();
        }
        
        // Exécuter l'action
        onPressed();
      },
      child: child,
    );
  }
  
  Future<void> _playSound() async {
    final soundService = SoundService();
    switch (soundType) {
      case SoundType.click:
        await soundService.playClick();
        break;
      case SoundType.success:
        await soundService.playSuccess();
        break;
      case SoundType.error:
        await soundService.playError();
        break;
      case SoundType.notification:
        await soundService.playNotification();
        break;
      case SoundType.levelUp:
        await soundService.playLevelUp();
        break;
    }
  }
  
  void _vibrate() {
    HapticFeedback.lightImpact();
  }
}

enum SoundType {
  click,
  success,
  error,
  notification,
  levelUp,
}