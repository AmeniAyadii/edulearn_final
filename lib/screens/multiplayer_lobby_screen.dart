// lib/games/guess_game/screens/multiplayer_lobby_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/guess_game_provider.dart';
import '../models/game_session.dart';
import 'guess_screen.dart';

class MultiplayerLobbyScreen extends StatefulWidget {
  final String childId;
  
  const MultiplayerLobbyScreen({
    Key? key,
    required this.childId,
  }) : super(key: key);
  
  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GuessGameProvider>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Parties disponibles'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<GameSession>>(
        stream: provider.getAvailableGames(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final games = snapshot.data!;
          
          if (games.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gamepad, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Aucune partie disponible',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return _buildGameCard(context, game);
            },
          );
        },
      ),
    );
  }
  
  Widget _buildGameCard(BuildContext context, GameSession game) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () async {
          try {
            final provider = Provider.of<GuessGameProvider>(context, listen: false);
            await provider.joinGameSession(game.sessionId, widget.childId);
            
            if (!mounted) return;
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GuessScreen(
                  sessionId: game.sessionId,
                  childId: widget.childId,
                ),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'En attente',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  if (game.joinCode != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        game.joinCode!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.question_mark, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Objet mystère à deviner',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, size: 20, color: Color(0xFF6C63FF)),
                    SizedBox(width: 8),
                    Text('Rejoindre la partie', style: TextStyle(color: Color(0xFF6C63FF))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}