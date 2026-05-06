import 'package:flutter/material.dart';

class ThemePreview extends StatelessWidget {
  final Widget lightWidget;
  final Widget darkWidget;

  const ThemePreview({
    super.key,
    required this.lightWidget,
    required this.darkWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkWidget : lightWidget;
  }
}