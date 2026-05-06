// lib/games/guess_game/screens/game_result_screen.dart

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class GameResultScreen extends StatefulWidget {
  final int points;
  final int attemptsUsed;
  final String objectName;
  final String childId;
  
  const GameResultScreen({
    Key? key,
    required this.points,
    required this.attemptsUsed,
    required this.objectName,
    required this.childId,
  }) : super(key: key);
  
  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen> {
  late ConfettiController _confettiController;
  
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final message = _getMessage();
    final emoji = _getEmoji();
    final color = _getColor();
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  gravity: 0.1,
                ),
              ),
              
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 80)),
                      
                      const SizedBox(height: 30),
                      
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'C\'était : ${widget.objectName.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Points gagnés',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '+${widget.points}',
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            const Divider(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoTile('🎯', 'Essais', '${widget.attemptsUsed}'),
                                _buildInfoTile('🏆', 'Score max', _getMaxScore()),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                              icon: const Icon(Icons.home),
                              label: const Text('Accueil'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Rejouer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: color,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getMessage() {
    if (widget.attemptsUsed == 1) return "🎉 Parfait !\nDu premier coup !";
    if (widget.attemptsUsed == 2) return "🌟 Bravo !\nRapide et malin !";
    return "🎈 Félicitations !\nTu as trouvé !";
  }
  
  String _getEmoji() {
    if (widget.attemptsUsed == 1) return "🏆👑🏆";
    if (widget.attemptsUsed == 2) return "⭐🌟⭐";
    return "🎉✨🎊";
  }
  
  Color _getColor() {
    if (widget.attemptsUsed == 1) return const Color(0xFFFFB74D);
    if (widget.attemptsUsed == 2) return const Color(0xFFFF7043);
    return const Color(0xFF6C63FF);
  }
  
  String _getMaxScore() {
    if (widget.attemptsUsed == 1) return "15/15";
    if (widget.attemptsUsed == 2) return "10/15";
    return "5/15";
  }
  
  Widget _buildInfoTile(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}