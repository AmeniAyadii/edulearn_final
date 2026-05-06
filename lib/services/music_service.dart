import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final AudioPlayer _backgroundPlayer = AudioPlayer();
  bool _isMusicEnabled = true;
  String? _currentMusicPath;

  Future<void> init() async {
    await _loadSettings();
    _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
    
    // Écouter les changements d'état de l'application
    WidgetsBinding.instance.addObserver(AppLifecycleObserver());
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isMusicEnabled = prefs.getBool('music') ?? true;
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music', _isMusicEnabled);
  }

  bool get isMusicEnabled => _isMusicEnabled;

  void setMusicEnabled(bool enabled) {
    _isMusicEnabled = enabled;
    saveSettings();
    if (!enabled) {
      stopBackgroundMusic();
    } else {
      if (_currentMusicPath != null) {
        playBackgroundMusic(_currentMusicPath!);
      }
    }
  }

  // lib/services/music_service.dart
Future<void> playBackgroundMusic(String musicPath, {double volume = 0.3}) async {
  if (!_isMusicEnabled) return;
  
  try {
    _currentMusicPath = musicPath;
    await _backgroundPlayer.stop();
    // CORRECTION: Utiliser setSourceAsset sans 'assets/' au début
    await _backgroundPlayer.setSourceAsset(musicPath);
    await _backgroundPlayer.setVolume(volume);
    await _backgroundPlayer.resume();
    debugPrint('🎵 Musique de fond démarrée: $musicPath');
  } catch (e) {
    debugPrint('❌ Erreur lecture musique: $e');
  }
}

  Future<void> stopBackgroundMusic() async {
    try {
      await _backgroundPlayer.stop();
      debugPrint('🎵 Musique de fond arrêtée');
    } catch (e) {
      debugPrint('❌ Erreur arrêt musique: $e');
    }
  }

  Future<void> pauseBackgroundMusic() async {
    try {
      await _backgroundPlayer.pause();
      debugPrint('🎵 Musique de fond en pause');
    } catch (e) {
      debugPrint('❌ Erreur mise en pause: $e');
    }
  }

  Future<void> resumeBackgroundMusic() async {
    if (!_isMusicEnabled) return;
    try {
      await _backgroundPlayer.resume();
      debugPrint('🎵 Musique de fond reprise');
    } catch (e) {
      debugPrint('❌ Erreur reprise musique: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _backgroundPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('❌ Erreur réglage volume: $e');
    }
  }

  Future<void> dispose() async {
    await _backgroundPlayer.dispose();
  }
}

// Observateur du cycle de vie de l'application
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final musicService = MusicService();
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        musicService.pauseBackgroundMusic();
        break;
      case AppLifecycleState.resumed:
        musicService.resumeBackgroundMusic();
        break;
      default:
        break;
    }
  }
}