import 'package:flutter/material.dart';
import '../services/vibration_service.dart';

class VibrantButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final String vibrationType; // 'light', 'medium', 'heavy', 'success', 'error'
  final bool hapticFeedback;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const VibrantButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.vibrationType = 'light',
    this.hapticFeedback = true,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (hapticFeedback) {
          final vibration = VibrationService();
          switch (vibrationType) {
            case 'light':
              await vibration.light();
              break;
            case 'medium':
              await vibration.medium();
              break;
            case 'heavy':
              await vibration.heavy();
              break;
            case 'success':
              await vibration.success();
              break;
            case 'error':
              await vibration.error();
              break;
            case 'notification':
              await vibration.notification();
              break;
            case 'selection':
              await vibration.selection();
              break;
            default:
              await vibration.click();
          }
        }
        onPressed();
      },
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}