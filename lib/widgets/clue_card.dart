// lib/games/guess_game/widgets/clue_card.dart

import 'package:flutter/material.dart';
import '../models/game_session.dart';

class ClueCard extends StatelessWidget {
  final Clue clue;
  final bool isRevealed;
  
  const ClueCard({
    Key? key,
    required this.clue,
    this.isRevealed = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // ✅ Éviter les problèmes de largeur infinie
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      constraints: BoxConstraints(
        maxWidth: screenWidth - 40, // ✅ Largeur maximale
        minWidth: 200,              // ✅ Largeur minimale
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRevealed 
              ? [Colors.amber.shade100, Colors.orange.shade50]
              : [Colors.grey.shade800, Colors.grey.shade900],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Numéro d'indice
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isRevealed ? Colors.amber : Colors.grey.shade700,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${clue.clueNumber}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isRevealed ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Texte de l'indice
          Expanded(
            child: Text(
              clue.clueText,
              style: TextStyle(
                fontSize: 16,
                height: 1.3,
                color: isRevealed ? Colors.black87 : Colors.grey.shade300,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Icône de statut
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isRevealed ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRevealed ? Icons.check_circle : Icons.lock_outline,
              size: 18,
              color: isRevealed ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}