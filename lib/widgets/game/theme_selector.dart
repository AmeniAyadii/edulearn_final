import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeSelector extends StatelessWidget {
  final String selectedTheme;
  final ValueChanged<String> onThemeSelected;

  const ThemeSelector({
    super.key,
    required this.selectedTheme,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          _buildThemeButton('classic', '🎨 Classique', Icons.color_lens),
          const SizedBox(width: 8),
          _buildThemeButton('camera', '📸 Caméra', Icons.camera_alt),
          const SizedBox(width: 8),
          _buildThemeButton('quiz', '🎯 Quiz', Icons.quiz),
        ],
      ),
    );
  }

  Widget _buildThemeButton(String theme, String label, IconData icon) {
    final isSelected = selectedTheme == theme;
    return Expanded(
      child: GestureDetector(
        onTap: () => onThemeSelected(theme),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(36),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}