import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class LanguageCircleWidget extends StatefulWidget {
  final String flag;
  final String languageName;
  final String languageCode;
  final String animalName;
  final bool isActive;
  final VoidCallback onTap;
  final Future<void> Function() onListen;  // ← CHANGÉ : Future<void> Function()
  final bool isDiscovered;
  
  const LanguageCircleWidget({
    super.key,
    required this.flag,
    required this.languageName,
    required this.languageCode,
    required this.animalName,
    required this.isActive,
    required this.onTap,
    required this.onListen,
    this.isDiscovered = true,
  });

  @override
  State<LanguageCircleWidget> createState() => _LanguageCircleWidgetState();
}

class _LanguageCircleWidgetState extends State<LanguageCircleWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  
  Future<void> _playAndNotify() async {
    setState(() {
      _isPlaying = true;
    });
    
    try {
      await _audioPlayer.play(AssetSource('sounds/click.mp3'));
    } catch (e) {
      // Fichier son non trouvé, ignorer
    }
    
    await widget.onListen();  // ← Maintenant fonctionne avec await
    
    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: widget.isActive 
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isActive ? Colors.white : Colors.white.withOpacity(0.3),
            width: widget.isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.flag,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              widget.languageName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _playAndNotify,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isPlaying ? Icons.play_circle_outline : Icons.play_arrow,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.animalName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
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
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}