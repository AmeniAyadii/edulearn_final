// lib/providers/animation_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimationProvider extends ChangeNotifier {
  static const String _animationsKey = 'animations_enabled';
  bool _animationsEnabled = true;
  double _animationSpeed = 1.0;

  AnimationProvider() {
    _loadAnimationSettings();
  }

  bool get animationsEnabled => _animationsEnabled;
  double get animationSpeed => _animationSpeed;

  Future<void> _loadAnimationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _animationsEnabled = prefs.getBool(_animationsKey) ?? true;
    _animationSpeed = prefs.getDouble('animation_speed') ?? 1.0;
    notifyListeners();
  }

  Future<void> setAnimationsEnabled(bool enabled) async {
    _animationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_animationsKey, enabled);
    notifyListeners();
  }

  Future<void> setAnimationSpeed(double speed) async {
    _animationSpeed = speed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('animation_speed', speed);
    notifyListeners();
  }

  Duration getDuration(Duration baseDuration) {
    if (!_animationsEnabled) return Duration.zero;
    return Duration(
      milliseconds: (baseDuration.inMilliseconds * _animationSpeed).toInt(),
    );
  }
}