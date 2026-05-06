// lib/widgets/language_selector.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class LanguageSelector extends StatelessWidget {
  final bool isModal;
  
  const LanguageSelector({super.key, this.isModal = true});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // ⭐ CORRECTION : Utiliser un type explicite Map<String, String>
    final List<Map<String, String>> languages = [
      {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
      {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    ];
    
    if (isModal) {
      return _buildModalSheet(context, languages, languageProvider, isDarkMode);
    } else {
      return _buildInlineSelector(context, languages, languageProvider, isDarkMode);
    }
  }
  
  Widget _buildModalSheet(
    BuildContext context,
    List<Map<String, String>> languages,
    LanguageProvider provider,
    bool isDarkMode,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Choisir la langue',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sélectionnez votre langue préférée',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          ...languages.map((lang) => ListTile(
            leading: Text(lang['flag'] ?? '🌐', style: const TextStyle(fontSize: 30)),
            title: Text(
              lang['name'] ?? 'Langue',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
            ),
            trailing: provider.currentLanguage == lang['code']
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 18, color: Color(0xFF6C63FF)),
                  )
                : null,
            onTap: () async {
              await provider.changeLanguage(context, lang['code'] ?? 'fr');
              if (context.mounted) Navigator.pop(context);
            },
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildInlineSelector(
    BuildContext context,
    List<Map<String, String>> languages,
    LanguageProvider provider,
    bool isDarkMode,
  ) {
    return Wrap(
      spacing: 8,
      children: languages.map((lang) {
        final isSelected = provider.currentLanguage == lang['code'];
        return FilterChip(
          avatar: Text(lang['flag'] ?? '🌐', style: const TextStyle(fontSize: 16)),
          label: Text(lang['name'] ?? 'Langue'),
          selected: isSelected,
          onSelected: (_) => provider.changeLanguage(context, lang['code'] ?? 'fr'),
          backgroundColor: isDarkMode ? const Color(0xFF2A2A3E) : Colors.grey.shade100,
          selectedColor: const Color(0xFF6C63FF).withOpacity(0.2),
          checkmarkColor: const Color(0xFF6C63FF),
        );
      }).toList(),
    );
  }
}