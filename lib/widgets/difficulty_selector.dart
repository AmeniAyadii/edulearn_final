// lib/games/guess_game/widgets/difficulty_selector.dart

import 'package:flutter/material.dart';
import '../models/game_session.dart';

class DifficultySelector extends StatelessWidget {
  final Function(Difficulty) onDifficultySelected;
  final bool isLoading;

  const DifficultySelector({
    Key? key,
    required this.onDifficultySelected,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF1E1E1E) 
              : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology,
                  size: 50,
                  color: Color(0xFF6C63FF),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'Choisis ta difficulté',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              
              // Subtitle
              Text(
                'Plus la difficulté est élevée, plus les objets sont complexes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              
              // Difficulty options
              _buildDifficultyOption(
                context: context,  // ⭐ PASSER LE CONTEXTE EXPLICITEMENT
                difficulty: Difficulty.easy,
                title: 'Facile',
                description: 'Objets simples (animaux, fruits)',
                points: '×1',
                color: Colors.green,
                icon: Icons.star,
              ),
              const SizedBox(height: 12),
              
              _buildDifficultyOption(
                context: context,  // ⭐ PASSER LE CONTEXTE EXPLICITEMENT
                difficulty: Difficulty.medium,
                title: 'Moyen',
                description: 'Objets du quotidien',
                points: '×2',
                color: Colors.orange,
                icon: Icons.star_half,
              ),
              const SizedBox(height: 12),
              
              _buildDifficultyOption(
                context: context,  // ⭐ PASSER LE CONTEXTE EXPLICITEMENT
                difficulty: Difficulty.hard,
                title: 'Difficile',
                description: 'Objets complexes',
                points: '×3',
                color: Colors.red,
                icon: Icons.star_outline,
              ),
              const SizedBox(height: 20),
              
              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyOption({
    required BuildContext context,  // ⭐ CONTEXTE EXPLICITE
    required Difficulty difficulty,
    required String title,
    required String description,
    required String points,
    required Color color,
    required IconData icon,
  }) {
    return InkWell(
      onTap: isLoading ? null : () {
        // ⭐ UTILISER LE CONTEXTE PASSÉ EN PARAMÈTRE
        Navigator.pop(context);
        onDifficultySelected(difficulty);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          points,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension pour les méthodes utilitaires de Difficulty
extension DifficultyExtension on Difficulty {
  String get displayName {
    switch (this) {
      case Difficulty.easy:
        return 'Facile';
      case Difficulty.medium:
        return 'Moyen';
      case Difficulty.hard:
        return 'Difficile';
    }
  }
  
  IconData get icon {
    switch (this) {
      case Difficulty.easy:
        return Icons.star;
      case Difficulty.medium:
        return Icons.star_half;
      case Difficulty.hard:
        return Icons.star_outline;
    }
  }
  
  Color get color {
    switch (this) {
      case Difficulty.easy:
        return Colors.green;
      case Difficulty.medium:
        return Colors.orange;
      case Difficulty.hard:
        return Colors.red;
    }
  }
  
  int get multiplier {
    switch (this) {
      case Difficulty.easy:
        return 1;
      case Difficulty.medium:
        return 2;
      case Difficulty.hard:
        return 3;
    }
  }
  
  String get description {
    switch (this) {
      case Difficulty.easy:
        return 'Objets simples (animaux, fruits)';
      case Difficulty.medium:
        return 'Objets du quotidien';
      case Difficulty.hard:
        return 'Objets complexes (électroménager)';
    }
  }
  
  int get basePoints {
    switch (this) {
      case Difficulty.easy:
        return 100;
      case Difficulty.medium:
        return 150;
      case Difficulty.hard:
        return 200;
    }
  }
}