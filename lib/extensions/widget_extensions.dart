import 'package:edulearn_final/widgets/sound_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_service.dart';

extension WidgetSoundExtension on Widget {
  Widget withSound({
    required VoidCallback onPressed,
    SoundType soundType = SoundType.click,
    bool hapticFeedback = true,
  }) {
    return GestureDetector(
      onTap: () async {
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
        if (hapticFeedback) {
          HapticFeedback.lightImpact();
        }
        onPressed();
      },
      child: this,
    );
  }
}