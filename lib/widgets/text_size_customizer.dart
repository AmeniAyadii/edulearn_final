// lib/widgets/text_size_customizer.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/text_size_provider.dart';
import '../theme/app_theme.dart';

class TextSizeCustomizer extends StatefulWidget {
  final bool showPreview;
  final VoidCallback? onChanged;

  const TextSizeCustomizer({
    super.key,
    this.showPreview = true,
    this.onChanged,
  });

  @override
  State<TextSizeCustomizer> createState() => _TextSizeCustomizerState();
}

class _TextSizeCustomizerState extends State<TextSizeCustomizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: screenWidth > 500 ? 500 : screenWidth - 40,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.text_fields,
                        size: 24,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Personnaliser la taille du texte',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : AppTheme.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Slider de taille
                _buildSizeSlider(textSizeProvider, isDarkMode),
                const SizedBox(height: 20),

                // Boutons de contrôle
                _buildControlButtons(textSizeProvider, isDarkMode, isSmallScreen),
                const SizedBox(height: 20),

                // Options prédéfinies
                _buildSizeOptions(textSizeProvider, isDarkMode),

                if (widget.showPreview) ...[
                  const SizedBox(height: 24),
                  _buildPreviewCard(textSizeProvider, isDarkMode),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSizeSlider(TextSizeProvider provider, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ajustement personnalisé',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey.shade300 : AppTheme.text,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.text_decrease, size: 20, color: Colors.grey),
            Expanded(
              child: Slider(
                value: provider.textScaleFactor,
                min: 0.7,
                max: 1.5,
                divisions: 16,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  provider.setTextSize(value);
                  if (widget.onChanged != null) widget.onChanged!();
                },
                activeColor: AppTheme.primaryColor,
                inactiveColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            Icon(Icons.text_increase, size: 20, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${(provider.textScaleFactor * 100).toInt()}%',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons(TextSizeProvider provider, bool isDarkMode, bool isSmallScreen) {
    if (isSmallScreen) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    provider.decreaseTextSize();
                    if (widget.onChanged != null) widget.onChanged!();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Petit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    provider.resetToDefault();
                    if (widget.onChanged != null) widget.onChanged!();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Normal'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              provider.increaseTextSize();
              if (widget.onChanged != null) widget.onChanged!();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Grand'),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              provider.decreaseTextSize();
              if (widget.onChanged != null) widget.onChanged!();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Plus petit'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              provider.resetToDefault();
              if (widget.onChanged != null) widget.onChanged!();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Normal'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              provider.increaseTextSize();
              if (widget.onChanged != null) widget.onChanged!();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Plus grand'),
          ),
        ),
      ],
    );
  }

  Widget _buildSizeOptions(TextSizeProvider provider, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tailles prédéfinies',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey.shade300 : AppTheme.text,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: provider.sizeOptions.map((option) {
            final isSelected = provider.textScaleFactor == option.value;
            return FilterChip(
              label: Text(
                option.label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  HapticFeedback.selectionClick();
                  provider.setTextSize(option.value);
                  if (widget.onChanged != null) widget.onChanged!();
                }
              },
              avatar: Icon(option.icon, size: 16),
              backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(TextSizeProvider provider, bool isDarkMode) {
    final isSmallScreen = MediaQuery.of(context).size.width < 380;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, size: isSmallScreen ? 18 : 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aperçu',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(provider.textScaleFactor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ceci est un exemple de texte',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : AppTheme.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'La taille du texte s\'adapte à vos préférences pour une meilleure lisibilité.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.4,
                    color: isDarkMode ? Colors.grey.shade400 : AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.star, size: isSmallScreen ? 14 : 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Les jeux et activités s\'adaptent aussi !',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 11 : 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}