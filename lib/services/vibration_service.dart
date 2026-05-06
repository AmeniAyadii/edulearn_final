import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Déclarer l'enum en dehors de la classe
enum VibrationType {
  light,      // Léger - pour les clics
  medium,     // Moyen - pour les succès
  heavy,      // Fort - pour les erreurs
  success,    // Succès - motif spécial
  error,      // Erreur - motif spécial
  notification, // Notification
  selection,   // Sélection
}

class VibrationService {
  static final VibrationService _instance = VibrationService._internal();
  factory VibrationService() => _instance;
  VibrationService._internal();

  bool _isVibrationEnabled = true;

  Future<void> init() async {
    await _loadSettings();
    await _checkVibrationSupport();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isVibrationEnabled = prefs.getBool('vibration') ?? true;
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration', _isVibrationEnabled);
  }

  bool get isVibrationEnabled => _isVibrationEnabled;
  
  void setVibrationEnabled(bool enabled) {
    _isVibrationEnabled = enabled;
    saveSettings();
  }

  Future<bool> _checkVibrationSupport() async {
    final hasVibrator = await Vibration.hasVibrator();
    final hasAmplitude = await Vibration.hasAmplitudeControl();
    debugPrint('Vibration support - Device: $hasVibrator, Amplitude: $hasAmplitude');
    return hasVibrator;
  }

  // Vibration de clic
  Future<void> click() async {
    if (!_isVibrationEnabled) return;
    try {
      await Vibration.vibrate(duration: 30);
    } catch (e) {
      await HapticFeedback.lightImpact();
    }
  }

  // Vibration légère
  Future<void> light() async {
    if (!_isVibrationEnabled) return;
    try {
      await Vibration.vibrate(duration: 50, amplitude: 50);
    } catch (e) {
      await HapticFeedback.lightImpact();
    }
  }

  // Vibration moyenne
  Future<void> medium() async {
    if (!_isVibrationEnabled) return;
    try {
      await Vibration.vibrate(duration: 100, amplitude: 128);
    } catch (e) {
      await HapticFeedback.mediumImpact();
    }
  }

  // Vibration forte
  Future<void> heavy() async {
    if (!_isVibrationEnabled) return;
    try {
      await Vibration.vibrate(duration: 150, amplitude: 255);
    } catch (e) {
      await HapticFeedback.heavyImpact();
    }
  }

  // Vibration de succès
  Future<void> success() async {
    if (!_isVibrationEnabled) return;
    try {
      await Vibration.vibrate(pattern: [0, 50, 100, 50]);
    } catch (e) {
      await HapticFeedback.mediumImpact();
    }
  }

  // Vibration d'erreur
  Future<void> error() async {
    if (!_isVibrationEnabled) return;
    try {
      await Vibration.vibrate(pattern: [0, 100, 50, 100]);
    } catch (e) {
      await HapticFeedback.heavyImpact();
    }
  }

  // Vibration de notification
  Future<void> notification() async {
    if (!_isVibrationEnabled) return;
    try {
      await Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100]);
    } catch (e) {
      await HapticFeedback.lightImpact();
    }
  }

  // Vibration de sélection
  Future<void> selection() async {
    if (!_isVibrationEnabled) return;
    try {
      await Vibration.vibrate(duration: 20);
    } catch (e) {
      await HapticFeedback.selectionClick();
    }
  }

  // Méthode pour jouer la vibration selon le type
  Future<void> play(VibrationType type) async {
    switch (type) {
      case VibrationType.light:
        await light();
        break;
      case VibrationType.medium:
        await medium();
        break;
      case VibrationType.heavy:
        await heavy();
        break;
      case VibrationType.success:
        await success();
        break;
      case VibrationType.error:
        await error();
        break;
      case VibrationType.notification:
        await notification();
        break;
      case VibrationType.selection:
        await selection();
        break;
    }
  }

  Future<void> customPattern(List<int> pattern, {int? intensities}) async {
    if (!_isVibrationEnabled) return;
    try {
      await Vibration.vibrate(pattern: pattern);
    } catch (e) {
      // Ignorer
    }
  }

  Future<void> vibrateDuration(int milliseconds) async {
    if (!_isVibrationEnabled) return;
    try {
      await Vibration.vibrate(duration: milliseconds);
    } catch (e) {
      // Ignorer
    }
  }

  Future<void> cancel() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      // Ignorer
    }
  }
}