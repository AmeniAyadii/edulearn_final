// games/guess_game/screens/game_history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/guess_game_provider.dart';
import '../models/game_session.dart';

class GameHistoryScreen extends StatefulWidget {
  final String childId;
  
  const GameHistoryScreen({
    Key? key,
    required this.childId,
  }) : super(key: key);
  
  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen> {
  late Future<List<GameHistory>> _historyFuture;
  
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }
  
  void _loadHistory() {
    final provider = Provider.of<GuessGameProvider>(context, listen: false);
    _historyFuture = provider.getGameHistory(widget.childId);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Historique des parties'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadHistory();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<GameHistory>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final history = snapshot.data!;
          
          if (history.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Aucune partie jouée',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Joue une partie pour voir ton historique !',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          // Statistiques
          final totalPoints = history.fold<int>(0, (sum, game) => sum + game.pointsEarned);
          final totalWins = history.where((g) => g.isVictory).length;
          final winRate = history.isNotEmpty ? (totalWins / history.length * 100).toInt() : 0;
          
          return Column(
            children: [
              // Stats header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8B85FF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('🎮', 'Parties', history.length.toString()),
                    _buildStatColumn('🏆', 'Victoires', totalWins.toString()),
                    _buildStatColumn('⭐', 'Win Rate', '$winRate%'),
                    _buildStatColumn('💎', 'Points', totalPoints.toString()),
                  ],
                ),
              ),
              
              // History list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final game = history[index];
                    return _buildHistoryCard(game);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildStatColumn(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
  
  Widget _buildHistoryCard(GameHistory game) {
    final isVictory = game.isVictory;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isVictory ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  isVictory ? '🎉' : '😢',
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.objectName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text('${game.pointsEarned} pts'),
                      const SizedBox(width: 12),
                      Icon(Icons.quiz, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${game.attemptsUsed} essais'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(game.completedAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isVictory ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isVictory ? 'Victoire' : 'Défaite',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}