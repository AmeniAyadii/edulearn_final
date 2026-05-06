import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  
  Future<void> playScanSound() async {
    await _player.play(AssetSource('sounds/scan.mp3'));
  }
  
  Future<void> playSuccessSound() async {
    await _player.play(AssetSource('sounds/success.mp3'));
  }
  
  Future<void> playErrorSound() async {
    await _player.play(AssetSource('sounds/error.mp3'));
  }
  
  Future<void> playInfoSound() async {
    await _player.play(AssetSource('sounds/info.mp3'));
  }
  
  void dispose() {
    _player.dispose();
  }
}