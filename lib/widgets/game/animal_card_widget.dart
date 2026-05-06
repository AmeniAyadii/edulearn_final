import 'package:flutter/material.dart';
import '../../models/game_animal.dart';

class AnimalCardWidget extends StatelessWidget {
  final GameAnimal animal;
  final bool small;
  final VoidCallback? onTap;

  const AnimalCardWidget({
    super.key,
    required this.animal,
    this.small = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        // Afficher les détails de l'animal
        _showAnimalDetails(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(small ? 16 : 20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animal emoji ou image
            Container(
              width: small ? 60 : 80,
              height: small ? 60 : 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: Center(
                child: Text(
                  _getAnimalEmoji(animal.id),
                  style: TextStyle(fontSize: small ? 35 : 45),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Nom en français (langue par défaut)
            Text(
              animal.getNameInLanguage('fr'),
              style: TextStyle(
                fontSize: small ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Progression des langues
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLanguageIndicator('🇫🇷', animal.translations['fr']?.isComplete ?? false),
                const SizedBox(width: 4),
                _buildLanguageIndicator('🇬🇧', animal.translations['en']?.isComplete ?? false),
                const SizedBox(width: 4),
                _buildLanguageIndicator('🇪🇸', animal.translations['es']?.isComplete ?? false),
                if (!small) ...[
                  const SizedBox(width: 4),
                  _buildLanguageIndicator('🇩🇪', animal.translations['de']?.isComplete ?? false),
                  const SizedBox(width: 4),
                  _buildLanguageIndicator('🇮🇹', animal.translations['it']?.isComplete ?? false),
                ],
              ],
            ),
            if (!small) ...[
              const SizedBox(height: 8),
              // Points
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${animal.basePoints} pts',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Niv. ${animal.difficulty}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageIndicator(String flag, bool isComplete) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isComplete 
            ? Colors.green.withOpacity(0.8)
            : Colors.white.withOpacity(0.3),
      ),
      child: Center(
        child: Text(
          flag,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  String _getAnimalEmoji(String animalId) {
    switch (animalId.toLowerCase()) {
      case 'lion':
        return '🦁';
      case 'elephant':
        return '🐘';
      case 'giraffe':
        return '🦒';
      case 'panda':
        return '🐼';
      case 'dolphin':
        return '🐬';
      case 'tiger':
        return '🐯';
      case 'monkey':
        return '🐒';
      case 'zebra':
        return '🦓';
      case 'kangaroo':
        return '🦘';
      case 'penguin':
        return '🐧';
      default:
        return '🐾';
    }
  }

  void _showAnimalDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B11CB), Color(0xFF2575FC)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Emoji
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: Center(
                        child: Text(
                          _getAnimalEmoji(animal.id),
                          style: const TextStyle(fontSize: 60),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Nom scientifique
                    Text(
                      animal.scientificName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Nom en français
                    Text(
                      animal.getNameInLanguage('fr'),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Fun fact
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.yellow, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              animal.getFunFact('fr'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Langues maîtrisées
                    const Text(
                      'Langues apprises',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: animal.translations.entries.map((entry) {
                        final isComplete = entry.value.isComplete;
                        return Chip(
                          backgroundColor: isComplete 
                              ? Colors.green.withOpacity(0.6)
                              : Colors.white.withOpacity(0.2),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getFlagForLanguage(entry.key),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entry.value.name,
                                style: TextStyle(
                                  color: isComplete ? Colors.white : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFlagForLanguage(String langCode) {
    switch (langCode) {
      case 'fr': return '🇫🇷';
      case 'en': return '🇬🇧';
      case 'es': return '🇪🇸';
      case 'de': return '🇩🇪';
      case 'it': return '🇮🇹';
      case 'pt': return '🇵🇹';
      case 'nl': return '🇳🇱';
      case 'ru': return '🇷🇺';
      case 'zh': return '🇨🇳';
      case 'ja': return '🇯🇵';
      case 'ar': return '🇦🇪';
      case 'hi': return '🇮🇳';
      default: return '🌍';
    }
  }
}