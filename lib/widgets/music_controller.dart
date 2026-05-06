import 'package:flutter/material.dart';
import '../services/sound_service.dart';

class MusicController extends StatelessWidget {
  const MusicController({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.music_note, color: Colors.white),
            onPressed: () => _showMusicControls(context),
          ),
        ],
      ),
    );
  }

  void _showMusicControls(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Contrôle musique',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMusicButton(
                  icon: Icons.play_arrow,
                  label: 'Play',
                  onPressed: () => SoundService().startBackgroundMusic(),
                ),
                _buildMusicButton(
                  icon: Icons.pause,
                  label: 'Pause',
                  onPressed: () => SoundService().pauseBackgroundMusic(),
                ),
                _buildMusicButton(
                  icon: Icons.stop,
                  label: 'Stop',
                  onPressed: () => SoundService().stopBackgroundMusic(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 40),
          onPressed: onPressed,
        ),
        Text(label),
      ],
    );
  }
}