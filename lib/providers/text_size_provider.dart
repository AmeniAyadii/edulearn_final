// lib/providers/text_size_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TextSizeProvider extends ChangeNotifier {
  static const String _textSizeKey = 'text_scale_factor';
  double _textScaleFactor = 1.0;

  // Options de taille de texte
  final List<TextSizeOption> sizeOptions = [
    TextSizeOption(value: 0.85, label: 'Très petit', icon: Icons.text_decrease, level: 0),
    TextSizeOption(value: 0.95, label: 'Petit', icon: Icons.text_fields, level: 1),
    TextSizeOption(value: 1.0, label: 'Normal', icon: Icons.text_fields, level: 2),
    TextSizeOption(value: 1.1, label: 'Grand', icon: Icons.text_increase, level: 3),
    TextSizeOption(value: 1.2, label: 'Très grand', icon: Icons.text_increase, level: 4),
  ];

  TextSizeProvider() {
    _loadTextSize();
  }

  double get textScaleFactor => _textScaleFactor;

  TextSizeOption get currentOption {
    return sizeOptions.firstWhere(
      (option) => option.value == _textScaleFactor,
      orElse: () => sizeOptions[2], // Normal par défaut
    );
  }

  Future<void> _loadTextSize() async {
    final prefs = await SharedPreferences.getInstance();
    _textScaleFactor = prefs.getDouble(_textSizeKey) ?? 1.0;
    notifyListeners();
  }

  Future<void> setTextSize(double scaleFactor) async {
    _textScaleFactor = scaleFactor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textSizeKey, scaleFactor);
    notifyListeners();
  }

  void increaseTextSize() {
    final currentIndex = sizeOptions.indexWhere((o) => o.value == _textScaleFactor);
    if (currentIndex < sizeOptions.length - 1) {
      setTextSize(sizeOptions[currentIndex + 1].value);
    }
  }

  void decreaseTextSize() {
    final currentIndex = sizeOptions.indexWhere((o) => o.value == _textScaleFactor);
    if (currentIndex > 0) {
      setTextSize(sizeOptions[currentIndex - 1].value);
    }
  }

  void resetToDefault() {
    setTextSize(1.0);
  }
}

class TextSizeOption {
  final double value;
  final String label;
  final IconData icon;
  final int level;

  TextSizeOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.level,
  });
}