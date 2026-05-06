import 'dart:io';
import 'dart:ui' as ui;

Future<void> main() async {
  print('🖼️ Génération des icônes...');
  
  const sourceIcon = 'assets/icon/icon.png';
  const sizes = {
    'android': {
      'mipmap-hdpi': 72,
      'mipmap-mdpi': 48,
      'mipmap-xhdpi': 96,
      'mipmap-xxhdpi': 144,
      'mipmap-xxxhdpi': 192,
    },
    'ios': {
      '20x20@2x': 40,
      '20x20@3x': 60,
      '29x29@2x': 58,
      '29x29@3x': 87,
      '40x40@2x': 80,
      '40x40@3x': 120,
      '60x60@2x': 120,
      '60x60@3x': 180,
      '76x76@2x': 152,
      '83.5x83.5@2x': 167,
      '1024x1024': 1024,
    },
  };
  
  print('✅ Script prêt - Placez votre icône source dans $sourceIcon');
  print('📏 Taille recommandée: 1024x1024 pixels');
}